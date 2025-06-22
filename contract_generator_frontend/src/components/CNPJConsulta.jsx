import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Building, MapPin, Phone, Mail, Calendar, Users, ArrowLeft, Search } from 'lucide-react';

const CNPJConsulta = ({ onBack }) => {
  const [cnpj, setCnpj] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [companyData, setCompanyData] = useState(null);

  const formatCNPJ = (value) => {
    // Remove tudo que não é número
    const numbers = value.replace(/\D/g, '');
    
    // Aplica a máscara XX.XXX.XXX/XXXX-XX
    if (numbers.length <= 14) {
      return numbers
        .replace(/(\d{2})(\d)/, '$1.$2')
        .replace(/(\d{3})(\d)/, '$1.$2')
        .replace(/(\d{3})(\d)/, '$1/$2')
        .replace(/(\d{4})(\d)/, '$1-$2');
    }
    return value;
  };

  const handleCNPJChange = (e) => {
    const formatted = formatCNPJ(e.target.value);
    setCnpj(formatted);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setCompanyData(null);

    try {
      const token = localStorage.getItem('token');
      const cleanCNPJ = cnpj.replace(/\D/g, '');

      if (cleanCNPJ.length !== 14) {
        setError('CNPJ deve ter 14 dígitos');
        setLoading(false);
        return;
      }

      const response = await fetch(`https://biancomeister.pythonanywhere.com/api/cnpj/${cleanCNPJ}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      const data = await response.json();

      if (response.ok && data.success) {
        setCompanyData(data.data);
      } else {
        setError(data.message || 'Erro ao consultar CNPJ');
      }
    } catch (err) {
      setError('Erro de conexão com o servidor');
    } finally {
      setLoading(false);
    }
  };

  const getSituacaoColor = (situacao) => {
    switch (situacao?.toUpperCase()) {
      case 'ATIVA':
        return 'bg-green-100 text-green-800';
      case 'SUSPENSA':
        return 'bg-yellow-100 text-yellow-800';
      case 'INAPTA':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center py-4">
            <Button variant="ghost" onClick={onBack} className="mr-4">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Voltar
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                Consulta CNPJ
              </h1>
              <p className="text-sm text-gray-600">
                Busque informações atualizadas da Receita Federal
              </p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          
          {/* Formulário de Consulta */}
          <Card className="mb-6">
            <CardHeader>
              <CardTitle className="flex items-center">
                <Search className="w-5 h-5 mr-2" />
                Consultar CNPJ
              </CardTitle>
              <CardDescription>
                Digite o CNPJ da empresa para buscar informações na Receita Federal
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                {error && (
                  <Alert variant="destructive">
                    <AlertDescription>{error}</AlertDescription>
                  </Alert>
                )}
                
                <div className="flex gap-4">
                  <div className="flex-1">
                    <Label htmlFor="cnpj">CNPJ</Label>
                    <Input
                      id="cnpj"
                      type="text"
                      value={cnpj}
                      onChange={handleCNPJChange}
                      placeholder="00.000.000/0000-00"
                      maxLength={18}
                      required
                    />
                  </div>
                  <div className="flex items-end">
                    <Button type="submit" disabled={loading}>
                      {loading ? 'Consultando...' : 'Consultar'}
                    </Button>
                  </div>
                </div>
              </form>
            </CardContent>
          </Card>

          {/* Resultados da Consulta */}
          {companyData && (
            <div className="space-y-6">
              
              {/* Informações Básicas */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Building className="w-5 h-5 mr-2" />
                    Informações da Empresa
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label className="text-sm font-medium text-gray-500">Razão Social</Label>
                      <p className="text-lg font-semibold">{companyData.nome}</p>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-500">Nome Fantasia</Label>
                      <p className="text-lg">{companyData.fantasia || 'Não informado'}</p>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-500">CNPJ</Label>
                      <p className="text-lg font-mono">{formatCNPJ(companyData.cnpj)}</p>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-500">Situação</Label>
                      <div className="mt-1">
                        <Badge className={getSituacaoColor(companyData.situacao)}>
                          {companyData.situacao}
                        </Badge>
                      </div>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-500">Tipo</Label>
                      <p>{companyData.tipo}</p>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-500">Porte</Label>
                      <p>{companyData.porte}</p>
                    </div>
                    <div className="md:col-span-2">
                      <Label className="text-sm font-medium text-gray-500">Natureza Jurídica</Label>
                      <p>{companyData.natureza_juridica}</p>
                    </div>
                  </div>
                  
                  <Separator />
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label className="text-sm font-medium text-gray-500">Data de Abertura</Label>
                      <p className="flex items-center">
                        <Calendar className="w-4 h-4 mr-2" />
                        {companyData.abertura}
                      </p>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-500">Capital Social</Label>
                      <p>{companyData.capital_social || 'Não informado'}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Endereço */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <MapPin className="w-5 h-5 mr-2" />
                    Endereço
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    <p className="text-lg">
                      {companyData.logradouro}
                      {companyData.numero && `, ${companyData.numero}`}
                      {companyData.complemento && `, ${companyData.complemento}`}
                    </p>
                    <p>
                      {companyData.bairro} - {companyData.municipio}/{companyData.uf}
                    </p>
                    <p>CEP: {companyData.cep}</p>
                  </div>
                </CardContent>
              </Card>

              {/* Contato */}
              {(companyData.telefone || companyData.email) && (
                <Card>
                  <CardHeader>
                    <CardTitle>Contato</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-2">
                    {companyData.telefone && (
                      <p className="flex items-center">
                        <Phone className="w-4 h-4 mr-2" />
                        {companyData.telefone}
                      </p>
                    )}
                    {companyData.email && (
                      <p className="flex items-center">
                        <Mail className="w-4 h-4 mr-2" />
                        {companyData.email}
                      </p>
                    )}
                  </CardContent>
                </Card>
              )}

              {/* Atividade Principal */}
              {companyData.atividade_principal && companyData.atividade_principal.length > 0 && (
                <Card>
                  <CardHeader>
                    <CardTitle>Atividade Principal</CardTitle>
                  </CardHeader>
                  <CardContent>
                    {companyData.atividade_principal.map((atividade, index) => (
                      <div key={index} className="space-y-1">
                        <p className="font-medium">{atividade.code}</p>
                        <p className="text-gray-600">{atividade.text}</p>
                      </div>
                    ))}
                  </CardContent>
                </Card>
              )}

              {/* Quadro Societário */}
              {companyData.qsa && companyData.qsa.length > 0 && (
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center">
                      <Users className="w-5 h-5 mr-2" />
                      Quadro Societário
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      {companyData.qsa.map((socio, index) => (
                        <div key={index} className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                          <div>
                            <p className="font-medium">{socio.nome}</p>
                            <p className="text-sm text-gray-600">{socio.qual}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              )}

              {/* Ações */}
              <Card>
                <CardContent className="pt-6">
                  <div className="flex gap-4">
                    <Button className="flex-1">
                      Gerar Contrato
                    </Button>
                    <Button variant="outline" className="flex-1">
                      Gerar Procuração
                    </Button>
                  </div>
                </CardContent>
              </Card>

            </div>
          )}
        </div>
      </main>
    </div>
  );
};

export default CNPJConsulta;

