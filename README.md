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

### Análise Técnica

O Named Volume `mysql-prod-data` é armazenado em `/var/lib/docker/volumes/`
no host, fora do ciclo de vida do container. Ao remover o container com
`docker rm -f`, apenas o container é destruído — o volume permanece intacto.
Ao recriar um novo container apontando para o mesmo volume, o MySQL encontra
os arquivos de dados existentes e retoma o estado anterior, confirmando a persistência.

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

---

# Cenário 2 — Backup e Restauração

### Análise Técnica

Existem duas estratégias de backup. O backup de volume (`.tar.gz`) copia os
arquivos brutos do MySQL — útil para migração de servidor. O `mysqldump` gera
um arquivo SQL com os comandos para recriar o banco — mais portátil e legível.
Na prática, recomenda-se usar os dois em conjunto.

## Passo 1 — Backup com tar.gz

```bash
docker run --rm \
  -v mysql-prod-data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu \
  tar czf /backup/mysql-prod-backup.tar.gz -C /data .

ls -lh backups/
```

Sobe um container Ubuntu temporário (`--rm` = some ao terminar), monta o volume
do MySQL e a pasta local `backups`, e comprime tudo com `tar`.

![01-backup-tar-criado](https://github.com/user-attachments/assets/9bc1987f-b05b-4e9e-a6e6-0f4969f598c0)

## Passo 2 — Backup com mysqldump

```bash
docker exec mysql-server2 mysqldump -uroot -p123456 empresa > backups/empresa-dump.sql
ls -lh backups/
cat backups/empresa-dump.sql
```

![02-mysqldump-criado](https://github.com/user-attachments/assets/b11b1180-9309-4cd8-8c64-e16e7449d15a)

## Passo 3 — Simular perda de dados

```bash
docker rm -f mysql-server2
docker volume rm mysql-prod-data
docker volume ls
docker ps -a
```

![03-volume-removido-desastre](https://github.com/user-attachments/assets/95652ef6-6d4c-4e6b-a02c-e0ecbb9dad57)

## Passo 4 — Restaurar os dados

```bash
docker volume create mysql-prod-data

docker exec -i mysql-server2 mysql -uroot -p123456 -e "CREATE DATABASE IF NOT EXISTS empresa;"

docker exec -i mysql-server2 mysql -uroot -p123456 empresa < backups/empresa-dump.sql

docker exec mysql-server2 mysql -uroot -p123456 empresa -e "SELECT * FROM usuarios;"
```

![04-dados-restaurados](https://github.com/user-attachments/assets/3d204a12-492e-4a64-bf83-51d1b48d479b)

---

# Cenário 3 — Bind Mount

### Análise Técnica

Bind Mount é diferente de Named Volume. Em vez de o Docker gerenciar o
armazenamento, você mapeia uma pasta real do host diretamente para dentro
do container. Mudanças feitas no host aparecem no container em tempo real,
e vice-versa. É muito usado em desenvolvimento — você edita o código no
seu editor, e o container vê as mudanças na hora.

## Passo 1 — Criar diretório local

```bash
mkdir -p ~/docker-bind-test
echo "Arquivo criado no HOST em $(date)" > ~/docker-bind-test/arquivo-host.txt
ls ~/docker-bind-test/
```

![01-diretorio-host](https://github.com/user-attachments/assets/1619c29b-59a8-4e0e-b690-a746b277c418)

## Passo 2 — Subir container com Bind Mount

```bash
docker run -d \
  --name container-bind \
  -v ~/docker-bind-test:/app/dados \
  ubuntu \
  sleep infinity

docker ps
```

![02-container-bind-rodando](https://github.com/user-attachments/assets/1249fe29-4dd3-4144-bc58-ca60b422dcff)

## Passo 3 — Validar acesso dentro do container

```bash
docker exec -it container-bind ls /app/dados
docker exec -it container-bind cat /app/dados/arquivo-host.txt
```

## Passo 4 — Criar arquivo dentro do container e ver no host

```bash
docker exec -it container-bind bash -c "echo 'Arquivo criado DENTRO do container' > /app/dados/arquivo-container.txt"

ls ~/docker-bind-test/
cat ~/docker-bind-test/arquivo-container.txt
```

![04-arquivo-container-no-host](https://github.com/user-attachments/assets/7a9d69ba-e382-4a04-98ab-53cfbdf42b7a)

---

# Cenário 4 — Compartilhamento Entre Containers

### Análise Técnica

Um Named Volume pode ser montado em múltiplos containers ao mesmo tempo.
Isso permite que um container "produtor" escreva dados e outro container
"consumidor" leia esses dados em tempo real, sem comunicação de rede entre
eles — apenas pelo sistema de arquivos compartilhado. Simula padrões reais
como um servidor web escrevendo logs que um agente de coleta lê.

## Passo 1 — Criar volume compartilhado

```bash
docker volume create volume-compartilhado
docker volume ls
```

![01-volume-compartilhado](https://github.com/user-attachments/assets/995a4e5f-1b1a-48be-aba2-8a5ea487f7a7)

## Passo 2 — Container produtor

```bash
docker run -d \
  --name container-produtor \
  -v volume-compartilhado:/dados \
  ubuntu \
  bash -c "while true; do echo \"Mensagem: \$(date)\" >> /dados/log.txt; sleep 3; done"

docker ps
```

![02-produtor-rodando](https://github.com/user-attachments/assets/c42f15e6-23a4-48ba-bfec-b29f2e23fedb)

## Passo 3 — Container consumidor

```bash
docker run -d \
  --name container-consumidor \
  -v volume-compartilhado:/dados \
  ubuntu \
  sleep infinity

sleep 10

docker exec container-consumidor cat /dados/log.txt
```

![03-consumidor-lendo-dados](https://github.com/user-attachments/assets/71f915c9-e6e3-4cc8-9269-cfa6422a0e61)

## Passo 4 — Validar em tempo real

```bash
sleep 10
docker exec container-consumidor wc -l /dados/log.txt
docker exec container-consumidor tail -5 /dados/log.txt
```

![04-dados-em-tempo-real-pt1](https://github.com/user-attachments/assets/2e45c18f-6bf9-4266-a436-244b96bbec5a)

![04-dados-em-tempo-real-pt2](https://github.com/user-attachments/assets/4c74dcf4-6208-4da0-8062-66da38eebd96)

---

# Cenário 5 — Automação de Backup com Bash

### Análise Técnica

Em ambientes reais de produção, backups são feitos automaticamente por scripts
agendados via `cron`. O script Bash encapsula toda a lógica de backup — geração
do nome com data/hora, execução do dump, compressão — permitindo que qualquer
pessoa execute com um único comando.

## Passo 1 — Script de backup (scripts/backup.sh)

```bash
#!/bin/bash

# ============================================
# Script de Backup Automatizado - MySQL Docker
# ============================================

CONTAINER="mysql-server2"
BANCO="empresa"
USUARIO="root"
SENHA="123456"
DIR_BACKUP="$(pwd)/backups"
DATA=$(date +"%Y%m%d_%H%M%S")
ARQUIVO_SQL="$DIR_BACKUP/backup_${DATA}.sql"
ARQUIVO_GZ="$DIR_BACKUP/backup_${DATA}.tar.gz"

echo "======================================"
echo "Iniciando backup: $(date)"
echo "======================================"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERRO: container '$CONTAINER' não está rodando."
  exit 1
fi

mkdir -p "$DIR_BACKUP"

echo "[1/3] Gerando dump SQL..."
docker exec "$CONTAINER" mysqldump -u"$USUARIO" -p"$SENHA" "$BANCO" > "$ARQUIVO_SQL"

echo "[2/3] Comprimindo arquivo..."
tar czf "$ARQUIVO_GZ" -C "$DIR_BACKUP" "$(basename $ARQUIVO_SQL)"
rm "$ARQUIVO_SQL"

echo "[3/3] Backup concluído!"
echo "Arquivo gerado: $ARQUIVO_GZ"
echo "Tamanho: $(du -h $ARQUIVO_GZ | cut -f1)"
echo "======================================"
```

## Passo 2 — Script de restauração (scripts/restore.sh)

```bash
#!/bin/bash

CONTAINER="mysql-server2"
BANCO="empresa"
USUARIO="root"
SENHA="123456"
ARQUIVO_GZ="$1"

if [ -z "$ARQUIVO_GZ" ]; then
  echo "Uso: ./restore.sh <arquivo.tar.gz>"
  exit 1
fi

echo "Restaurando de: $ARQUIVO_GZ"
tar xzf "$ARQUIVO_GZ" -C /tmp/
ARQUIVO_SQL=$(tar tzf "$ARQUIVO_GZ" | head -1)
docker exec -i "$CONTAINER" mysql -u"$USUARIO" -p"$SENHA" "$BANCO" < "/tmp/$ARQUIVO_SQL"
echo "Restauração concluída!"
```

## Passo 3 — Executar o script

```bash
chmod +x scripts/backup.sh scripts/restore.sh
sudo ./scripts/backup.sh
```

![01-script-executado](https://github.com/user-attachments/assets/884544ec-9cb0-4945-a2c7-d55189af427a)

## Passo 4 — Confirmar arquivo gerado

```bash
ls -lh backups/
```

![02-backup-gerado](https://github.com/user-attachments/assets/95de8c95-161b-4ea8-abb4-4d9d73a40b82)

---

## Conclusão

Esta atividade demonstrou na prática os principais mecanismos de persistência
de dados em containers Docker:

- **Named Volumes** garantem que dados sobrevivam à remoção de containers
- **Bind Mounts** permitem sincronização em tempo real entre host e container
- **Backup com tar.gz** preserva os arquivos brutos do volume para migração
- **mysqldump** gera backups SQL portáteis e legíveis
- **Scripts Bash** automatizam operações repetitivas de infraestrutura

O uso correto desses recursos é essencial para ambientes de produção confiáveis.
