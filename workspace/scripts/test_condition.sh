#!/bin/bash
# =============================================================================
# Script de test pour le déclenchement conditionnel de Famine
# =============================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions d'affichage
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Variables
FAMINE_BINARY="./Famine"
TEST_DIR="/tmp/test_condition"
DOCKER_CONTAINER="famine-test"

print_header "Test du déclenchement conditionnel de Famine"

# Vérifier que Famine est compilé
if [ ! -f "$FAMINE_BINARY" ]; then
    print_error "Famine non trouvé. Compilation nécessaire."
    print_info "Exécution de: make clean && make all"
    make clean && make all
fi

# Créer le répertoire de test
print_info "Création du répertoire de test..."
mkdir -p "$TEST_DIR"
mkdir -p /tmp/test /tmp/test2

# Créer des binaires de test
print_info "Création des binaires de test..."
cat > /tmp/test/sample.c << 'EOF'
#include <stdio.h>
int main() { printf("Hello from test binary!\n"); return 0; }
EOF

gcc -m64 -static -o /tmp/test/sample /tmp/test/sample.c
cp /bin/ls /tmp/test2/ls 2>/dev/null || true

print_success "Binaires de test créés"

# =============================================================================
# TEST 1: Condition normale (sans FAMINE_FORCE)
# =============================================================================
print_header "Test 1: Condition normale (sans FAMINE_FORCE)"

print_info "Vérification avant infection..."
echo "Signatures trouvées avant infection:"
strings /tmp/test/sample | grep -i famine || echo "  → Aucune signature Famine"

print_info "Exécution de Famine sans FAMINE_FORCE..."
unset FAMINE_FORCE
timeout 5s "$FAMINE_BINARY" > /tmp/famine_output1.txt 2>&1 || true

print_info "Vérification après infection (condition normale)..."
echo "Signatures trouvées après test 1:"
strings /tmp/test/sample | grep -i famine || echo "  → Aucune signature Famine"

if strings /tmp/test/sample | grep -q "Famine version 1.0"; then
    print_success "Infection détectée (condition remplie)"
    INFECTED_NORMAL=1
else
    print_info "Pas d'infection (condition non remplie)"
    INFECTED_NORMAL=0
fi

# =============================================================================
# TEST 2: Force avec fichier de force
# =============================================================================
print_header "Test 2: Force avec fichier de force"

# Restaurer les binaires propres
print_info "Restauration des binaires propres..."
gcc -m64 -static -o /tmp/test/sample /tmp/test/sample.c
cp /bin/ls /tmp/test2/ls 2>/dev/null || true

print_info "Vérification avant infection..."
echo "Signatures trouvées avant infection:"
strings /tmp/test/sample | grep -i famine || echo "  → Aucune signature Famine"

print_info "Exécution de Famine avec fichier de force..."
touch /tmp/famine_force
timeout 5s "$FAMINE_BINARY" > /tmp/famine_output2.txt 2>&1 || true

print_info "Vérification après infection (fichier de force)..."
echo "Signatures trouvées après test 2:"
strings /tmp/test/sample | grep -i famine || echo "  → Aucune signature Famine"

if strings /tmp/test/sample | grep -q "Famine version 1.0"; then
    print_success "Infection détectée (fichier de force)"
    INFECTED_FORCE=1
else
    print_error "Pas d'infection malgré fichier de force"
    INFECTED_FORCE=0
fi

# =============================================================================
# TEST 3: Test avec Docker (simulation d'environnement différent)
# =============================================================================
print_header "Test 3: Test avec Docker"

