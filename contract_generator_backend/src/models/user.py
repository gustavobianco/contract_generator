from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import json

db = SQLAlchemy()

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    nome = db.Column(db.String(100), nullable=False)
    data_cadastro = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relacionamento com documentos
    documentos = db.relationship('Documento', backref='usuario', lazy=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def __repr__(self):
        return f'<User {self.email}>'

    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'nome': self.nome,
            'data_cadastro': self.data_cadastro.isoformat() if self.data_cadastro else None
        }

class Documento(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    tipo = db.Column(db.String(50), nullable=False)  # 'contrato' ou 'procuracao'
    nome_arquivo = db.Column(db.String(255), nullable=False)
    data_geracao = db.Column(db.DateTime, default=datetime.utcnow)
    caminho_arquivo_pdf = db.Column(db.String(500), nullable=True)
    dados_cnpj = db.Column(db.Text, nullable=True)  # JSON string com dados da empresa
    cnpj = db.Column(db.String(18), nullable=False)  # CNPJ formatado
    
    def set_dados_cnpj(self, dados_dict):
        self.dados_cnpj = json.dumps(dados_dict, ensure_ascii=False)
    
    def get_dados_cnpj(self):
        if self.dados_cnpj:
            return json.loads(self.dados_cnpj)
        return {}

    def __repr__(self):
        return f'<Documento {self.nome_arquivo}>'

    def to_dict(self):
        return {
            'id': self.id,
            'usuario_id': self.usuario_id,
            'tipo': self.tipo,
            'nome_arquivo': self.nome_arquivo,
            'data_geracao': self.data_geracao.isoformat() if self.data_geracao else None,
            'caminho_arquivo_pdf': self.caminho_arquivo_pdf,
            'dados_cnpj': self.get_dados_cnpj(),
            'cnpj': self.cnpj
        }

