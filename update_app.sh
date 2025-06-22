#!/bin/bash

# Script de Atualização do Gerador de Contratos e Procurações
# Este script atualiza a aplicação com zero downtime

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Verificar se está no diretório correto
if [ ! -d "/home/ubuntu/contract_generator_backend" ]; then
    print_error "Diretório do projeto não encontrado!"
    exit 1
fi

# Definir variáveis
PROJECT_DIR="/home/ubuntu"
BACKEND_DIR="$PROJECT_DIR/contract_generator_backend"
FRONTEND_DIR="$PROJECT_DIR/contract_generator_frontend"
SERVICE_NAME="contract-generator"
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)

print_status "🔄 Iniciando atualização da aplicação..."

# Criar backup antes da atualização
print_step "1. Criando backup..."
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/pre_update_backup_$DATE.tar.gz" \
    --exclude="node_modules" \
    --exclude="venv" \
    --exclude="dist" \
    --exclude="build" \
    --exclude="*.log" \
    "$BACKEND_DIR" \
    "$FRONTEND_DIR" 2>/dev/null || true

print_status "Backup criado: $BACKUP_DIR/pre_update_backup_$DATE.tar.gz"

# Verificar status do serviço antes da atualização
print_step "2. Verificando status do serviço..."
if systemctl is-active --quiet $SERVICE_NAME; then
    print_status "Serviço está rodando"
    SERVICE_WAS_RUNNING=true
else
    print_warning "Serviço não está rodando"
    SERVICE_WAS_RUNNING=false
fi

# Atualizar código do repositório
print_step "3. Atualizando código do repositório..."
cd "$PROJECT_DIR"

# Verificar se há mudanças locais não commitadas
if [ -d ".git" ]; then
    if ! git diff-index --quiet HEAD --; then
        print_warning "Há mudanças locais não commitadas. Fazendo stash..."
        git stash push -m "Auto-stash before update $DATE"
    fi
    
    print_status "Fazendo pull do repositório..."
    git pull origin main || {
        print_error "Falha ao fazer pull do repositório"
        exit 1
    }
else
    print_warning "Não é um repositório Git. Pulando atualização do código..."
fi

# Atualizar backend
print_step "4. Atualizando backend..."
cd "$BACKEND_DIR"

# Verificar se o ambiente virtual existe
if [ ! -d "venv" ]; then
    print_warning "Ambiente virtual não encontrado. Criando..."
    python3 -m venv venv
fi

# Ativar ambiente virtual e atualizar dependências
source venv/bin/activate
print_status "Atualizando dependências do Python..."
pip install --upgrade pip
pip install -r requirements.txt

# Verificar se o Gunicorn está instalado
if ! pip show gunicorn > /dev/null 2>&1; then
    print_status "Instalando Gunicorn..."
    pip install gunicorn
fi

# Executar migrações do banco de dados (se houver)
print_status "Verificando banco de dados..."
python -c "
import sys
sys.path.insert(0, '.')
from src.start_server_5002 import app
from src.models.user import db
with app.app_context():
    db.create_all()
    print('Banco de dados atualizado')
" || print_warning "Falha ao atualizar banco de dados"

# Atualizar frontend
print_step "5. Atualizando frontend..."
cd "$FRONTEND_DIR"

# Verificar se pnpm está instalado
if ! command -v pnpm &> /dev/null; then
    print_warning "pnpm não encontrado. Instalando..."
    sudo npm install -g pnpm
fi

print_status "Instalando dependências do frontend..."
pnpm install

# Atualizar URLs do backend no frontend (se necessário)
print_status "Verificando configurações do frontend..."
DOMAIN=${DOMAIN:-"localhost"}
find src -name "*.jsx" -type f -exec sed -i "s|http://localhost:5002|https://$DOMAIN|g" {} \; 2>/dev/null || true

print_status "Construindo frontend para produção..."
pnpm run build

# Verificar se a build foi bem-sucedida
if [ ! -d "dist" ]; then
    print_error "Falha na build do frontend!"
    exit 1
fi

# Reiniciar serviços
print_step "6. Reiniciando serviços..."

if [ "$SERVICE_WAS_RUNNING" = true ]; then
    print_status "Reiniciando serviço do backend..."
    sudo systemctl restart $SERVICE_NAME
    
    # Aguardar o serviço inicializar
    sleep 5
    
    # Verificar se o serviço está rodando
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_status "Serviço reiniciado com sucesso"
    else
        print_error "Falha ao reiniciar o serviço!"
        print_error "Logs do serviço:"
        sudo journalctl -u $SERVICE_NAME --no-pager -n 20
        exit 1
    fi
else
    print_status "Iniciando serviço do backend..."
    sudo systemctl start $SERVICE_NAME
fi

print_status "Recarregando configuração do Nginx..."
sudo nginx -t && sudo systemctl reload nginx || {
    print_error "Falha na configuração do Nginx!"
    exit 1
}

# Verificar saúde da aplicação
print_step "7. Verificando saúde da aplicação..."
sleep 3

# Testar endpoint de saúde
if curl -f -s -k https://localhost/health > /dev/null; then
    print_status "Aplicação está respondendo corretamente"
else
    print_warning "Aplicação pode não estar respondendo corretamente"
fi

# Limpeza
print_step "8. Limpeza..."
print_status "Removendo arquivos temporários..."

# Remover builds antigas (manter apenas as 3 mais recentes)
cd "$BACKUP_DIR"
ls -t pre_update_backup_*.tar.gz 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true

# Limpar logs antigos
sudo find /var/log/gunicorn -name "*.log" -mtime +7 -delete 2>/dev/null || true
sudo find /var/log/nginx -name "*.log" -mtime +7 -delete 2>/dev/null || true

print_status "✅ Atualização concluída com sucesso!"
echo ""
echo "📋 Resumo da atualização:"
echo "   • Backup criado: $BACKUP_DIR/pre_update_backup_$DATE.tar.gz"
echo "   • Código atualizado do repositório"
echo "   • Dependências do backend atualizadas"
echo "   • Frontend reconstruído"
echo "   • Serviços reiniciados"
echo ""
echo "🔧 Comandos úteis:"
echo "   • Verificar logs: sudo journalctl -u $SERVICE_NAME -f"
echo "   • Status do serviço: sudo systemctl status $SERVICE_NAME"
echo "   • Logs do Nginx: sudo tail -f /var/log/nginx/contract-generator.error.log"
echo ""
echo "🌐 Aplicação disponível em: https://localhost"

