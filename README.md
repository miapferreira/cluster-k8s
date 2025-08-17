# Cluster Kubernetes na AWS com Terraform

Este projeto cria um cluster Kubernetes na AWS com 1 control-plane e 3 worker nodes usando Terraform.

## Arquitetura

- **1 Control Plane**: t2.medium (mínimo recomendado)
- **3 Worker Nodes**: t2.medium cada
- **VPC**: 10.0.0.0/16
- **AMI**: Ubuntu 24.04 LTS
- **CNI**: Weave Net

## Pré-requisitos

- Terraform >= 1.0
- AWS CLI configurado
- Acesso à AWS com permissões para criar recursos

## Como usar

### Opção 1: Deploy Automatizado (Recomendado)

1. Clone este repositório
2. Configure suas credenciais AWS
3. Execute o script de deploy:

```bash
./deploy.sh
```

### Opção 2: Deploy Manual

1. Clone este repositório
2. Configure suas credenciais AWS
3. Gere a chave SSH:
```bash
./ssh/generate_key.sh
```
4. Execute os comandos Terraform:
```bash
terraform init
terraform plan
terraform apply
```

## Estrutura do Projeto

- `main.tf` - Configuração principal e providers
- `variables.tf` - Variáveis do projeto
- `outputs.tf` - Outputs do projeto
- `network.tf` - Recursos de rede (VPC, subnets, etc.)
- `security-group.tf` - Security groups e key pair
- `instances.tf` - Instâncias EC2
- `scripts/` - Scripts de automação
  - `control_plane_setup.sh` - Configuração automática do control plane
  - `worker_setup.sh` - Configuração automática dos worker nodes
- `ssh/` - Chaves SSH
  - `generate_key.sh` - Script para gerar chave SSH
- `deploy.sh` - Script de deploy automatizado
- `PARAMETRIZACAO.md` - Documentação detalhada da parametrização

## Próximos Passos

Após a criação da infraestrutura:

### 1. Verificar Status do Cluster
```bash
# Conectar no control plane
ssh -i ssh/k8s-key ubuntu@<IP_DO_CONTROL_PLANE>

# Verificar status dos nós
kubectl get nodes

# Verificar pods do sistema
kubectl get pods -n kube-system
```

### 2. Adicionar Worker Nodes
```bash
# No control plane, gerar comando de join
./generate-join-command.sh

# Em cada worker node, executar o comando gerado
./join-cluster.sh "<COMANDO_DE_JOIN>"
```

### 3. Verificar Cluster Completo
```bash
# Verificar todos os nós
kubectl get nodes -o wide

# Verificar informações do cluster
kubectl cluster-info

# Testar deploy de aplicação
kubectl run nginx --image=nginx --port=80
kubectl get pods
```

## Segurança

- Security groups configurados apenas com as portas necessárias
- Key pair para acesso SSH
- Instâncias em subnets privadas (exceto control plane)
