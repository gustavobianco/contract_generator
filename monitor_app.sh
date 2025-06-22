#!/bin/bash

# Script de Monitoramento do Gerador de Contratos e Procurações
# Este script verifica a saúde da aplicação e pode ser usado com cron

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
SERVICE_NAME="contract-generator"
NGINX_SERVICE="nginx"
LOG_FILE="/var/log/contract-generator-monitor.log"
ALERT_EMAIL=""  # Configure um email para alertas
MAX_RESPONSE_TIME=5  # segundos
MAX_MEMORY_USAGE=80  # porcentagem
MAX_CPU_USAGE=80     # porcentagem

# Função para logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" > /dev/null
}

# Função para enviar alertas (configure conforme necessário)
send_alert() {
    local message="$1"
    log_message "ALERT: $message"
    
    # Enviar email se configurado
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Contract Generator Alert" "$ALERT_EMAIL" 2>/dev/null || true
    fi
    
    # Enviar para syslog
    logger -t contract-generator-monitor "ALERT: $message"
}

# Função para verificar se um serviço está rodando
check_service() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name"; then
        return 0
    else
        return 1
    fi
}

# Função para verificar resposta HTTP
check_http_response() {
    local url="$1"
    local expected_status="$2"
    local timeout="$3"
    
    local response_time
    local http_status
    
    response_time=$(curl -o /dev/null -s -w "%{time_total}" -m "$timeout" -k "$url" 2>/dev/null || echo "timeout")
    http_status=$(curl -o /dev/null -s -w "%{http_code}" -m "$timeout" -k "$url" 2>/dev/null || echo "000")
    
    if [ "$response_time" = "timeout" ] || [ "$http_status" = "000" ]; then
        return 1
    fi
    
    if [ "$http_status" = "$expected_status" ]; then
        # Verificar tempo de resposta
        if (( $(echo "$response_time > $MAX_RESPONSE_TIME" | bc -l) )); then
            log_message "WARNING: Slow response time: ${response_time}s for $url"
        fi
        return 0
    else
        return 1
    fi
}

# Função para verificar uso de recursos
check_resource_usage() {
    local service_name="$1"
    
    # Obter PID do processo principal
    local main_pid=$(systemctl show --property MainPID --value "$service_name")
    
    if [ "$main_pid" != "0" ] && [ -n "$main_pid" ]; then
        # Verificar uso de CPU e memória
        local cpu_usage=$(ps -p "$main_pid" -o %cpu --no-headers 2>/dev/null | tr -d ' ' || echo "0")
        local mem_usage=$(ps -p "$main_pid" -o %mem --no-headers 2>/dev/null | tr -d ' ' || echo "0")
        
        # Remover casas decimais para comparação
        cpu_usage=${cpu_usage%.*}
        mem_usage=${mem_usage%.*}
        
        if [ "$cpu_usage" -gt "$MAX_CPU_USAGE" ]; then
            send_alert "High CPU usage detected: ${cpu_usage}% for $service_name"
        fi
        
        if [ "$mem_usage" -gt "$MAX_MEMORY_USAGE" ]; then
            send_alert "High memory usage detected: ${mem_usage}% for $service_name"
        fi
        
        log_message "Resource usage for $service_name - CPU: ${cpu_usage}%, Memory: ${mem_usage}%"
    fi
}

# Função para verificar espaço em disco
check_disk_space() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -gt 90 ]; then
        send_alert "Critical disk space: ${usage}% used"
    elif [ "$usage" -gt 80 ]; then
        log_message "WARNING: High disk usage: ${usage}%"
    fi
}

# Função para verificar logs de erro
check_error_logs() {
    local error_count
    
    # Verificar erros no log do Gunicorn (últimos 5 minutos)
    error_count=$(sudo journalctl -u "$SERVICE_NAME" --since "5 minutes ago" --no-pager | grep -i error | wc -l)
    if [ "$error_count" -gt 5 ]; then
        send_alert "High error rate in $SERVICE_NAME logs: $error_count errors in last 5 minutes"
    fi
    
    # Verificar erros no log do Nginx (últimos 5 minutos)
    if [ -f "/var/log/nginx/contract-generator.error.log" ]; then
        error_count=$(sudo tail -n 100 /var/log/nginx/contract-generator.error.log | grep "$(date '+%Y/%m/%d %H:%M' -d '5 minutes ago')" | wc -l)
        if [ "$error_count" -gt 10 ]; then
            send_alert "High error rate in Nginx logs: $error_count errors in last 5 minutes"
        fi
    fi
}

