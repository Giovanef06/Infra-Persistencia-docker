# Infra Persistência Docker

## Introdução

Containers Docker são por natureza **efêmeros**: quando um container é removido,
todos os dados armazenados dentro dele são perdidos junto. Isso é chamado de
comportamento *stateless*.

Para aplicações que precisam guardar dados (bancos de dados, arquivos, logs),
é necessário usar mecanismos de persistência externos ao container. O Docker
oferece duas soluções principais: **Named Volumes** (gerenciados pelo Docker,
ideais para produção) e **Bind Mounts** (mapeiam pastas do host, ideais para
desenvolvimento).

O objetivo desta atividade é demonstrar na prática como configurar, validar,
fazer backup e automatizar a persistência de dados em ambientes containerizados.

---

## Ambiente Utilizado

| Item | Versão |
|---|---|
| Ubuntu | 22.04.5 LTS |
| Docker Engine | 28.2.2 |
| Docker Compose | 1.29.2 |
| Git | 2.34.1 |
| Hardware | 8GB RAM, x86_64 |

---

# Cenário 1 — Persistência com MySQL e Named Volume

## Etapa 1 — Criação do Volume

```bash
docker volume create mysql-prod-data
docker volume ls
```

Volume nomeado criado para armazenar os dados do MySQL de forma persistente.

