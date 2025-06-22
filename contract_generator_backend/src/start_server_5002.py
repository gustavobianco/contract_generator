import os
import sys
# DON'T CHANGE THIS !!!
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from flask import Flask, send_from_directory
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from src.models.user import db
from src.routes.user import user_bp
from src.routes.cnpj import cnpj_bp

app = Flask(__name__, static_folder=os.path.join(os.path.dirname(__file__), 'static'))
app.config['SECRET_KEY'] = 'asdf#FGSgvasgf$5$WGT'
app.config['JWT_SECRET_KEY'] = 'jwt-secret-string-change-in-production'

# Configurar CORS para permitir requisições do frontend
CORS(app, origins=["http://localhost:5173", "http://localhost:3000"])

# Configurar JWT
jwt = JWTManager(app)

# Registrar blueprints
app.register_blueprint(user_bp, url_prefix='/api')
app.register_blueprint(cnpj_bp, url_prefix='/api')

# Configuração do banco de dados MySQL
# Para desenvolvimento local, use as variáveis de ambiente ou valores padrão
mysql_user = os.environ.get('MYSQL_USER', 'root')
mysql_password = os.environ.get('MYSQL_PASSWORD', 'password')
mysql_host = os.environ.get('MYSQL_HOST', 'localhost')
mysql_port = os.environ.get('MYSQL_PORT', '3306')
mysql_database = os.environ.get('MYSQL_DATABASE', 'contract_generator')

# String de conexão MySQL
app.config['SQLALCHEMY_DATABASE_URI'] = f"mysql+pymysql://{mysql_user}:{mysql_password}@{mysql_host}:{mysql_port}/{mysql_database}?charset=utf8mb4"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Configurações específicas do MySQL
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    'pool_pre_ping': True,
    'pool_recycle': 300,
    'connect_args': {
        'charset': 'utf8mb4',
        'use_unicode': True,
        'autocommit': True
    }
}

db.init_app(app)

# Criar diretório para PDFs se não existir
pdf_dir = os.path.join(os.path.dirname(__file__), 'pdfs')
if not os.path.exists(pdf_dir):
    os.makedirs(pdf_dir)

with app.app_context():
    db.create_all()

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve(path):
    static_folder_path = app.static_folder
    if static_folder_path is None:
            return "Static folder not configured", 404

    if path != "" and os.path.exists(os.path.join(static_folder_path, path)):
        return send_from_directory(static_folder_path, path)
    else:
        index_path = os.path.join(static_folder_path, 'index.html')
        if os.path.exists(index_path):
            return send_from_directory(static_folder_path, 'index.html')
        else:
            return "index.html not found", 404


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=True)

