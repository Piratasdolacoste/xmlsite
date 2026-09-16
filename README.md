# Site de construções — passo a passo

## 1. Crie o repositório
1. Entre no GitHub (crie uma conta se não tiver).
2. Clique em **New repository**.
3. Dê um nome, ex: `construcoes-tfm`.
4. Marque como **Public**.
5. Clique em **Create repository**.

## 2. Suba estes arquivos
Na página do repositório recém-criado:
1. Clique em **Add file → Upload files**.
2. Arraste **todos** os arquivos e pastas deste pacote (`index.html`, `galeria.html`,
   `script-base.lua`, `scripts/`, `.github/`, `preview/`) mantendo a estrutura de pastas.
3. Clique em **Commit changes**.

(Se preferir usar `git` pela linha de comando, também funciona normalmente —
`git init`, `git add .`, `git commit`, `git push`.)

## 3. Ative o GitHub Pages
1. No repositório, vá em **Settings → Pages**.
2. Em **Source**, escolha a branch `main` e a pasta `/ (root)`.
3. Clique em **Save**.
4. Espere 1–2 minutos. O GitHub vai te dar um link parecido com
   `https://SEU_USUARIO.github.io/SEU_REPO/`.

## 4. Dê permissão de escrita para as Actions
1. Vá em **Settings → Actions → General**.
2. Desça até **Workflow permissions**.
3. Marque **Read and write permissions**.
4. Clique em **Save**.

(Sem isso, a Action não consegue commitar as construções automaticamente.)

## 5. Crie a label "construcao"
1. Vá na aba **Issues → Labels**.
2. Clique em **New label**.
3. Nome: `construcao` (sem acento, exatamente assim).
4. Salve.

## 6. Ajuste os arquivos com o nome do seu repositório
Troque `SEU_USUARIO/SEU_REPO` pelo caminho real do seu repositório (ex: `joaosilva/construcoes-tfm`) nos seguintes lugares:
- `index.html` → variável `REPO`
- `galeria.html` → variável `REPO`

Pode editar direto pelo site do GitHub (clique no arquivo → ícone de lápis → salvar).

## 7. Teste
1. Acesse `https://SEU_USUARIO.github.io/SEU_REPO/`.
2. Preencha o formulário com uma construção de teste (nick, nome, descrição, XML feito no
   [miceditor](https://entibo.github.io/miceditor)).
3. Clique em enviar — vai abrir uma issue no GitHub, já preenchida. Confirme criando a issue.
4. Espere ~30 segundos (a Action está rodando — dá pra acompanhar na aba **Actions** do repositório).
5. A issue deve fechar sozinha com um comentário de confirmação.
6. Acesse `galeria.html` no seu site — a construção deve aparecer com o preview visual.
7. O script atualizado (pronto pra colar no editor de módulos do Transformice) aparece
   no final da página `galeria.html`.

## Observações importantes
- O "nick" no formulário é só uma identificação simples — não é uma senha nem uma conta real.
  Quem realmente fica registrado é a conta do GitHub usada para abrir a issue.
- O código do miceditor (pasta `preview/`) não tem licença declarada pelo autor original
  (entibo). Antes de deixar isso no ar publicamente, é uma boa ideia mandar uma mensagem
  pra ele avisando/pedindo autorização — é cortesia com quem fez o trabalho, mesmo o
  código sendo público.
- Se quiser moderar as construções antes delas entrarem no script (em vez de aceitar tudo
  automaticamente), me avise — dá pra trocar o "commit direto" da Action por um Pull
  Request que você aprova manualmente.
