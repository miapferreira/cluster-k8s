# Parametrização das Instâncias - Implementação

Este documento mostra como cada parte da sua documentação foi implementada nos scripts de automação.

## 📋 Resumo da Implementação

Todas as etapas da sua documentação foram implementadas automaticamente nos scripts `control_plane_setup.sh` e `worker_setup.sh`, que são executados via `user_data` das instâncias EC2.

## 🔧 Etapas Implementadas

### 1. Carregar Módulos do Kernel ✅
**Arquivo:** `scripts/control_plane_setup.sh` (linhas 18-25)
```bash
# 1. Carregar Módulos do Kernel
log "📦 Carregando módulos do kernel..."
cat > /etc/modules-load.d/k8s.conf << EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
```

### 2. Configurar Parâmetros do Sistema ✅
**Arquivo:** `scripts/control_plane_setup.sh` (linhas 27-35)
```bash
# 2. Configurar Parâmetros do Sistema
log "⚙️ Configurando parâmetros do sistema..."
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
```

### 3. Instalar Container Runtime (containerd) ✅
**Arquivo:** `scripts/control_plane_setup.sh` (linhas 37-55)
```bash
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
```

### 4. Instalar Pacotes do Kubernetes ✅
**Arquivo:** `scripts/control_plane_setup.sh` (linhas 57-75)
```bash
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
```

### 5. Inicializar o Cluster ✅
**Arquivo:** `scripts/control_plane_setup.sh` (linhas 77-82)
```bash
# 5. Inicializar o Cluster
log "🎯 Inicializando cluster Kubernetes..."
# Obter IP privado da instância
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=$PRIVATE_IP
```

### 6. Configurar kubectl ✅
**Arquivo:** `scripts/control_plane_setup.sh` (linhas 84-88)
```bash
# 6. Configurar kubectl para usuário ubuntu
log "🔧 Configurando kubectl..."
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
```

### 7. Instalar CNI (Weave Net) ✅
**Arquivo:** `scripts/control_plane_setup.sh` (linhas 90-92)
```bash
# 7. Instalar CNI (Weave Net)
log "🌐 Instalando Weave Net CNI..."
su - ubuntu -c "kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml"
```

## 🔄 Como Funciona

### Execução Automática
1. **User Data**: Os scripts são executados automaticamente quando as instâncias iniciam
2. **Base64**: Os scripts são codificados em base64 no Terraform
3. **Template**: Variáveis são substituídas dinamicamente
4. **Logs**: Todas as operações são logadas em `/var/log/k8s-setup.log`

### Diferenças entre Control Plane e Workers

| Control Plane | Workers |
|---------------|---------|
| Executa `kubeadm init` | Não executa `kubeadm init` |
| Instala Weave Net | Não instala CNI |
| Cria script de join | Cria script para fazer join |
| Configura kubectl | Não configura kubectl |

## 📊 Logs e Monitoramento

### Logs Disponíveis
- **Control Plane**: `/var/log/k8s-setup.log`
- **Workers**: `/var/log/k8s-worker-setup.log`

### Verificar Status
```bash
# Verificar logs de configuração
tail -f /var/log/k8s-setup.log

# Verificar status do cluster
kubectl get nodes

# Verificar pods do sistema
kubectl get pods -n kube-system
```

## 🛠️ Personalização

### Modificar Scripts
Para personalizar a configuração, edite os arquivos:
- `scripts/control_plane_setup.sh`
- `scripts/worker_setup.sh`

### Adicionar Configurações
Exemplos de personalizações possíveis:
- Instalar ferramentas adicionais
- Configurar monitoramento
- Ajustar parâmetros do sistema
- Instalar CNI diferente

## ✅ Vantagens da Automação

1. **Consistência**: Todas as instâncias são configuradas igualmente
2. **Velocidade**: Configuração automática em minutos
3. **Reprodutibilidade**: Mesmo resultado sempre
4. **Documentação**: Scripts servem como documentação viva
5. **Manutenção**: Fácil de atualizar e versionar
