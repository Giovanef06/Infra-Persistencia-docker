# Problemas Encontrados e Soluções

## Problema 1 — Container com nome errado no script
**Erro:** `ERRO: container 'mysql-prod' não está rodando`  
**Causa:** O script usava o nome `mysql-prod` mas o container foi criado como `mysql-server2`  
**Solução:** Alterar a variável `CONTAINER="mysql-prod"` para `CONTAINER="mysql-server2"` no `backup.sh`

## Problema 2 — Banco 'empresa' não criado automaticamente
**Erro:** `ERROR 1049 (42000): Unknown database 'empresa'`  
**Causa:** O volume já tinha dados antigos do MySQL, então a variável `MYSQL_DATABASE` foi ignorada na recriação do container  
**Solução:** Criar o banco manualmente com `CREATE DATABASE empresa;` antes de restaurar o dump

## Problema 3 — Permissão negada no Docker sem sudo
**Erro:** `permission denied while trying to connect to the Docker daemon socket`  
**Causa:** Usuário não está no grupo docker  
**Solução:** Utilizar `sudo` antes dos comandos docker

## Problema 4 — Push rejeitado pelo GitHub
**Erro:** `rejected - fetch first`  
**Causa:** O README foi editado direto no GitHub, deixando o repositório remoto à frente do local  
**Solução:** Executar `git pull origin main --rebase` antes do push

## Problema 5 — tar.gz não gerado na primeira tentativa
**Erro:** `Cannot open: No such file or directory`  
**Causa:** O caminho do arquivo de backup estava incorreto  
**Solução:** Verificar o diretório atual com `pwd` e garantir que a pasta `backups/` existe antes de executar o comando
