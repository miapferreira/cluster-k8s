#!/bin/bash

# Script de configuração do Control Plane do Kubernetes
# Baseado na documentação fornecida

set -e

CLUSTER_NAME="${cluster_name}"
LOG_FILE="/var/log/k8s-setup.log"

# Função para logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log "🚀 Iniciando configuração do Control Plane do Kubernetes..."

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

# 5. Inicializar o Cluster
log "🎯 Inicializando cluster Kubernetes..."
# Obter IP privado da instância
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=$PRIVATE_IP

# 6. Configurar kubectl para usuário ubuntu
log "🔧 Configurando kubectl..."
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# 7. Instalar CNI (Weave Net)
log "🌐 Instalando Weave Net CNI..."
su - ubuntu -c "kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml"

# 8. Criar script para gerar token de join
log "📝 Criando script para gerar token de join..."
cat > /home/ubuntu/generate-join-command.sh << 'EOF'
#!/bin/bash
# Script para gerar comando de join para worker nodes
kubeadm token create --print-join-command
EOF

chmod +x /home/ubuntu/generate-join-command.sh
chown ubuntu:ubuntu /home/ubuntu/generate-join-command.sh

# 9. Configurar alias úteis
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

log "✅ Configuração do Control Plane concluída!"
log "🔑 Para conectar: ssh -i k8s-key.pem ubuntu@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
log "📋 Para gerar comando de join: ./generate-join-command.sh"
log "📊 Para verificar status: kubectl get nodes"
