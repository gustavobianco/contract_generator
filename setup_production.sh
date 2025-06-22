#!/bin/bash

# Script de Configuração de Produção para o Gerador de Contratos e Procurações
# Este script configura um ambiente de produção completo com Nginx, Gunicorn e SSL

set -e

echo "🚀 Iniciando configuração do ambiente de produção..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   print_error "Este script não deve ser executado como root"
   exit 1
fi

# Definir variáveis
PROJECT_DIR="/home/ubuntu"
BACKEND_DIR="$PROJECT_DIR/contract_generator_backend"
FRONTEND_DIR="$PROJECT_DIR/contract_generator_frontend"
NGINX_SITES_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
SERVICE_NAME="contract-generator"
DOMAIN="localhost"  # Altere para seu domínio real

print_status "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

print_status "Instalando dependências do sistema..."
sudo apt install -y nginx python3-pip python3-venv nodejs npm build-essential

print_status "Instalando pnpm globalmente..."
sudo npm install -g pnpm

print_status "Configurando backend Flask..."
cd "$BACKEND_DIR"

# Criar ambiente virtual se não existir
if [ ! -d "venv" ]; then
    print_status "Criando ambiente virtual Python..."
    python3 -m venv venv
fi

# Ativar ambiente virtual e instalar dependências
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

print_status "Instalando dependências do frontend..."
cd "$FRONTEND_DIR"
pnpm install

print_status "Atualizando URLs do backend no frontend..."
# Substituir localhost:5002 pelo domínio de produção
find src -name "*.jsx" -type f -exec sed -i "s|http://localhost:5002|https://$DOMAIN|g" {} \;

print_status "Construindo frontend para produção..."
pnpm run build

print_status "Criando arquivo de configuração do Gunicorn..."
cat > "$BACKEND_DIR/gunicorn.conf.py" << EOF
# Configuração do Gunicorn para produção
bind = "127.0.0.1:8000"
workers = 4
worker_class = "sync"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 100
timeout = 30
keepalive = 2
preload_app = True
daemon = False
user = "ubuntu"
group = "ubuntu"
tmp_upload_dir = None
errorlog = "/var/log/gunicorn/error.log"
accesslog = "/var/log/gunicorn/access.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'
EOF

print_status "Criando diretório de logs do Gunicorn..."
sudo mkdir -p /var/log/gunicorn
sudo chown ubuntu:ubuntu /var/log/gunicorn

print_status "Criando arquivo WSGI para produção..."
cat > "$BACKEND_DIR/wsgi.py" << EOF
#!/usr/bin/env python3
import sys
import os

# Adicionar o diretório do projeto ao Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Importar a aplicação Flask
from src.start_server_5002 import app

if __name__ == "__main__":
    app.run()
EOF

print_status "Criando serviço systemd para o backend..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=Gunicorn instance to serve Contract Generator
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$BACKEND_DIR/venv/bin"
ExecStart=$BACKEND_DIR/venv/bin/gunicorn --config gunicorn.conf.py wsgi:app
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

print_status "Criando configuração do Nginx..."
sudo tee $NGINX_SITES_DIR/$SERVICE_NAME > /dev/null << EOF
# Configuração do Nginx para o Gerador de Contratos e Procurações

# Redirecionamento HTTP para HTTPS
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# Configuração HTTPS principal
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # Configurações SSL (ajuste os caminhos dos certificados)
    ssl_certificate /etc/ssl/certs/contract-generator.crt;
    ssl_certificate_key /etc/ssl/private/contract-generator.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Configurações de segurança
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Diretório raiz para arquivos estáticos do frontend
    root $FRONTEND_DIR/dist;
    index index.html;

    # Configurações de compressão
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Servir arquivos estáticos do frontend
    location / {
        try_files \$uri \$uri/ /index.html;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Proxy para API do backend
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Servir arquivos de download (PDFs gerados)
    location /downloads/ {
        alias $BACKEND_DIR/src/pdfs/;
        expires 1h;
        add_header Cache-Control "private";
    }

    # Logs
    access_log /var/log/nginx/contract-generator.access.log;
    error_log /var/log/nginx/contract-generator.error.log;
}
EOF

