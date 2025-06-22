# Gerador de Contratos e Procurações

## 📄 Descrição do Projeto

Este projeto é uma aplicação web completa desenvolvida para simplificar a geração de contratos e procurações em formato PDF. A aplicação permite que usuários autenticados consultem dados de empresas diretamente da Receita Federal (via API ReceitaWS) e utilizem essas informações para preencher modelos de documentos dinamicamente. Os PDFs gerados podem ser baixados e, futuramente, enviados por e-mail.

## ✨ Funcionalidades

- **Autenticação de Usuários**: Sistema de registro e login seguro com gerenciamento de sessão via JWT (JSON Web Tokens).
- **Consulta CNPJ**: Interface para buscar informações detalhadas de empresas (razão social, nome fantasia, endereço, atividades, QSA, etc.) utilizando a API ReceitaWS.
- **Geração de Documentos (PDF)**: Capacidade de gerar contratos e procurações em PDF, preenchendo tags nos modelos com os dados obtidos da Receita Federal.
- **Download de Documentos**: PDFs gerados são disponibilizados para download direto na aplicação.
- **Envio por E-mail (Futuro)**: Funcionalidade planejada para enviar os documentos gerados para o e-mail cadastrado do usuário.
- **Interface Intuitiva**: Frontend desenvolvido em React com design responsivo e fácil navegação.

## 🚀 Tecnologias Utilizadas

### Backend
- **Python**: Linguagem de programação principal.
- **Flask**: Microframework web para o desenvolvimento da API RESTful.
- **Flask-SQLAlchemy**: ORM para interação com o banco de dados.
- **Flask-JWT-Extended**: Extensão para autenticação baseada em JWT.
- **ReportLab**: Biblioteca para geração de PDFs (a ser implementada para preenchimento de modelos).
- **Requests**: Biblioteca para fazer requisições HTTP (usada para integrar com a API ReceitaWS).
- **SQLite**: Banco de dados leve para desenvolvimento e testes (pode ser facilmente migrado para PostgreSQL/MySQL em produção).
- **Gunicorn**: Servidor WSGI para servir a aplicação Flask em produção.

### Frontend
- **React**: Biblioteca JavaScript para construção da interface do usuário.
- **Vite**: Ferramenta de build rápido para projetos React.
- **Tailwind CSS**: Framework CSS para estilização rápida e responsiva.
- **Axios (ou Fetch API)**: Para comunicação com o backend.

### Infraestrutura (Produção)
- **Nginx**: Servidor web e proxy reverso para servir o frontend e rotear requisições para o backend.
- **Systemd**: Gerenciador de serviços para garantir que o backend e o Nginx rodem continuamente.
- **SSL/TLS**: Para comunicação segura via HTTPS.

## ⚙️ Configuração e Execução Local

Siga os passos abaixo para configurar e rodar a aplicação em seu ambiente de desenvolvimento local.

### Pré-requisitos
- Python 3.8+
- Node.js 18+ (necessário para o frontend)
- pnpm (recomendado para o frontend, ou npm/yarn)
- Git

### 1. Clonar o Repositório

```bash
git clone <URL_DO_SEU_REPOSITORIO>
cd <NOME_DA_PASTA_DO_PROJETO>
```

### 2. Configurar e Rodar o Backend (Flask)

```bash
cd contract_generator_backend

# Criar e ativar ambiente virtual
python3 -m venv venv
source venv/bin/activate  # No Windows: .\venv\Scripts\activate

# Instalar dependências
pip install -r requirements.txt
pip install gunicorn  # Gunicorn é usado em produção, mas pode ser útil para testes locais

# Rodar o servidor Flask
# O script start_server_5002.py inicia o Flask na porta 5002
python src/start_server_5002.py

# Opcional: Para rodar com Gunicorn (simulando produção)
# gunicorn --bind 127.0.0.1:5002 wsgi:application
```

O backend estará disponível em `http://localhost:5002`.

### 3. Configurar e Rodar o Frontend (React)

O frontend é a parte da aplicação que você vê e interage no seu navegador. Ele é construído com React e utiliza ferramentas como `pnpm` para gerenciar suas dependências e otimizar o código.

**Importante:** Se você receber o erro "npm not found" ou "pnpm not found", isso significa que o Node.js e/ou o gerenciador de pacotes não estão instalados ou configurados corretamente no seu sistema. Certifique-se de que o Node.js (que inclui o npm) e o pnpm estejam instalados conforme os "Pré-requisitos" acima.

1.  **Navegue até a pasta do frontend:**
    Abra seu terminal e digite:

    ```bash
    cd ../contract_generator_frontend
    ```

2.  **Instalar as dependências do frontend:**
    Para que o frontend funcione, ele precisa de várias bibliotecas e ferramentas. O `pnpm` (ou `npm`/`yarn`) é um gerenciador de pacotes que baixa e organiza tudo isso para você. Digite:

    ```bash
    pnpm install
    ```
    *   **O que este comando faz?** Ele lê o arquivo `package.json` (que **existe** na raiz da pasta `contract_generator_frontend`) do projeto. Este arquivo lista todas as dependências do frontend. Em seguida, ele baixa essas dependências da internet e as instala em uma pasta chamada `node_modules` dentro do seu projeto. É um passo crucial para preparar o ambiente do frontend.
    *   **Alternativa:** Se `pnpm install` falhar ou você preferir, e tiver `npm` instalado, pode tentar `npm install`.

3.  **Rodar o servidor de desenvolvimento do React:**
    Após a instalação das dependências, você pode iniciar o servidor de desenvolvimento do React. Este servidor permite que você veja e teste o frontend no seu navegador enquanto o desenvolve. Ele automaticamente recarrega a página a cada alteração que você faz no código.

    ```bash
    pnpm run dev
    ```

    *   **O que este comando faz?** Ele inicia um servidor local que serve os arquivos do seu frontend. Você verá uma mensagem no terminal indicando em qual endereço (geralmente `http://localhost:5173`) o frontend está disponível. Abra este endereço no seu navegador para interagir com a aplicação.

O frontend estará disponível em `http://localhost:5173` (ou outra porta, conforme indicado pelo Vite).

## 🌐 Implantação em Produção

Para implantar a aplicação em um ambiente de produção, consulte o guia detalhado `production_deployment_guide.md` na raiz do projeto. Este guia aborda:

- Preparação do servidor (Ubuntu/Debian)
- Configuração de Nginx como proxy reverso e servidor de arquivos estáticos
- Configuração de Gunicorn para o backend Flask
- Uso de Systemd para gerenciamento de serviços
- Configuração de SSL/TLS (Let's Encrypt)
- Scripts de atualização e monitoramento
- Sugestões de provedores de hospedagem (VPS, PaaS, Serverless)

## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues, enviar pull requests ou sugerir melhorias.

## 📝 Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

---

**Desenvolvido por:** Manus AI
**Data:** $(date)
**Versão:** 1.0

