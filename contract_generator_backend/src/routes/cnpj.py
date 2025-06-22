from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from src.services.cnpj_service import CNPJService

cnpj_bp = Blueprint('cnpj', __name__)

@cnpj_bp.route('/cnpj/<cnpj>', methods=['GET'])
@jwt_required()
def get_cnpj_data(cnpj):
    """
    Busca dados de uma empresa pelo CNPJ
    
    Args:
        cnpj (str): CNPJ da empresa
        
    Returns:
        JSON: Dados da empresa ou erro
    """
    try:
        # Verificar se o usuário está autenticado
        user_id = int(get_jwt_identity())
        
        # Buscar dados da empresa
        result = CNPJService.get_company_data(cnpj)
        
        if result['error']:
            return jsonify({
                'success': False,
                'message': result['message']
            }), 400
        
        return jsonify({
            'success': True,
            'data': result['data']
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Erro interno do servidor: {str(e)}'
        }), 500

@cnpj_bp.route('/cnpj/validate', methods=['POST'])
@jwt_required()
def validate_cnpj():
    """
    Valida um CNPJ
    
    Returns:
        JSON: Resultado da validação
    """
    try:
        # Verificar se o usuário está autenticado
        user_id = int(get_jwt_identity())
        
        data = request.json
        cnpj = data.get('cnpj', '')
        
        if not cnpj:
            return jsonify({
                'success': False,
                'message': 'CNPJ é obrigatório'
            }), 400
        
        is_valid = CNPJService.validate_cnpj(cnpj)
        formatted_cnpj = CNPJService.format_cnpj(cnpj)
        
        return jsonify({
            'success': True,
            'valid': is_valid,
            'cnpj': formatted_cnpj,
            'message': 'CNPJ válido' if is_valid else 'CNPJ inválido'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Erro interno do servidor: {str(e)}'
        }), 500