print_status "Criando certificado SSL auto-assinado (para desenvolvimento)..."
sudo mkdir -p /etc/ssl/private
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/contract-generator.key \
    -out /etc/ssl/certs/contract-generator.crt \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=ContractGenerator/CN=$DOMAIN"

print_status "Habilitando site no Nginx..."
sudo ln -sf $NGINX_SITES_DIR/$SERVICE_NAME $NGINX_ENABLED_DIR/
sudo rm -f $NGINX_ENABLED_DIR/default

print_status "Testando configuração do Nginx..."
sudo nginx -t

print_status "Habilitando e iniciando serviços..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME
sudo systemctl enable nginx
sudo systemctl restart nginx

print_status "Criando script de atualização..."
cat > "$PROJECT_DIR/update_app.sh" << EOF
#!/bin/bash
# Script para atualizar a aplicação

set -e

echo "🔄 Atualizando aplicação..."

# Ir para o diretório do projeto
cd $PROJECT_DIR

# Atualizar código do repositório
git pull origin main

# Atualizar backend
cd $BACKEND_DIR
source venv/bin/activate
pip install -r requirements.txt

# Atualizar frontend
cd $FRONTEND_DIR
pnpm install
pnpm run build

# Reiniciar serviços
sudo systemctl restart $SERVICE_NAME
sudo systemctl reload nginx

echo "✅ Aplicação atualizada com sucesso!"
EOF

chmod +x "$PROJECT_DIR/update_app.sh"

print_status "Criando script de backup..."
cat > "$PROJECT_DIR/backup_app.sh" << EOF
#!/bin/bash
# Script para backup da aplicação

BACKUP_DIR="/home/ubuntu/backups"
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="contract_generator_backup_\$DATE.tar.gz"

mkdir -p \$BACKUP_DIR

echo "📦 Criando backup..."

tar -czf "\$BACKUP_DIR/\$BACKUP_FILE" \\
    --exclude="node_modules" \\
    --exclude="venv" \\
    --exclude="dist" \\
    --exclude="build" \\
    --exclude="*.log" \\
    $PROJECT_DIR/contract_generator_backend \\
    $PROJECT_DIR/contract_generator_frontend

echo "✅ Backup criado: \$BACKUP_DIR/\$BACKUP_FILE"
EOF

chmod +x "$PROJECT_DIR/backup_app.sh"

print_status "Verificando status dos serviços..."
sudo systemctl status $SERVICE_NAME --no-pager
sudo systemctl status nginx --no-pager

print_status "Configurando firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw --force enable

echo ""
echo "🎉 Configuração de produção concluída!"
echo ""
echo "📋 Resumo:"
echo "   • Backend Flask rodando com Gunicorn na porta 8000"
echo "   • Frontend React construído e servido pelo Nginx"
echo "   • Nginx configurado como proxy reverso na porta 443 (HTTPS)"
echo "   • Certificado SSL auto-assinado criado"
echo "   • Serviços configurados para iniciar automaticamente"
echo ""
echo "🔧 Comandos úteis:"
echo "   • Verificar logs do backend: sudo journalctl -u $SERVICE_NAME -f"
echo "   • Verificar logs do Nginx: sudo tail -f /var/log/nginx/contract-generator.error.log"
echo "   • Reiniciar backend: sudo systemctl restart $SERVICE_NAME"
echo "   • Recarregar Nginx: sudo systemctl reload nginx"
echo "   • Atualizar aplicação: ./update_app.sh"
echo "   • Fazer backup: ./backup_app.sh"
echo ""
echo "🌐 Acesse sua aplicação em: https://$DOMAIN"
echo ""
print_warning "Para produção real, substitua o certificado SSL auto-assinado por um certificado válido (Let's Encrypt, etc.)"