# Função principal de monitoramento
main_check() {
    local status="OK"
    local issues=()
    
    log_message "Starting health check..."
    
    # Verificar serviço do backend
    if ! check_service "$SERVICE_NAME"; then
        status="CRITICAL"
        issues+=("Backend service is not running")
        send_alert "Backend service $SERVICE_NAME is not running"
    else
        log_message "Backend service is running"
        check_resource_usage "$SERVICE_NAME"
    fi
    
    # Verificar serviço do Nginx
    if ! check_service "$NGINX_SERVICE"; then
        status="CRITICAL"
        issues+=("Nginx service is not running")
        send_alert "Nginx service is not running"
    else
        log_message "Nginx service is running"
    fi
    
    # Verificar resposta HTTP da aplicação
    if ! check_http_response "https://localhost/health" "200" "$MAX_RESPONSE_TIME"; then
        status="CRITICAL"
        issues+=("Application not responding")
        send_alert "Application health check failed"
    else
        log_message "Application health check passed"
    fi
    
    # Verificar API do backend
    if ! check_http_response "https://localhost/api/users" "401" "$MAX_RESPONSE_TIME"; then
        status="WARNING"
        issues+=("API endpoint not responding correctly")
        log_message "WARNING: API endpoint check failed"
    else
        log_message "API endpoint check passed"
    fi
    
    # Verificar espaço em disco
    check_disk_space
    
    # Verificar logs de erro
    check_error_logs
    
    # Verificar conectividade com API externa (Receita Federal)
    if ! curl -s --max-time 10 "https://receitaws.com.br/v1/cnpj/11222333000181" > /dev/null; then
        log_message "WARNING: External API (ReceitaWS) connectivity issue"
    else
        log_message "External API connectivity OK"
    fi
    
    # Resumo do status
    if [ "$status" = "OK" ]; then
        log_message "Health check completed - Status: OK"
    else
        log_message "Health check completed - Status: $status - Issues: ${issues[*]}"
    fi
    
    # Retornar código de saída baseado no status
    case "$status" in
        "OK") exit 0 ;;
        "WARNING") exit 1 ;;
        "CRITICAL") exit 2 ;;
    esac
}

# Função para mostrar status detalhado
show_status() {
    echo "=== Contract Generator Status ==="
    echo ""
    
    # Status dos serviços
    echo "Services:"
    if check_service "$SERVICE_NAME"; then
        echo -e "  Backend: ${GREEN}Running${NC}"
    else
        echo -e "  Backend: ${RED}Stopped${NC}"
    fi
    
    if check_service "$NGINX_SERVICE"; then
        echo -e "  Nginx: ${GREEN}Running${NC}"
    else
        echo -e "  Nginx: ${RED}Stopped${NC}"
    fi
    
    echo ""
    
    # Status da aplicação
    echo "Application Health:"
    if check_http_response "https://localhost/health" "200" 5; then
        echo -e "  Health Check: ${GREEN}OK${NC}"
    else
        echo -e "  Health Check: ${RED}Failed${NC}"
    fi
    
    if check_http_response "https://localhost/api/users" "401" 5; then
        echo -e "  API Endpoint: ${GREEN}OK${NC}"
    else
        echo -e "  API Endpoint: ${RED}Failed${NC}"
    fi
    
    echo ""
    
    # Uso de recursos
    echo "Resource Usage:"
    local main_pid=$(systemctl show --property MainPID --value "$SERVICE_NAME")
    if [ "$main_pid" != "0" ] && [ -n "$main_pid" ]; then
        local cpu_usage=$(ps -p "$main_pid" -o %cpu --no-headers 2>/dev/null | tr -d ' ' || echo "0")
        local mem_usage=$(ps -p "$main_pid" -o %mem --no-headers 2>/dev/null | tr -d ' ' || echo "0")
        echo "  CPU: ${cpu_usage}%"
        echo "  Memory: ${mem_usage}%"
    fi
    
    local disk_usage=$(df / | awk 'NR==2 {print $5}')
    echo "  Disk: $disk_usage"
    
    echo ""
    
    # Logs recentes
    echo "Recent Logs (last 5 lines):"
    sudo journalctl -u "$SERVICE_NAME" --no-pager -n 5 | tail -n 5
}

# Verificar argumentos da linha de comando
case "${1:-check}" in
    "check")
        main_check
        ;;
    "status")
        show_status
        ;;
    "help")
        echo "Usage: $0 [check|status|help]"
        echo ""
        echo "Commands:"
        echo "  check   - Run health check (default)"
        echo "  status  - Show detailed status"
        echo "  help    - Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

