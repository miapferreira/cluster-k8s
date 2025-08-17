#!/bin/bash

# Script de configuração dos Worker Nodes do Kubernetes
# Baseado na documentação fornecida

set -e

CLUSTER_NAME="${cluster_name}"
WORKER_ID="${worker_id}"
LOG_FILE="/var/log/k8s-worker-setup.log"

# Função para logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Worker-$WORKER_ID: $1" | tee -a $LOG_FILE
}

log "🚀 Iniciando configuração do Worker Node $WORKER_ID..."

# 1. Carregar Módulos do Kernel
log "📦 Carregando módulos do kernel..."
cat > /etc/modules-load.d/k8s.conf << EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# 2. Configurar Parâmetros do Sistema
log "⚙️ Configurando parâmetros do sistema..."
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# 3. Instalar Container Runtime (containerd)
log "🐳 Instalando containerd..."
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Adicionar repositório Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar containerd
apt-get update
apt-get install -y containerd.io

# Configurar containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Reiniciar e habilitar containerd
systemctl restart containerd
systemctl enable containerd

# 4. Instalar Pacotes do Kubernetes
log "☸️ Instalando pacotes do Kubernetes..."
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg

# Adicionar repositório Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | apt-key add -
echo 'deb https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# Instalar componentes
apt-get update
apt-get install -y kubelet kubeadm kubectl

# Impedir atualizações automáticas
apt-mark hold kubelet kubeadm kubectl

# Habilitar kubelet
systemctl enable --now kubelet

# 5. Configurar alias úteis
log "🔧 Configurando aliases úteis..."
cat >> /home/ubuntu/.bashrc << 'EOF'

# Kubernetes aliases
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kdn='kubectl describe node'
alias klogs='kubectl logs'

# Cluster info
alias kcluster='kubectl cluster-info'
alias knodes='kubectl get nodes -o wide'
alias kpods='kubectl get pods -A'
EOF

chown ubuntu:ubuntu /home/ubuntu/.bashrc

# 6. Criar script para join no cluster
log "📝 Criando script para join no cluster..."
cat > /home/ubuntu/join-cluster.sh << 'EOF'
#!/bin/bash
# Script para fazer join no cluster
# Execute este script após obter o comando de join do control plane
# Exemplo: ./join-cluster.sh "kubeadm join 172.31.91.34:6443 --token 3vrkwi.kve7m3y3c8zawxvq --discovery-token-ca-cert-hash sha256:84378d3208d3bed7f3bd1be723fa4592679e9e9443f8a8a03c9f05726464dcfd"

if [ $# -eq 0 ]; then
    echo "❌ Erro: Forneça o comando de join como parâmetro"
    echo "💡 Exemplo: ./join-cluster.sh \"kubeadm join 172.31.91.34:6443 --token xxx --discovery-token-ca-cert-hash sha256:xxx\""
    exit 1
fi

echo "🔗 Fazendo join no cluster Kubernetes..."
echo "Comando: $1"
eval $1

if [ $? -eq 0 ]; then
    echo "✅ Worker node adicionado ao cluster com sucesso!"
    echo "📊 Para verificar status, conecte no control plane e execute: kubectl get nodes"
else
    echo "❌ Erro ao fazer join no cluster"
    exit 1
fi
EOF

chmod +x /home/ubuntu/join-cluster.sh
chown ubuntu:ubuntu /home/ubuntu/join-cluster.sh

# 7. Criar arquivo de instruções
log "📋 Criando arquivo de instruções..."
cat > /home/ubuntu/INSTRUCTIONS.md << EOF
# Worker Node $WORKER_ID - Instruções

## Para fazer join no cluster:

1. Conecte no control plane:
   \`\`\`bash
   ssh -i k8s-key.pem ubuntu@<IP_DO_CONTROL_PLANE>
   \`\`\`

2. Gere o comando de join:
   \`\`\`bash
   ./generate-join-command.sh
   \`\`\`

3. Copie o comando gerado e execute neste worker node:
   \`\`\`bash
   ./join-cluster.sh "<COMANDO_DE_JOIN>"
   \`\`\`

## Verificar status:
- No control plane: \`kubectl get nodes\`
- Neste worker: \`kubectl get nodes\` (após configurar kubeconfig)

## Logs de configuração:
- \`tail -f /var/log/k8s-worker-setup.log\`
EOF

chown ubuntu:ubuntu /home/ubuntu/INSTRUCTIONS.md

log "✅ Configuração do Worker Node $WORKER_ID concluída!"
log "📋 Instruções disponíveis em: /home/ubuntu/INSTRUCTIONS.md"
log "🔗 Para fazer join: ./join-cluster.sh \"<COMANDO_DE_JOIN>\""
