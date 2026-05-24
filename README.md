# Infra Persistência Docker

## Introdução

Esta atividade demonstra persistência de dados em containers Docker utilizando volumes, bind mounts, backup e automação.

## Ambiente Utilizado

- Ubuntu Linux
- Docker Engine
- Docker Compose
- Git
- GitHub

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
