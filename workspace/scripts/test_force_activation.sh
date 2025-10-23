#!/bin/bash

# =============================================================================
# Script de test pour vérifier l'activation avec le fichier de force
# =============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_header "Test d'activation avec fichier de force"

# Vérifier que Famine est compilé
if [ ! -f "./Famine" ]; then
    print_error "Famine non trouvé. Compilation nécessaire."
    make clean && make all
fi

# Créer l'environnement de test
print_info "Création de l'environnement de test..."
mkdir -p /tmp/test_force
mkdir -p /tmp/test

# Créer un programme de test simple
print_info "Création du programme de test..."
cat > /tmp/test_force/sample.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from test!\n");
    return 0;
}
EOF

# Compiler le programme
print_info "Compilation du programme..."
gcc -m64 -static -o /tmp/test_force/sample /tmp/test_force/sample.c
print_success "Programme compilé"

# Vérifier qu'il n'est pas encore infecté
print_info "Vérification avant infection..."
if strings /tmp/test_force/sample | grep -q "Famine"; then
    print_error "Le binaire est déjà infecté avant le test !"
else
    print_success "Binaire propre avant infection"
fi

# Copier vers /tmp/test pour Famine
print_info "Copie vers /tmp/test pour Famine..."
cp /tmp/test_force/sample /tmp/test/

# Test 1: Sans fichier de force (ne devrait pas s'activer)
print_info "Test 1: Exécution SANS fichier de force..."
./Famine
if strings /tmp/test/sample | grep -q "Famine"; then
    print_error "Infection inattendue sans fichier de force !"
else
    print_success "Pas d'infection sans fichier de force (correct)"
fi

# Test 2: Avec fichier de force (devrait s'activer)
print_info "Test 2: Création du fichier de force..."
touch /tmp/famine_force
print_success "Fichier de force créé"

print_info "Test 2: Exécution AVEC fichier de force..."
./Famine

# Vérifier l'infection
print_info "Vérification de l'infection..."
if strings /tmp/test/sample | grep -q "Famine"; then
    print_success "Infection réussie avec fichier de force !"
    print_info "Signature trouvée:"
    strings /tmp/test/sample | grep "Famine"
else
    print_error "Infection échouée malgré le fichier de force"
fi

# Nettoyer
print_info "Nettoyage..."
rm -f /tmp/famine_force
rm -rf /tmp/test_force /tmp/test

print_header "Test terminé"
