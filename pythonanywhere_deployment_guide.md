# Guia de Implantação da Aplicação no PythonAnywhere

Este guia detalha os passos necessários para implantar a aplicação "Gerador de Contratos e Procurações" no PythonAnywhere, uma plataforma de hospedagem em nuvem que oferece um ambiente Python completo, incluindo servidores web WSGI, bancos de dados e agendamento de tarefas. O PythonAnywhere é uma excelente opção para aplicações Flask devido à sua facilidade de uso e ao suporte nativo a Python.

## 1. Visão Geral da Implantação

A aplicação é composta por duas partes principais:

*   **Backend (Flask):** Responsável pela lógica de negócio, autenticação, integração com a API da Receita Federal e geração de PDFs. Será hospedado como uma aplicação web WSGI no PythonAnywhere.
*   **Frontend (React):** A interface do usuário, que interage com o backend. Será construído e seus arquivos estáticos (HTML, CSS, JavaScript) serão servidos diretamente pelo servidor web do PythonAnywhere.

## 2. Preparação do Ambiente no PythonAnywhere

Antes de implantar a aplicação, você precisará configurar seu ambiente no PythonAnywhere.

### 2.1. Criação de Conta e Acesso ao Console

1.  **Crie uma conta no PythonAnywhere:** Se você ainda não tem uma, acesse [www.pythonanywhere.com](https://www.pythonanywhere.com/) e crie uma conta (a conta "Free" é suficiente para começar, mas pode ter limitações de recursos e tempo de atividade).
2.  **Acesse o Dashboard:** Após o login, você será direcionado para o seu dashboard.
3.  **Abra um Bash Console:** No dashboard, clique em "Consoles" e depois em "Bash". Este será o seu terminal para interagir com o ambiente do PythonAnywhere.

### 2.2. Clonando o Repositório da Aplicação

No Bash Console, você precisará clonar o repositório da sua aplicação. Assumindo que sua aplicação está em um repositório Git (GitHub, GitLab, Bitbucket, etc.):

```bash
cd ~
git clone <URL_DO_SEU_REPOSITORIO>
```

Substitua `<URL_DO_SEU_REPOSITORIO>` pelo URL real do seu repositório Git. Por exemplo, se o nome da sua pasta for `contract_generator`, o comando seria:

```bash
cd ~
git clone https://github.com/seu-usuario/contract_generator.git
```

Após clonar, você terá as pastas `contract_generator_backend` e `contract_generator_frontend` dentro do seu diretório home (`/home/seu-usuario/`).

## 3. Implantação do Backend (Flask)

O backend Flask será configurado como uma aplicação web WSGI no PythonAnywhere.

### 3.1. Configuração do Ambiente Virtual

É crucial usar um ambiente virtual para gerenciar as dependências do Python.

No Bash Console, navegue até a pasta do backend e crie o ambiente virtual:

```bash
cd ~/contract_generator/contract_generator_backend
python3.10 -m venv venv  # Use a versão do Python disponível no PythonAnywhere (ex: python3.10)
source venv/bin/activate
pip install -r requirements.txt
```

**Observações:**

*   O PythonAnywhere geralmente oferece várias versões do Python. Verifique qual versão é a padrão ou a mais recente disponível (ex: `python3.8`, `python3.9`, `python3.10`). Você pode verificar as versões disponíveis digitando `ls /usr/bin/python*` no console.
*   Certifique-se de que o arquivo `requirements.txt` na pasta `contract_generator_backend` esteja atualizado com todas as dependências do seu projeto Flask (flask, flask-cors, flask-jwt-extended, sqlalchemy, requests, reportlab, etc.). Se não estiver, você pode gerá-lo localmente com `pip freeze > requirements.txt` antes de fazer o push para o repositório.

### 3.2. Criação da Aplicação Web no PythonAnywhere

1.  **Navegue até a aba "Web"** no seu dashboard do PythonAnywhere.
2.  Clique em **"Add a new web app"**.
3.  Selecione a **versão do Python** que você usou para criar o ambiente virtual (ex: Python 3.10).
4.  Escolha **"Flask"** como framework.
5.  **Caminho do Código (Code path):** Insira o caminho para a pasta raiz do seu backend Flask. Por exemplo: `/home/seu-usuario/contract_generator/contract_generator_backend`.
6.  **Caminho do Arquivo WSGI (WSGI configuration file):** O PythonAnywhere criará um arquivo WSGI padrão. Você precisará editá-lo. O caminho padrão será algo como `/var/www/seu-usuario_pythonanywhere_com_wsgi.py`.

### 3.3. Configuração do Arquivo WSGI

Este é o passo mais importante para o backend. Você precisará editar o arquivo WSGI gerado pelo PythonAnywhere para apontar para a sua aplicação Flask.

1.  No dashboard do PythonAnywhere, vá para a aba "Web" e clique no link do **"WSGI configuration file"** (geralmente `/var/www/seu-usuario_pythonanywhere_com_wsgi.py`).
2.  **Edite o conteúdo** para que se pareça com o seguinte (remova o conteúdo existente e substitua por este, ajustando os caminhos):

    ```python
    import sys
    import os

    # Adicione o caminho para a pasta raiz do seu projeto Flask
    # Substitua \'seu-usuario\' pelo seu nome de usuário no PythonAnywhere
    # e \'contract_generator_backend\' pelo nome da sua pasta do backend
    project_home = u\'\'/home/seu-usuario/contract_generator/contract_generator_backend\'\'
    if project_home not in sys.path:
        sys.path.insert(0, project_home)

    # Adicione o caminho para o ambiente virtual
    # Substitua \'seu-usuario\' pelo seu nome de usuário no PythonAnywhere
    activate_this = u\'\'/home/seu-usuario/contract_generator/contract_generator_backend/venv/bin/activate_this.py\'\'
    with open(activate_this) as f:
        exec(f.read(), dict(__file__=activate_this))

    # Importe e rode sua aplicação Flask
    # Certifique-se de que \'start_server_5002\' é o nome do seu arquivo Python principal
    # e \'app\' é a instância do seu aplicativo Flask dentro desse arquivo
    from src.start_server_5002 import app as application  # Renomeie \'app\' para \'application\'
    ```

    **Pontos importantes:**
    *   `project_home`: Deve apontar para a pasta `contract_generator_backend`.
    *   `activate_this`: Deve apontar para o arquivo `activate_this.py` dentro da pasta `venv/bin` do seu ambiente virtual.
    *   `from src.start_server_5002 import app as application`: Isso assume que seu arquivo principal do Flask é `start_server_5002.py` dentro da pasta `src` e que a instância do seu aplicativo Flask é chamada `app`. Se você nomeou o arquivo ou a instância de forma diferente, ajuste aqui. O PythonAnywhere espera que a instância da aplicação seja chamada `application`.

### 3.4. Configuração de Variáveis de Ambiente (Opcional, mas Recomendado)

Se você tiver variáveis de ambiente (como `JWT_SECRET_KEY`), você pode configurá-las na aba "Web" do PythonAnywhere, na seção "Environment variables". Adicione-as como pares chave-valor.

### 3.5. Reiniciando a Aplicação Web

Após fazer as alterações no arquivo WSGI ou nas variáveis de ambiente, volte para a aba "Web" e clique no botão **"Reload seu-usuario.pythonanywhere.com"** para que as mudanças entrem em vigor.

## 4. Implantação do Frontend (React)

O frontend React é a parte da aplicação que você vê e interage no navegador. Para que ele funcione em um ambiente de produção, precisamos "construí-lo" para que todos os seus arquivos (código, estilos, imagens) sejam otimizados e transformados em um formato que os navegadores entendam facilmente e que possa ser servido de forma eficiente.

### 4.1. Construindo o Frontend para Produção: Entendendo `npm`, `pnpm` e o Processo de Build

Você mencionou que o comando `npm` não foi encontrado e, mais recentemente, o erro `ERR_PNPM_NO_SCRIPT` ao tentar `pnpm run build`. Vamos esclarecer isso.

**O que são `npm` e `pnpm`?**

`npm` (Node Package Manager) e `pnpm` (performant npm) são **gerenciadores de pacotes** para projetos JavaScript. Pense neles como "organizadores" que baixam todas as "peças" (bibliotecas e ferramentas) que o seu projeto React precisa para funcionar e, em seguida, as montam de forma otimizada para serem usadas na internet. O `pnpm` é uma alternativa mais moderna e eficiente ao `npm`.

**O erro `ERR_PNPM_NO_SCRIPT`:**

Este erro significa que o `pnpm` não conseguiu encontrar um script chamado `build` no arquivo `package.json` **no diretório atual onde você executou o comando**. Embora eu tenha confirmado que o `package.json` *contém* o script `build`, é crucial que você esteja no diretório correto (`contract_generator_frontend`) ao executar o comando.

**Passos para garantir que `npm` e `pnpm` estejam disponíveis e construir o frontend:**

1.  **Verificar e Instalar Node.js e npm (se necessário):**
    No Bash Console do PythonAnywhere, tente verificar se o `node` e o `npm` já estão instalados:

    ```bash
    node -v
npm -v
    ```

    *   Se ambos os comandos retornarem um número de versão (ex: `v18.x.x`), significa que estão instalados. Pule para o passo 3.
    *   Se você receber "command not found" ou um erro similar, precisará instalá-los. O PythonAnywhere tem um guia para isso. Geralmente, você pode usar algo como:

        ```bash
        # Para instalar Node.js e npm (exemplo, verifique a documentação do PythonAnywhere para o método mais atualizado)
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
        ```
        *Nota: O `sudo` pode não funcionar em contas gratuitas do PythonAnywhere. Se não funcionar, você pode precisar instalar o Node.js em seu diretório home ou usar uma conta paga. Verifique a documentação oficial do PythonAnywhere sobre como instalar Node.js.* [1]

2.  **Instalar pnpm (se necessário):**
    Mesmo com o `npm` instalado, o `pnpm` pode não estar. Você pode instalá-lo globalmente usando o `npm`:

    ```bash
    npm install -g pnpm
    ```

    *   Verifique se foi instalado corretamente:

        ```bash
        pnpm -v
        ```

3.  **Navegar até a pasta do frontend e verificar o `package.json`:**
    **Este passo é CRÍTICO.** Você deve estar dentro da pasta `contract_generator_frontend` para que o `pnpm` encontre o `package.json` e seus scripts.

    No Bash Console do PythonAnywhere, digite o seguinte comando para ir para a pasta onde o código do seu frontend React está localizado:

    ```bash
    cd ~/contract_generator/contract_generator_frontend
    ```

    Após entrar na pasta, você pode verificar se o `package.json` está lá e se o script `build` existe, usando o comando:

    ```bash
    cat package.json | grep \"build\"
    ```
    Você deve ver uma linha como `"build": "vite build",` na saída.

4.  **Instalar as dependências do frontend:**
    Agora que `pnpm` (ou `npm`) está disponível e você está no diretório correto, você pode instalar as dependências do seu projeto React. Este comando lê o arquivo `package.json` e baixa todas as bibliotecas e ferramentas necessárias.

    ```bash
    pnpm install
    ```

    *   **O que este comando faz?** Ele lê o arquivo `package.json` (que está na pasta `contract_generator_frontend`). Este arquivo lista todas as bibliotecas e ferramentas que o seu frontend React utiliza. O `pnpm install` então baixa todas essas bibliotecas da internet e as organiza em uma pasta chamada `node_modules` dentro do seu projeto. É como se ele montasse uma caixa de ferramentas completa para o seu projeto React.
    *   **Se `pnpm install` falhar:** Se você ainda tiver problemas, tente usar `npm install` como alternativa, caso o `pnpm` não esteja funcionando corretamente no seu ambiente.

5.  **Construir a aplicação para produção:**
    Depois que todas as dependências estão instaladas, precisamos "construir" (ou "compilar") o seu projeto React. Este processo pega todo o código que você escreveu (que é otimizado para desenvolvimento) e o transforma em um conjunto de arquivos (HTML, CSS, JavaScript) que são pequenos, rápidos e eficientes para serem carregados por qualquer navegador de internet. Isso é o que chamamos de "build de produção".

    Para fazer isso, use o comando `pnpm run build`:

    ```bash
    pnpm run build
    ```

    *   **O que este comando faz?** Ele executa um script pré-definido no seu projeto (configurado no `package.json`) que otimiza e empacota todo o seu código React. O resultado final é uma nova pasta, geralmente chamada `dist` (ou `build`, dependendo da configuração do seu projeto, mas no nosso caso é `dist`), que contém todos os arquivos prontos para serem colocados em um servidor web.
    *   **Onde estão os arquivos?** Após a execução bem-sucedida, você encontrará uma nova pasta chamada `dist` dentro de `~/contract_generator/contract_generator_frontend/`. Esta pasta `dist` é o que você vai usar para a próxima etapa, que é configurar o PythonAnywhere para servir esses arquivos estáticos.

Em resumo, para o frontend, você precisa garantir que o Node.js e um gerenciador de pacotes (`npm` ou `pnpm`) estejam instalados, usar `pnpm install` para baixar as dependências e `pnpm run build` para criar a versão otimizada do seu site.

### 4.2. Configuração de Arquivos Estáticos no PythonAnywhere

Depois de construir o frontend, você precisa dizer ao PythonAnywhere onde encontrar os arquivos do seu site para que ele possa exibi-los aos visitantes.

1.  **Navegue até a aba "Web"** no seu dashboard do PythonAnywhere.
2.  Role para baixo até a seção **"Static files"**.
3.  Adicione uma nova entrada:
    *   **URL:** Digite `/` (uma única barra). Isso significa que o PythonAnywhere servirá os arquivos desta pasta como a página principal do seu site.
    *   **Path:** Insira o caminho completo para a pasta `dist` que foi criada no passo anterior. Por exemplo: `/home/seu-usuario/contract_generator/contract_generator_frontend/dist`.

    **Exemplo de Configuração de Arquivos Estáticos:**

    | URL         | Path                                                              |
    | :---------- | :---------------------------------------------------------------- |
    | `/`         | `/home/seu-usuario/contract_generator/contract_generator_frontend/dist` |

    Ao configurar `/` como URL para os arquivos estáticos, o PythonAnywhere servirá o seu frontend React como a página principal do seu domínio. As requisições que começam com `/api` (como as que seu frontend faz para o backend) ainda serão roteadas para o seu backend Flask, conforme configurado na seção 3.

### 4.3. Ajuste da URL do Backend no Frontend

No seu código React (frontend), ele está configurado para se comunicar com o backend usando o endereço `http://localhost:5002`. Quando você implanta a aplicação no PythonAnywhere, o endereço do backend mudará para o endereço do seu site no PythonAnywhere (por exemplo, `https://seu-usuario.pythonanywhere.com`).

Você precisará alterar essa URL no código do seu frontend. **É importante fazer essa alteração no seu código fonte local (no seu computador) e depois enviar as mudanças para o seu repositório Git. Em seguida, você fará um `git pull` no PythonAnywhere e refará o `pnpm run build` para que as mudanças sejam aplicadas.**

**Exemplo de alteração:**

De:

```javascript
const response = await fetch(`http://localhost:5002/api/login`, {
```

Para:

```javascript
const response = await fetch(`https://seu-usuario.pythonanywhere.com/api/login`, {
```

Lembre-se de fazer essa alteração em todos os arquivos `.jsx` relevantes (como `Login.jsx`, `Register.jsx`, `CNPJConsulta.jsx`) na pasta `src/components` do seu frontend, onde você faz chamadas para o backend.

## 5. Configuração do Banco de Dados

O PythonAnywhere suporta SQLite (que você está usando), MySQL e PostgreSQL. Para o SQLite, o arquivo `app.db` será criado automaticamente na primeira execução do seu aplicativo Flask, desde que o diretório `src/database` exista e seja gravável.

Certifique-se de que o caminho para o banco de dados no seu `start_server_5002.py` esteja correto e seja absoluto, apontando para um local dentro do seu diretório de projeto no PythonAnywhere (ex: `/home/seu-usuario/contract_generator/contract_generator_backend/src/database/app.db`).

## 6. Considerações Finais

*   **HTTPS:** O PythonAnywhere oferece HTTPS automaticamente para seus domínios `seu-usuario.pythonanywhere.com`.
*   **Limitações da Conta Gratuita:** A conta gratuita do PythonAnywhere tem limites de CPU, RAM e tempo de atividade. Para aplicações em produção com tráfego constante, considere fazer um upgrade para uma conta paga.
*   **Depuração:** Use os logs de erro do PythonAnywhere (na aba "Web") para depurar problemas no backend. Para o frontend, use as ferramentas de desenvolvedor do seu navegador.
*   **Atualizações:** Sempre que fizer alterações no código, você precisará fazer um `git pull` no Bash Console do PythonAnywhere, reinstalar dependências se necessário, e recarregar a aplicação web na aba "Web". Para o frontend, refaça o `pnpm run build` e recarregue a aplicação web.

Seguindo estes passos, você deverá ser capaz de implantar sua aplicação "Gerador de Contratos e Procurações" com sucesso no PythonAnywhere.

## Referências

[1] [PythonAnywhere - Installing Node.js](https://help.pythonanywhere.com/pages/Nodejs/)

