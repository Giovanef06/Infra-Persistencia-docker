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

## cenario2/01-backup-tar-criado

docker run --rm \
  -v mysql-prod-data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu \
  tar czf /backup/mysql-prod-backup.tar.gz -C /data .

ls -lh backups/

O que esse comando faz: sobe um container Ubuntu temporário (--rm = some ao terminar), monta o volume do MySQL e a pasta local backups, e comprime tudo com tar.

<img width="733" height="170" alt="01-backup-tar-criado" src="https://github.com/user-attachments/assets/9bc1987f-b05b-4e9e-a6e6-0f4969f598c0" />


