# Configuração do Gunicorn para produção
# Arquivo: gunicorn.conf.py

import multiprocessing
import os

# Endereço e porta para bind
bind = "127.0.0.1:8000"

# Número de workers (processos)
# Recomendação: (2 x CPU cores) + 1
workers = multiprocessing.cpu_count() * 2 + 1

# Classe do worker
worker_class = "sync"

# Número máximo de conexões simultâneas por worker
worker_connections = 1000

# Número máximo de requisições que um worker pode processar antes de ser reiniciado
max_requests = 1000
max_requests_jitter = 100

# Timeout para requisições
timeout = 30

# Timeout para keep-alive
keepalive = 2

# Pré-carregar a aplicação
preload_app = True

# Não executar como daemon (para systemd)
daemon = False

# Usuário e grupo para executar o processo
user = "ubuntu"
group = "ubuntu"

# Diretório temporário para uploads
tmp_upload_dir = None

# Configurações de log
errorlog = "/var/log/gunicorn/error.log"
accesslog = "/var/log/gunicorn/access.log"
loglevel = "info"

# Formato do log de acesso
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

# Configurações de processo
proc_name = "contract_generator"

# Configurações de SSL (se necessário)
# keyfile = "/path/to/keyfile"
# certfile = "/path/to/certfile"

# Configurações de performance
max_requests_jitter = 50
preload_app = True
worker_tmp_dir = "/dev/shm"

# Configurações de graceful restart
graceful_timeout = 30
worker_class = "sync"

# Configurações de monitoramento
enable_stdio_inheritance = True

# Hook para configurações adicionais
def when_ready(server):
    server.log.info("Servidor pronto para receber conexões")

def worker_int(worker):
    worker.log.info("Worker recebeu INT ou QUIT signal")

def pre_fork(server, worker):
    server.log.info("Worker spawned (pid: %s)", worker.pid)

def post_fork(server, worker):
    server.log.info("Worker spawned (pid: %s)", worker.pid)

def post_worker_init(worker):
    worker.log.info("Worker initialized (pid: %s)", worker.pid)

def worker_abort(worker):
    worker.log.info("Worker received SIGABRT signal")

