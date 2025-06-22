# Guia Completo de Implantação em Produção
## Gerador de Contratos e Procurações

Este documento fornece instruções detalhadas para transformar a aplicação em um site de produção e implantá-la permanentemente em um servidor.

## 📋 Visão Geral da Arquitetura de Produção

A aplicação em produção utiliza a seguinte arquitetura:

- **Frontend (React)**: Construído para produção e servido como arquivos estáticos
- **Nginx**: Servidor web que serve o frontend e atua como proxy reverso para o backend
- **Backend (Flask)**: Executado via Gunicorn (servidor WSGI de produção)
- **Banco de Dados**: SQLite (pode ser migrado para PostgreSQL/MySQL)
- **SSL/TLS**: Certificados para HTTPS
- **Monitoramento**: Scripts de monitoramento e logs

## 🚀 Passo a Passo para Implantação

### 1. Preparação do Servidor

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install -y nginx python3-pip python3-venv nodejs npm build-essential git curl

# Instalar pnpm
sudo npm install -g pnpm

# Criar usuário para a aplicação (se necessário)
sudo useradd -m -s /bin/bash ubuntu
```

### 2. Configuração da Aplicação

```bash
# Clonar o repositório
cd /home/ubuntu
git clone <URL_DO_SEU_REPOSITORIO>

# Tornar o script de configuração executável
chmod +x setup_production.sh

# Executar o script de configuração
./setup_production.sh
```

### 3. Configuração Manual (Alternativa)

Se preferir configurar manualmente:

#### 3.1. Backend Flask

```bash
cd /home/ubuntu/contract_generator_backend

# Criar ambiente virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependências
pip install -r requirements.txt
pip install gunicorn

# Copiar arquivos de configuração
cp ../gunicorn.conf.py .
cp ../wsgi.py .
```

#### 3.2. Frontend React

```bash
cd /home/ubuntu/contract_generator_frontend

# Instalar dependências
pnpm install

# Atualizar URLs do backend
find src -name "*.jsx" -type f -exec sed -i "s|http://localhost:5002|https://SEU_DOMINIO|g" {} \;

# Construir para produção
pnpm run build
```

#### 3.3. Configuração do Nginx

```bash
# Copiar configuração do Nginx
sudo cp /home/ubuntu/nginx_config.conf /etc/nginx/sites-available/contract-generator

# Habilitar o site
sudo ln -sf /etc/nginx/sites-available/contract-generator /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração
sudo nginx -t
```

#### 3.4. Configuração do Systemd

```bash
# Copiar arquivo de serviço
sudo cp /home/ubuntu/contract-generator.service /etc/systemd/system/

# Recarregar systemd e habilitar serviço
sudo systemctl daemon-reload
sudo systemctl enable contract-generator
sudo systemctl start contract-generator
```

### 4. Configuração SSL/TLS

#### 4.1. Certificado Auto-assinado (Desenvolvimento)

```bash
sudo mkdir -p /etc/ssl/private
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/contract-generator.key \
    -out /etc/ssl/certs/contract-generator.crt \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=ContractGenerator/CN=SEU_DOMINIO"
```

#### 4.2. Let's Encrypt (Produção)

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado
sudo certbot --nginx -d SEU_DOMINIO

# Configurar renovação automática
sudo crontab -e
# Adicionar: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 5. Configuração de Firewall

```bash
# Configurar UFW
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw --force enable
```

## 🔧 Scripts de Gerenciamento

### Script de Atualização

```bash
# Tornar executável
chmod +x /home/ubuntu/update_app.sh

# Executar atualização
./update_app.sh
```

### Script de Monitoramento

```bash
# Tornar executável
chmod +x /home/ubuntu/monitor_app.sh

# Verificar status
./monitor_app.sh status

# Executar verificação de saúde
./monitor_app.sh check
```

### Configuração de Monitoramento Automático

```bash
# Adicionar ao crontab para verificação a cada 5 minutos
crontab -e
# Adicionar: */5 * * * * /home/ubuntu/monitor_app.sh check
```

## 📊 Monitoramento e Logs

### Logs Importantes

```bash
# Logs do backend
sudo journalctl -u contract-generator -f

# Logs do Nginx
sudo tail -f /var/log/nginx/contract-generator.error.log
sudo tail -f /var/log/nginx/contract-generator.access.log

