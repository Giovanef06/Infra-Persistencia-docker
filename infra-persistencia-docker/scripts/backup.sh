#!/bin/bash

# ============================================
# Script de Backup Automatizado - MySQL Docker
# ============================================

CONTAINER="mysql-server2"
BANCO="empresa"
USUARIO="root"
SENHA="senha123"
DIR_BACKUP="$(pwd)/backups"
DATA=$(date +"%Y%m%d_%H%M%S")
ARQUIVO_SQL="$DIR_BACKUP/backup_${DATA}.sql"
ARQUIVO_GZ="$DIR_BACKUP/backup_${DATA}.tar.gz"

echo "======================================"
echo "Iniciando backup: $(date)"
echo "======================================"

# Verifica se o container está rodando
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERRO: container '$CONTAINER' não está rodando."
  exit 1
fi

# Cria diretório de backup se não existir
mkdir -p "$DIR_BACKUP"

# Gera dump SQL
echo "[1/3] Gerando dump SQL..."
docker exec "$CONTAINER" mysqldump -u"$USUARIO" -p"$SENHA" "$BANCO" > "$ARQUIVO_SQL"

# Comprime o dump
echo "[2/3] Comprimindo arquivo..."
tar czf "$ARQUIVO_GZ" -C "$DIR_BACKUP" "$(basename $ARQUIVO_SQL)"
rm "$ARQUIVO_SQL"

# Resultado
echo "[3/3] Backup concluído!"
echo "Arquivo gerado: $ARQUIVO_GZ"
echo "Tamanho: $(du -h $ARQUIVO_GZ | cut -f1)"
echo "======================================"
