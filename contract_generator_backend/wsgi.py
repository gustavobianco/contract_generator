#!/usr/bin/env python3
"""
WSGI entry point para o Gerador de Contratos e Procurações
Este arquivo é usado pelo Gunicorn para servir a aplicação Flask em produção
"""

import sys
import os
from pathlib import Path

# Adicionar o diretório do projeto ao Python path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

# Configurar variáveis de ambiente para produção
os.environ.setdefault('FLASK_ENV', 'production')
os.environ.setdefault('FLASK_DEBUG', 'False')

try:
    # Importar a aplicação Flask
    from src.start_server_5002 import app
    
    # Configurações adicionais para produção
    app.config.update(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'production-secret-key-change-me'),
        JWT_SECRET_KEY=os.environ.get('JWT_SECRET_KEY', 'jwt-production-secret-change-me'),
        SQLALCHEMY_DATABASE_URI=os.environ.get(
            'DATABASE_URL', 
            f"sqlite:///{project_root}/src/database/app.db"
        ),
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
        SQLALCHEMY_ENGINE_OPTIONS={
            'pool_pre_ping': True,
            'pool_recycle': 300,
        }
    )
    
    # Criar tabelas se não existirem
    with app.app_context():
        from src.models.user import db
        db.create_all()
    
    print(f"✅ Aplicação Flask carregada com sucesso")
    print(f"📁 Diretório do projeto: {project_root}")
    print(f"🗄️ Banco de dados: {app.config['SQLALCHEMY_DATABASE_URI']}")
    
except Exception as e:
    print(f"❌ Erro ao carregar a aplicação: {e}")
    import traceback
    traceback.print_exc()
    raise

# Exportar a aplicação para o Gunicorn
application = app

if __name__ == "__main__":
    # Para desenvolvimento local
    app.run(host='0.0.0.0', port=5000, debug=False)

