import requests
import re
from typing import Dict, Optional

class CNPJService:
    """Serviço para consulta de dados de CNPJ usando a API ReceitaWS"""
    
    BASE_URL = "https://receitaws.com.br/v1/cnpj/"
    
    @staticmethod
    def format_cnpj(cnpj: str) -> str:
        """Remove formatação do CNPJ, deixando apenas números"""
        return re.sub(r'[^0-9]', '', cnpj)
    
    @staticmethod
    def validate_cnpj(cnpj: str) -> bool:
        """Valida se o CNPJ tem 14 dígitos"""
        clean_cnpj = CNPJService.format_cnpj(cnpj)
        return len(clean_cnpj) == 14 and clean_cnpj.isdigit()
    
    @staticmethod
    def get_company_data(cnpj: str) -> Dict:
        """
        Busca dados da empresa pelo CNPJ
        
        Args:
            cnpj (str): CNPJ da empresa (com ou sem formatação)
            
        Returns:
            Dict: Dados da empresa ou erro
        """
        try:
            # Validar CNPJ
            if not CNPJService.validate_cnpj(cnpj):
                return {
                    'error': True,
                    'message': 'CNPJ inválido. Deve conter 14 dígitos.'
                }
            
            # Formatar CNPJ
            clean_cnpj = CNPJService.format_cnpj(cnpj)
            
            # Fazer requisição para a API
            response = requests.get(
                f"{CNPJService.BASE_URL}{clean_cnpj}",
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                
                # Verificar se houve erro na resposta
                if data.get('status') == 'ERROR':
                    return {
                        'error': True,
                        'message': data.get('message', 'Erro ao consultar CNPJ')
                    }
                
                # Processar e retornar dados
                return {
                    'error': False,
                    'data': {
                        'cnpj': clean_cnpj,
                        'nome': data.get('nome', ''),
                        'fantasia': data.get('fantasia', ''),
                        'abertura': data.get('abertura', ''),
                        'situacao': data.get('situacao', ''),
                        'tipo': data.get('tipo', ''),
                        'porte': data.get('porte', ''),
                        'natureza_juridica': data.get('natureza_juridica', ''),
                        'logradouro': data.get('logradouro', ''),
                        'numero': data.get('numero', ''),
                        'complemento': data.get('complemento', ''),
                        'cep': data.get('cep', ''),
                        'bairro': data.get('bairro', ''),
                        'municipio': data.get('municipio', ''),
                        'uf': data.get('uf', ''),
                        'email': data.get('email', ''),
                        'telefone': data.get('telefone', ''),
                        'atividade_principal': data.get('atividade_principal', []),
                        'atividades_secundarias': data.get('atividades_secundarias', []),
                        'qsa': data.get('qsa', []),
                        'capital_social': data.get('capital_social', ''),
                        'ultima_atualizacao': data.get('ultima_atualizacao', '')
                    }
                }
            
            elif response.status_code == 429:
                return {
                    'error': True,
                    'message': 'Limite de requisições excedido. Tente novamente em alguns minutos.'
                }
            
            else:
                return {
                    'error': True,
                    'message': f'Erro na consulta: {response.status_code}'
                }
                
        except requests.exceptions.Timeout:
            return {
                'error': True,
                'message': 'Timeout na consulta. Tente novamente.'
            }
        
        except requests.exceptions.RequestException as e:
            return {
                'error': True,
                'message': f'Erro de conexão: {str(e)}'
            }
        
        except Exception as e:
            return {
                'error': True,
                'message': f'Erro interno: {str(e)}'
            }

