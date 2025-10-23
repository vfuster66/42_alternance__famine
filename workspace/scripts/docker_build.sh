#!/bin/bash
# =============================================================================
# Script pour compiler et tester Famine dans Docker
# =============================================================================

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_header "Compilation et test de Famine dans Docker"

# Vérifier si Docker est disponible
if ! command -v docker >/dev/null 2>&1; then
    print_info "Docker non disponible. Utilisation d'une VM Linux recommandée."
    exit 1
fi

# Créer un conteneur temporaire pour la compilation
print_info "Création du conteneur de compilation..."
CONTAINER_NAME="famine-build-$(date +%s)"

docker run -d --name "$CONTAINER_NAME" \
    -v "$(pwd):/workspace" \
    ubuntu:20.04 \
    sleep 300

# Installer les dépendances
print_info "Installation des dépendances..."
docker exec "$CONTAINER_NAME" bash -c "
    apt-get update && \
    apt-get install -y nasm gcc make && \
    echo 'Dépendances installées'
"

# Compiler le projet
print_info "Compilation du projet..."
docker exec -w /workspace "$CONTAINER_NAME" make clean
docker exec -w /workspace "$CONTAINER_NAME" make all

# Vérifier la compilation
if docker exec "$CONTAINER_NAME" test -f /workspace/Famine; then
    print_success "Compilation réussie !"
else
    print_info "Erreur de compilation"
    docker exec -w /workspace "$CONTAINER_NAME" make all
fi

# Tester le déclenchement conditionnel
print_info "Test du déclenchement conditionnel..."
docker exec -w /workspace "$CONTAINER_NAME" make test-condition-debug

# Nettoyer le conteneur
print_info "Nettoyage du conteneur..."
docker stop "$CONTAINER_NAME" >/dev/null 2>&1
docker rm "$CONTAINER_NAME" >/dev/null 2>&1

print_success "Tests terminés dans Docker !"
