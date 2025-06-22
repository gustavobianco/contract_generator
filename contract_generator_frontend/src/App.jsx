import { useState, useEffect } from 'react';
import Login from './components/Login';
import Register from './components/Register';
import Dashboard from './components/Dashboard';
import CNPJConsulta from './components/CNPJConsulta';
import './App.css';

function App() {
  const [user, setUser] = useState(null);
  const [currentView, setCurrentView] = useState('login'); // 'login', 'register', 'dashboard', 'cnpj'
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Verificar se há um usuário logado no localStorage
    const token = localStorage.getItem('token');
    const savedUser = localStorage.getItem('user');
    
    if (token && savedUser) {
      try {
        setUser(JSON.parse(savedUser));
        setCurrentView('dashboard');
      } catch (error) {
        console.error('Erro ao carregar dados do usuário:', error);
        localStorage.removeItem('token');
        localStorage.removeItem('user');
      }
    }
    setLoading(false);
  }, []);

  const handleLogin = (userData) => {
    setUser(userData);
    setCurrentView('dashboard');
  };

  const handleLogout = () => {
    setUser(null);
    setCurrentView('login');
  };

  const handleRegister = (userData) => {
    // Após registro bem-sucedido, redirecionar para login
    console.log('Usuário registrado:', userData);
  };

  const switchToRegister = () => {
    setCurrentView('register');
  };

  const switchToLogin = () => {
    setCurrentView('login');
  };

  const navigateToCNPJ = () => {
    setCurrentView('cnpj');
  };

  const navigateBackToDashboard = () => {
    setCurrentView('dashboard');
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Carregando...</p>
        </div>
      </div>
    );
  }

  if (currentView === 'cnpj' && user) {
    return <CNPJConsulta onBack={navigateBackToDashboard} />;
  }

  if (currentView === 'dashboard' && user) {
    return (
      <Dashboard 
        user={user} 
        onLogout={handleLogout}
        onNavigateToCNPJ={navigateToCNPJ}
      />
    );
  }

  if (currentView === 'register') {
    return (
      <Register 
        onRegister={handleRegister}
        onSwitchToLogin={switchToLogin}
      />
    );
  }

  return (
    <Login 
      onLogin={handleLogin}
      onSwitchToRegister={switchToRegister}
    />
  );
}

export default App;

