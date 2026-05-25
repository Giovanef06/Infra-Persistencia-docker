#!/bin/bash

# ============================================
# Script de Restauração - MySQL Docker
# ============================================

CONTAINER="mysql-prod"
BANCO="empresa"
USUARIO="root"
SENHA="senha123"
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