# Vérifier si Docker est disponible
if command -v docker >/dev/null 2>&1; then
    print_info "Docker disponible, test avec conteneur..."
    
    # Créer un conteneur de test
    print_info "Création du conteneur de test..."
    docker run -d --name "$DOCKER_CONTAINER" ubuntu:20.04 sleep 300 2>/dev/null || true
    
    # Copier Famine dans le conteneur
    print_info "Copie de Famine dans le conteneur..."
    docker cp "$FAMINE_BINARY" "$DOCKER_CONTAINER:/famine" 2>/dev/null || true
    
    # Créer l'environnement de test dans le conteneur
    print_info "Préparation de l'environnement dans le conteneur..."
    docker exec "$DOCKER_CONTAINER" mkdir -p /tmp/test /tmp/test2 2>/dev/null || true
    
    # Créer un binaire de test dans le conteneur
    print_info "Création du binaire de test dans le conteneur..."
    docker exec "$DOCKER_CONTAINER" bash -c 'echo "int main(){printf(\"Hello from container!\\n\");return 0;}" > /tmp/test/sample.c' 2>/dev/null || true
    docker exec "$DOCKER_CONTAINER" gcc -m64 -static -o /tmp/test/sample /tmp/test/sample.c 2>/dev/null || true
    
    # Test sans FAMINE_FORCE dans le conteneur
    print_info "Test sans FAMINE_FORCE dans le conteneur..."
    docker exec "$DOCKER_CONTAINER" /famine 2>/dev/null || true
    
    # Vérifier l'infection dans le conteneur
    print_info "Vérification de l'infection dans le conteneur..."
    if docker exec "$DOCKER_CONTAINER" strings /tmp/test/sample | grep -q "Famine version 1.0"; then
        print_success "Infection détectée dans le conteneur"
        INFECTED_DOCKER=1
    else
        print_info "Pas d'infection dans le conteneur (condition non remplie)"
        INFECTED_DOCKER=0
    fi
    
    # Test avec fichier de force dans le conteneur
    print_info "Test avec fichier de force dans le conteneur..."
    docker exec "$DOCKER_CONTAINER" bash -c 'touch /tmp/famine_force && /famine' 2>/dev/null || true
    
    # Vérifier l'infection forcée dans le conteneur
    print_info "Vérification de l'infection forcée dans le conteneur..."
    if docker exec "$DOCKER_CONTAINER" strings /tmp/test/sample | grep -q "Famine version 1.0"; then
        print_success "Infection forcée détectée dans le conteneur"
        INFECTED_DOCKER_FORCE=1
    else
        print_error "Pas d'infection forcée dans le conteneur"
        INFECTED_DOCKER_FORCE=0
    fi
    
    # Nettoyer le conteneur
    print_info "Nettoyage du conteneur..."
    docker stop "$DOCKER_CONTAINER" 2>/dev/null || true
    docker rm "$DOCKER_CONTAINER" 2>/dev/null || true
    
else
    print_info "Docker non disponible, test Docker ignoré"
    INFECTED_DOCKER=0
    INFECTED_DOCKER_FORCE=0
fi

# =============================================================================
# RÉSUMÉ DES TESTS
# =============================================================================
print_header "Résumé des tests"

print_info "Résultats:"
print_info "  - Condition normale: $INFECTED_NORMAL"
print_info "  - FAMINE_FORCE=1: $INFECTED_FORCE"
print_info "  - Docker normal: $INFECTED_DOCKER"
print_info "  - Docker forcé: $INFECTED_DOCKER_FORCE"

# Vérifier que FAMINE_FORCE=1 fonctionne toujours
if [ "$INFECTED_FORCE" -eq 1 ]; then
    print_success "✓ FAMINE_FORCE=1 fonctionne correctement"
else
    print_error "✗ FAMINE_FORCE=1 ne fonctionne pas"
fi

# Vérifier que les conditions normales sont respectées
if [ "$INFECTED_NORMAL" -eq 0 ] && [ "$INFECTED_FORCE" -eq 1 ]; then
    print_success "✓ Conditions d'activation fonctionnent correctement"
elif [ "$INFECTED_NORMAL" -eq 1 ] && [ "$INFECTED_FORCE" -eq 1 ]; then
    print_info "ℹ Conditions d'activation remplies dans l'environnement actuel"
else
    print_error "✗ Problème avec les conditions d'activation"
fi

# Nettoyage
print_info "Nettoyage des fichiers temporaires..."
rm -f /tmp/famine_output1.txt /tmp/famine_output2.txt
rm -f /tmp/test/sample.c /tmp/test/sample
rm -f /tmp/test2/ls
rm -f /tmp/famine_force

print_header "Tests terminés"
print_success "Script de test du déclenchement conditionnel exécuté avec succès !"
