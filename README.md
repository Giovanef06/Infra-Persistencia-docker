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

## Ambiente Utilizado
- Ubuntu: 22.04.5 LTS
- Docker Engine: 28.2.2
- Docker Compose: 1.29.2
- Git: 2.34.1
- Hardware: 8GB RAM, arquitetura x86_64

  

  # Cenário 1 — Persistência com MySQL

## Etapa 1 — Criação do Volume

bash
docker volume create mysql-prod-data


Volume criado para persistência de dados.
<img width="736" height="290" alt="01-volume-criado" src="https://github.com/user-attachments/assets/0285f1a2-7574-4b02-bff3-db7fcdf600aa" />

## Etapa 2 - Criar container
docker run -d \
--name mysql-server \
-e MYSQL_ROOT_PASSWORD=123456 \
-e MYSQL_DATABASE=empresa \
-v mysql-prod-data:/var/lib/mysql \
-p 3306:3306 \
mysql:8

container iniciado

<img width="734" height="407" alt="02-container-mysql" src="https://github.com/user-attachments/assets/7f514bcb-79d3-4d47-b2f9-05a97bfc3daa" />

## ETAPA 3 — Criar tabela

entrar:
docker exec -it mysql-server mysql -u root -p

senha:
123456

dentro do sql: 
USE empresa;

CREATE TABLE usuarios (
 id INT AUTO_INCREMENT PRIMARY KEY,
 nome VARCHAR(100),
 email VARCHAR(100)
);

tabela criada

<img width="784" height="539" alt="03-tabela-criada" src="https://github.com/user-attachments/assets/f60be521-46df-410e-9077-cbfaf63fccfa" />

## ETAPA 4 e ETAPA 5 — Inserir e Validar registros

INSERT INTO usuarios(nome,email)
VALUES
('Carlos','carlos@gmail.com'),
('Ana','ana@gmail.com'),
('Marcos','marcos@gmail.com');

SELECT * FROM usuarios;


<img width="981" height="766" alt="04-registros" src="https://github.com/user-attachments/assets/128a1999-b566-4eb9-8756-cbf7f7e8d9bc" />

## ETAPA 6 — Remover container

docker rm -f mysql-server

<img width="993" height="486" alt="05-container-removido" src="https://github.com/user-attachments/assets/e924fc17-9efc-4922-bd76-af2addd8bfae" />

## ETAPA 7 e ETAPA 8 - Recriar container e Validar persistência

docker run -d \
--name mysql-server2 \
-e MYSQL_ROOT_PASSWORD=123456 \
-v mysql-prod-data:/var/lib/mysql \
-p 3306:3306 \
mysql:8

docker exec -it mysql-server2 mysql -u root -p

USE empresa;
SELECT * FROM usuarios;

<img width="1200" height="723" alt="06-recriaçao do container e persistencia-validada" src="https://github.com/user-attachments/assets/7e61ae97-8cac-4e4f-abba-a1da4d15ae6c" />


### Análise Técnica

O Named Volume `mysql-prod-data` é armazenado em `/var/lib/docker/volumes/` 
no host, fora do ciclo de vida do container. Ao remover o container com 
`docker rm -f`, apenas o container é destruído — o volume permanece intacto. 
Ao recriar um novo container apontando para o mesmo volume, o MySQL encontra 
os arquivos de dados existentes e retoma o estado anterior, confirmando a persistência.
