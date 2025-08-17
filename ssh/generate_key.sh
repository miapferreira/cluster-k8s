#!/bin/bash

# Script para gerar chave SSH para o cluster Kubernetes
# Execute este script antes de rodar o terraform

KEY_NAME="k8s-key"
SSH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Gerando chave SSH para o cluster Kubernetes..."
echo "Diretório: $SSH_DIR"

# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/$KEY_NAME" -N "" -C "kubernetes-cluster"

# Ajustar permissões
chmod 600 "$SSH_DIR/$KEY_NAME"
chmod 644 "$SSH_DIR/$KEY_NAME.pub"

echo "✅ Chave SSH gerada com sucesso!"
echo "📁 Chave privada: $SSH_DIR/$KEY_NAME"
echo "📁 Chave pública: $SSH_DIR/$KEY_NAME.pub"
echo ""
echo "⚠️  IMPORTANTE: Mantenha a chave privada segura!"
echo "🔑 Para conectar via SSH: ssh -i $SSH_DIR/$KEY_NAME ubuntu@<IP_DO_CONTROL_PLANE>"
