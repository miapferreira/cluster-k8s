#!/bin/bash

# Script de deploy do Cluster Kubernetes na AWS
# Este script automatiza todo o processo de criação

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging colorido
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar pré-requisitos
check_prerequisites() {
    log_info "🔍 Verificando pré-requisitos..."
    
    # Verificar se Terraform está instalado
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform não está instalado. Instale o Terraform primeiro."
        exit 1
    fi
    
    # Verificar se AWS CLI está configurado
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI não está configurado. Configure suas credenciais AWS primeiro."
        exit 1
    fi
    
    # Verificar se a chave SSH existe
    if [ ! -f "ssh/k8s-key.pub" ]; then
        log_warning "Chave SSH não encontrada. Gerando nova chave..."
        ./ssh/generate_key.sh
    fi
    
    log_success "Pré-requisitos verificados!"
}

# Deploy da infraestrutura
deploy_infrastructure() {
    log_info "🏗️ Iniciando deploy da infraestrutura..."
    
    # Inicializar Terraform
    log_info "📦 Inicializando Terraform..."
    terraform init
    
    # Verificar plano
    log_info "📋 Verificando plano de execução..."
    terraform plan
    
    # Confirmar deploy
    echo
    read -p "🤔 Deseja prosseguir com o deploy? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Deploy cancelado pelo usuário."
        exit 0
    fi
    
    # Aplicar configuração
    log_info "🚀 Aplicando configuração..."
    terraform apply -auto-approve
    
    log_success "Infraestrutura criada com sucesso!"
}

# Mostrar informações do cluster
show_cluster_info() {
    log_info "📊 Informações do cluster:"
    
    # Aguardar um pouco para as instâncias inicializarem
    log_info "⏳ Aguardando inicialização das instâncias..."
    sleep 30
    
    # Mostrar outputs
    echo
    log_info "🔍 Outputs do Terraform:"
    terraform output
    
    echo
    log_info "📋 Próximos passos:"
    echo "1. Conecte no control plane:"
    echo "   ssh -i ssh/k8s-key ubuntu@$(terraform output -raw control_plane_public_ip)"
    echo
    echo "2. Verifique o status do cluster:"
    echo "   kubectl get nodes"
    echo
    echo "3. Para adicionar worker nodes, execute no control plane:"
    echo "   ./generate-join-command.sh"
    echo
    echo "4. Copie o comando gerado e execute em cada worker node:"
    echo "   ./join-cluster.sh \"<COMANDO_DE_JOIN>\""
}

# Função principal
main() {
    echo "🚀 Deploy do Cluster Kubernetes na AWS"
    echo "======================================"
    echo
    
    check_prerequisites
    deploy_infrastructure
    show_cluster_info
    
    log_success "✅ Deploy concluído com sucesso!"
    echo
    log_info "📚 Para mais informações, consulte o README.md"
}

# Executar função principal
main "$@"
