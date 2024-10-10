# Endpoints

Base url: http://localhost:4000

- GET /swagger
- GET /dev/mailbox
- GET /cameras
- POST /notify-users

# Como rodar a aplicação Phoenix

| É necessário ter o docker e o docker-compose instalado

```bash
docker-compose up -d app
```

# Como executar os tests
```bash
docker-compose exec app mix test
```

# Como executar o seeder
| Ao subir a aplicação pela primeira vez o seeder ja será executado automaticamente

```bash
docker-compose exec app mix run priv/repo/seeds.exs
```

## Detalhes da Implementação

#### Sobre o envio de email
Eu resolvi usar o Oban para realizar o envio dos email em background seguindo o fluxo:

```txt
POST /notify-users -> cria um job e enfileira -> em background executa o job que envia os emails para todos os usuários
```

Optei fazer assim por uma questão de simplicidade, porém essa abordagem tem a desvantagem que caso o envio de um email falhe o job como inteiro tbm irá falhar. O ideal seria dois jobs(na verdade 1 + n), o primeiro é um fannout pra criar um outro job de o envio de email para cada usuário, assim a aplicação ficaria mais resiliente e mais facil de gerenciar, seguindo o fluxo:

```txt
POST /notify-users -> cria um job fannout e enfileira -> em background executa o job do fannout(gera outro job para cada um dos usuários) -> executa o job do envio individual de email
```

#### Sobre o seed dos usuários
O seed está divido em basicamente em duas partes:
 - geração dos payloads com os dados aleatótios
 - inserção em massa no banco.

A etapa de geração dos payloads é totalmemente assincrona, por ser basicamente uma operação 100% de CPU. Já inserção é feita em lotes de 50 itens, por ser uma operação de IO.

Como o cenario de exemplo é pequeno, por uma questão de simplicidade, usei o `Repo.insert_all/2` do Ecto, mas em cenários onde a carga de dados é maior o ideal seria usar o `Ecto.Adapters.SQL.stream` em conjunto do comando `COPY TO` do postgres por ser mais otmizado, porém é mais chato de implementar ja que basicamente é uma query raw e um string no formato CSV.
