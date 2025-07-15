#!/bin/bash

SECRETS_FILE="secrets.txt"

if [ ! -f "$SECRETS_FILE" ]; then
  echo "Fichier $SECRETS_FILE introuvable."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Utilisation : $0 <NomDuService> ou 'all' pour tous"
  exit 1
fi

if [ "$1" == "all" ]; then
  grep -o 'otpauth://[^ ]*' "$SECRETS_FILE" | while read -r line; do
    NAME=$(echo "$line" | cut -d ':' -f 3 | cut -d '?' -f 1)
    SECRET=$(echo "$line" | grep -o 'secret=[^&]*' | cut -d= -f2)
    CODE=$(oathtool --totp -b "$SECRET")
    echo "$NAME: $CODE"
  done
else
  MATCHES=$(grep -i "$1" "$SECRETS_FILE" | grep -o 'otpauth://[^ ]*')
  if [ -z "$MATCHES" ]; then
    echo "Aucun secret trouvé pour $1"
    exit 1
  fi

  echo "$MATCHES" | while read -r line; do
    NAME=$(echo "$line" | cut -d ':' -f 3 | cut -d '?' -f 1)
    SECRET=$(echo "$line" | grep -o 'secret=[^&]*' | cut -d= -f2)
    CODE=$(oathtool --totp -b "$SECRET")
    echo "$NAME: $CODE"
  done
fi
