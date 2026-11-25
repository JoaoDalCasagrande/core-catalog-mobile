# Core Catalog Mobile

Aplicativo Flutter (Android e iOS) do projeto **Core Catalog**: a versão mobile do front-end web
(`core-catalog-web`), consumindo a mesma API NestJS (`core-catalog`).

## Membros do grupo

| Nome |
| ---- |
| João Gabriel Dal'Forno Casagrande |
| _(nome do integrante)_ |
| _(nome do integrante)_ |
| _(nome do integrante)_ |

## Nome do aplicativo

**Core Catalog** (pacote Flutter `core_catalog_mobile`)

## Resumo das funcionalidades

O app é um catálogo de peças de computador para montar *builds* (configurações de PC) sem
estourar o orçamento. Ele tem as mesmas telas e regras do sistema web:

- **Login e cadastro**: entrar com e-mail e senha ou criar conta (`/auth/login`, `/auth/register`).
  O token JWT fica salvo no aparelho, então o usuário continua logado ao reabrir o app.
  Ações que exigem conta abrem o login e continuam de onde pararam depois de entrar.
- **Catálogo de peças** (aberto a todos): lista com preço e consumo em watts, filtro por
  categoria (com contagem), filtro por fabricante, busca por nome/fabricante, ordenação
  (menor preço, maior preço, menor consumo, nome) e "puxar para atualizar".
- **Adicionar peça a uma build**: o botão *Adicionar* pergunta em qual build colocar a peça
  e a quantidade. A API recusa a peça se o total passar do orçamento, e o app mostra o aviso.
- **Builds**: lista das builds do usuário, criação de nova build (nome + orçamento máximo,
  exige perfil) e tela de resumo com total gasto, quanto ainda cabe, consumo total, a
  **régua do orçamento** colorida por categoria, alerta de orçamento estourado e a lista de
  peças com quantidade, unitário e subtotal. *Adicionar peça* abre o catálogo já ligado à build.
- **Meu perfil**: criar ou editar nome completo, data de nascimento e avatar (URL da imagem),
  com prévia do avatar; também mostra a conta logada, o servidor da API e o botão *Sair*.
- **Painel (Admin)** com contagem de registros e:
  - **Usuários**: cadastrar, editar (nome/e-mail) e excluir;
  - **Perfis**: cadastrar escolhendo o usuário (só aparecem usuários sem perfil), editar e excluir;
  - **Peças**: listar e cadastrar (nome, categoria, fabricante, preço e consumo);
  - **Fabricantes**: listar e cadastrar.
- **Servidor da API configurável** dentro do app (ícone de servidor no login ou em *Meu perfil*),
  para usar em celular físico sem recompilar.

Visual baseado no web: mesma paleta verde, fontes IBM Plex Sans / IBM Plex Sans Condensed,
valores em reais (R$) e datas no formato brasileiro.

## Como rodar

1. Suba a API (`core-catalog`), que escuta na porta **3001**:
   ```bash
   npm install
   npx prisma migrate dev
   npm run start:dev
   ```
2. No app:
   ```bash
   flutter pub get
   flutter run
   ```

Endereço da API usado pelo app:

| Onde o app roda | Endereço padrão |
| --- | --- |
| Emulador Android | `http://10.0.2.2:3001` (é o `localhost` do computador) |
| Simulador iOS / web / desktop | `http://localhost:3001` |
| Celular físico | Configure no app o IP do computador, ex.: `http://192.168.0.10:3001` |

Também é possível definir na hora de rodar: `flutter run --dart-define=API_URL=http://192.168.0.10:3001`.

> O Android já está liberado para acessar a API por HTTP (`INTERNET` e `usesCleartextTraffic`
> no `AndroidManifest.xml`) e o iOS também (`NSAppTransportSecurity` no `Info.plist`).

### Se a pasta `android`/`ios` der erro de versão

As pastas `android/` e `ios/` foram geradas com os modelos do Flutter 3.50 (stable). Se a versão
do Flutter instalada for mais antiga e o build do Android reclamar da versão do Gradle/AGP,
recrie as pastas de plataforma (o código em `lib/` não muda):

```bash
rm -rf android ios
flutter create --platforms=android,ios --org com.corecatalog .
```

Depois, adicione de novo as duas liberações de rede:
- `android/app/src/main/AndroidManifest.xml`: `<uses-permission android:name="android.permission.INTERNET"/>`
  antes de `<application>` e `android:usesCleartextTraffic="true"` dentro de `<application ...>`;
- `ios/Runner/Info.plist`: a chave `NSAppTransportSecurity` com `NSAllowsArbitraryLoads = true`.

## Testes

```bash
flutter test
```

Testes de unidade dos formatadores (moeda, datas, régua) e da leitura dos JSONs da API.

## Estrutura

```
lib/
├── main.dart                 # inicia a sessão salva e abre o app
├── config/api_config.dart    # endereço padrão da API
├── models/models.dart        # Componente, Fabricante, Build, Resumo, Perfil, Usuário
├── services/
│   ├── session.dart          # token JWT + URL da API (shared_preferences)
│   ├── api_client.dart       # HTTP + Bearer token + tratamento de erros
│   └── core_catalog_api.dart # todas as rotas da API
├── theme/app_theme.dart      # cores e estilos do web
├── utils/formatters.dart     # R$, datas, iniciais, campo de moeda
├── widgets/                  # régua do orçamento, avatar, alertas, campo de data
└── screens/
    ├── home_shell.dart       # barra inferior: Catálogo, Builds, Perfil, Admin
    ├── auth/                 # login e cadastro
    ├── catalog/              # catálogo de peças
    ├── builds/               # lista, nova build e resumo
    ├── profile/              # meu perfil
    ├── admin/                # painel, usuários, perfis, peças, fabricantes
    └── settings/             # servidor da API
```

Pacotes usados: `http`, `shared_preferences`, `flutter_localizations` (datas e textos em pt-BR).
Fontes IBM Plex sob a licença SIL OFL (`assets/fonts/OFL.txt`).