![01-volume-criado](https://github.com/user-attachments/assets/0285f1a2-7574-4b02-bff3-db7fcdf600aa)

## Etapa 2 — Criar container MySQL

```bash
docker run -d \
  --name mysql-server \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -e MYSQL_DATABASE=empresa \
  -v mysql-prod-data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8
```

![02-container-mysql](https://github.com/user-attachments/assets/7f514bcb-79d3-4d47-b2f9-05a97bfc3daa)

## Etapa 3 — Criar tabela

```bash
docker exec -it mysql-server mysql -u root -p
```

```sql
USE empresa;

CREATE TABLE usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100),
  email VARCHAR(100)
);
```

![03-tabela-criada](https://github.com/user-attachments/assets/f60be521-46df-410e-9077-cbfaf63fccfa)

## Etapa 4 — Inserir e validar registros

```sql
INSERT INTO usuarios (nome, email) VALUES
  ('Carlos', 'carlos@gmail.com'),
  ('Ana', 'ana@gmail.com'),
  ('Marcos', 'marcos@gmail.com');

SELECT * FROM usuarios;
```

![04-registros](https://github.com/user-attachments/assets/128a1999-b566-4eb9-8756-cbf7f7e8d9bc)

## Etapa 5 — Remover container

```bash
docker rm -f mysql-server
```

![05-container-removido](https://github.com/user-attachments/assets/e924fc17-9efc-4922-bd76-af2addd8bfae)

## Etapa 6 — Recriar container e validar persistência

```bash
docker run -d \
  --name mysql-server2 \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -v mysql-prod-data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8

docker exec -it mysql-server2 mysql -u root -p
```

```sql
USE empresa;
SELECT * FROM usuarios;
```

![06-persistencia-validada](https://github.com/user-attachments/assets/7e61ae97-8cac-4e4f-abba-a1da4d15ae6c)

### Análise Técnica

O Named Volume `mysql-prod-data` é armazenado em `/var/lib/docker/volumes/`
no host, fora do ciclo de vida do container. Ao remover o container com
`docker rm -f`, apenas o container é destruído — o volume permanece intacto.
Ao recriar um novo container apontando para o mesmo volume, o MySQL encontra
os arquivos de dados existentes e retoma o estado anterior, confirmando a persistência.

## Cenário 2 — Backup e Restauração
Explicação técnica: Existem duas estratégias de backup. O backup de volume (.tar.gz) copia os arquivos brutos do MySQL — útil para migração de servidor. O mysqldump gera um arquivo SQL com os comandos para recriar o banco — mais portátil e legível. Na prática, use os dois.

## Passo 1 — Backup com tar.gz (backup do volume inteiro)

docker run --rm \
  -v mysql-prod-data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu \
  tar czf /backup/mysql-prod-backup.tar.gz -C /data .

ls -lh backups/

O que esse comando faz: sobe um container Ubuntu temporário (--rm = some ao terminar), monta o volume do MySQL e a pasta local backups, e comprime tudo com tar.

<img width="733" height="170" alt="01-backup-tar-criado" src="https://github.com/user-attachments/assets/9bc1987f-b05b-4e9e-a6e6-0f4969f598c0" />

## Passo 2 — Backup com mysqldump (backup SQL)

docker exec mysql-prod mysqldump -uroot -psenha123 empresa > backups/empresa-dump.sql
ls -lh backups/
cat backups/empresa-dump.sql

<img width="731" height="130" alt="02-mysqldump-criado" src="https://github.com/user-attachments/assets/b11b1180-9309-4cd8-8c64-e16e7449d15a" />

## Passo 3 — Simular perda de dados (o "desastre")

# Remove container E o volume — simula perda total
docker rm -f mysql-prod
docker volume rm mysql-prod-data

# Confirma que o volume sumiu
docker volume ls

<img width="1052" height="335" alt="03-volume-removido-desastre" src="https://github.com/user-attachments/assets/95652ef6-6d4c-4e6b-a02c-e0ecbb9dad57" />


## Passo 4 — Restaurar os dados

# Recria o volume
docker volume create mysql-prod-data

# Restaura os arquivos brutos do volume
docker run --rm \
  -v mysql-prod-data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu \
  tar xzf /backup/mysql-prod-backup.tar.gz -C /data

# Sobe o container novamente
docker run -d \
  --name mysql-prod \
  -e MYSQL_ROOT_PASSWORD=senha123 \
  -v mysql-prod-data:/var/lib/mysql \
  mysql:8.0

sleep 15

# Valida os dados
docker exec -it mysql-prod mysql -uroot -psenha123 empresa -e "SELECT * FROM usuarios;"

<img width="1056" height="584" alt="04-dados-restaurados" src="https://github.com/user-attachments/assets/3d204a12-492e-4a64-bf83-51d1b48d479b" />


## Cenário 3 — Bind Mount
Explicação técnica: Bind Mount é diferente de Named Volume. Em vez de o Docker gerenciar o armazenamento, você mapeia uma pasta real do seu computador (host) diretamente para dentro do container. Mudanças feitas no host aparecem no container em tempo real, e vice-versa. É muito usado em desenvolvimento — você edita o código no seu editor, e o container que está rodando a aplicação vê as mudanças na hora.

## Passo 1 — Criar diretório local

mkdir -p ~/docker-bind-test
echo "Arquivo criado no HOST em $(date)" > ~/docker-bind-test/arquivo-host.txt
ls ~/docker-bind-test/

<img width="736" height="116" alt="01-diretorio-host" src="https://github.com/user-attachments/assets/1619c29b-59a8-4e0e-b690-a746b277c418" />


## Passo 2 — Subir container com Bind Mount

docker run -d \
  --name container-bind \
  -v ~/docker-bind-test:/app/dados \
  ubuntu \
  sleep infinity

  ## Passo 3 — Validar acesso dentro do container 
  
  # Acessa o container e lista o diretório montado
docker exec -it container-bind ls /app/dados
docker exec -it container-bind cat /app/dados/arquivo-host.txt

docker ps

<img width="734" height="311" alt="02-container-bind-rodando" src="https://github.com/user-attachments/assets/1249fe29-4dd3-4144-bc58-ca60b422dcff" />


## Passo 4 — Criar arquivo dentro do container e ver no host
# Cria arquivo de dentro do container
docker exec -it container-bind bash -c "echo 'Arquivo criado DENTRO do container' > /app/dados/arquivo-container.txt"

# Verifica no host que o arquivo apareceu
ls ~/docker-bind-test/
cat ~/docker-bind-test/arquivo-container.txt

<img width="738" height="213" alt="04-arquivo-container-no-host" src="https://github.com/user-attachments/assets/7a9d69ba-e382-4a04-98ab-53cfbdf42b7a" />