# Logs do Gunicorn
sudo tail -f /var/log/gunicorn/error.log
sudo tail -f /var/log/gunicorn/access.log
```

### Comandos de Gerenciamento

```bash
# Reiniciar backend
sudo systemctl restart contract-generator

# Recarregar Nginx
sudo systemctl reload nginx

# Verificar status dos serviços
sudo systemctl status contract-generator
sudo systemctl status nginx

# Verificar configuração do Nginx
sudo nginx -t
```

## 🔒 Configurações de Segurança

### 1. Configurações do Nginx

- Rate limiting configurado
- Headers de segurança
- Bloqueio de arquivos sensíveis
- Configurações SSL seguras

### 2. Configurações do Sistema

```bash
# Configurar fail2ban (opcional)
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Configurar logrotate para logs
sudo tee /etc/logrotate.d/contract-generator > /dev/null << EOF
/var/log/gunicorn/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        systemctl reload contract-generator
    endscript
}
EOF
```

## 🚀 Opções de Hospedagem

### 1. VPS/Cloud Servers
- **DigitalOcean**: Droplets a partir de $5/mês
- **Linode**: VPS a partir de $5/mês
- **Vultr**: Instâncias a partir de $2.50/mês
- **AWS EC2**: t3.micro (free tier disponível)
- **Google Cloud**: e2-micro (free tier disponível)

### 2. Plataformas Gerenciadas
- **Heroku**: Fácil deploy, mas mais caro
- **Railway**: Moderna e simples
- **Render**: Boa alternativa ao Heroku
- **PythonAnywhere**: Especializada em Python

### 3. Configuração Recomendada para VPS

**Especificações mínimas:**
- 1 vCPU
- 1GB RAM
- 25GB SSD
- 1TB transferência

**Especificações recomendadas:**
- 2 vCPU
- 2GB RAM
- 50GB SSD
- Transferência ilimitada

## 📈 Otimizações de Performance

### 1. Configurações do Gunicorn

```python
# gunicorn.conf.py
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
max_requests = 1000
preload_app = True
```

### 2. Configurações do Nginx

```nginx
# Cache de arquivos estáticos
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# Compressão
gzip on;
gzip_types text/plain text/css application/javascript;
```

### 3. Banco de Dados

Para aplicações com mais tráfego, considere migrar para PostgreSQL:

```bash
# Instalar PostgreSQL
sudo apt install postgresql postgresql-contrib

# Criar banco e usuário
sudo -u postgres createdb contract_generator
sudo -u postgres createuser -P contract_user
```

## 🔄 Backup e Recuperação

### Script de Backup Automático

```bash
# Adicionar ao crontab para backup diário
crontab -e
# Adicionar: 0 2 * * * /home/ubuntu/backup_app.sh
```

### Restauração

```bash
# Parar serviços
sudo systemctl stop contract-generator

# Restaurar backup
tar -xzf backup_file.tar.gz -C /home/ubuntu/

# Reiniciar serviços
sudo systemctl start contract-generator
```

## 🌐 Configuração de Domínio

### 1. DNS

Configure os registros DNS do seu domínio:

```
A    @    IP_DO_SERVIDOR
A    www  IP_DO_SERVIDOR
```

### 2. Atualizar Configurações

```bash
# Atualizar domínio no Nginx
sudo sed -i 's/localhost/SEU_DOMINIO/g' /etc/nginx/sites-available/contract-generator

# Atualizar URLs no frontend
cd /home/ubuntu/contract_generator_frontend
find src -name "*.jsx" -type f -exec sed -i "s|https://localhost|https://SEU_DOMINIO|g" {} \;
pnpm run build

# Reiniciar serviços
sudo systemctl reload nginx
```

## 📞 Suporte e Troubleshooting

### Problemas Comuns

1. **Serviço não inicia**
   ```bash
   sudo journalctl -u contract-generator -n 50
   ```

2. **Erro 502 Bad Gateway**
   ```bash
   # Verificar se o backend está rodando
   curl http://127.0.0.1:8000/api/users
   ```

3. **Problemas de SSL**
   ```bash
   sudo nginx -t
   sudo certbot certificates
   ```

### Contatos de Suporte

- Documentação: Este arquivo
- Logs: `/var/log/nginx/` e `journalctl -u contract-generator`
- Monitoramento: `./monitor_app.sh status`

---

**Autor:** Manus AI  
**Data:** $(date)  
**Versão:** 1.0

