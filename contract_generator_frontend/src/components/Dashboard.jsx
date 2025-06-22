import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { FileText, Users, LogOut, Search } from 'lucide-react';

const Dashboard = ({ user, onLogout, onNavigateToCNPJ }) => {
  const [activeTab, setActiveTab] = useState('dashboard');

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    onLogout();
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                Gerador de Contratos e Procurações
              </h1>
              <p className="text-sm text-gray-600">
                Bem-vindo, {user.nome}
              </p>
            </div>
            <Button variant="outline" onClick={handleLogout}>
              <LogOut className="w-4 h-4 mr-2" />
              Sair
            </Button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            
            {/* Card Consultar CNPJ */}
            <Card className="hover:shadow-lg transition-shadow cursor-pointer" onClick={onNavigateToCNPJ}>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Search className="w-5 h-5 mr-2 text-indigo-600" />
                  Consultar CNPJ
                </CardTitle>
                <CardDescription>
                  Busque dados atualizados de empresas na Receita Federal
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button className="w-full" variant="default">
                  Consultar Empresa
                </Button>
              </CardContent>
            </Card>

            {/* Card Gerar Contrato */}
            <Card className="hover:shadow-lg transition-shadow cursor-pointer">
              <CardHeader>
                <CardTitle className="flex items-center">
                  <FileText className="w-5 h-5 mr-2 text-blue-600" />
                  Gerar Contrato
                </CardTitle>
                <CardDescription>
                  Crie contratos personalizados com dados da Receita Federal
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button className="w-full" variant="outline">
                  Novo Contrato
                </Button>
              </CardContent>
            </Card>

            {/* Card Gerar Procuração */}
            <Card className="hover:shadow-lg transition-shadow cursor-pointer">
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Users className="w-5 h-5 mr-2 text-green-600" />
                  Gerar Procuração
                </CardTitle>
                <CardDescription>
                  Crie procurações com informações empresariais atualizadas
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button className="w-full" variant="outline">
                  Nova Procuração
                </Button>
              </CardContent>
            </Card>

            {/* Card Histórico */}
            <Card className="hover:shadow-lg transition-shadow cursor-pointer">
              <CardHeader>
                <CardTitle className="flex items-center">
                  <FileText className="w-5 h-5 mr-2 text-purple-600" />
                  Histórico
                </CardTitle>
                <CardDescription>
                  Visualize e baixe documentos gerados anteriormente
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button className="w-full" variant="secondary">
                  Ver Histórico
                </Button>
              </CardContent>
            </Card>

          </div>

          {/* Seção de Informações */}
          <div className="mt-8">
            <Card>
              <CardHeader>
                <CardTitle>Como funciona</CardTitle>
                <CardDescription>
                  Processo simples para gerar seus documentos
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                  <div className="text-center">
                    <div className="bg-indigo-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-3">
                      <span className="text-indigo-600 font-bold">1</span>
                    </div>
                    <h3 className="font-medium mb-2">Consulte o CNPJ</h3>
                    <p className="text-sm text-gray-600">
                      Busque e valide os dados da empresa na Receita Federal
                    </p>
                  </div>
                  <div className="text-center">
                    <div className="bg-blue-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-3">
                      <span className="text-blue-600 font-bold">2</span>
                    </div>
                    <h3 className="font-medium mb-2">Informe o CNPJ</h3>
                    <p className="text-sm text-gray-600">
                      Digite o CNPJ da empresa para buscar os dados na Receita Federal
                    </p>
                  </div>
                  <div className="text-center">
                    <div className="bg-green-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-3">
                      <span className="text-green-600 font-bold">3</span>
                    </div>
                    <h3 className="font-medium mb-2">Escolha o Modelo</h3>
                    <p className="text-sm text-gray-600">
                      Selecione entre contrato ou procuração e personalize conforme necessário
                    </p>
                  </div>
                  <div className="text-center">
                    <div className="bg-purple-100 rounded-full w-12 h-12 flex items-center justify-center mx-auto mb-3">
                      <span className="text-purple-600 font-bold">4</span>
                    </div>
                    <h3 className="font-medium mb-2">Receba por Email</h3>
                    <p className="text-sm text-gray-600">
                      O documento será gerado e enviado para seu email automaticamente
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Dashboard;

