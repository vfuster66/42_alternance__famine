#!/bin/bash
# =============================================================================
# Script de test simple pour le déclenchement conditionnel de Famine
# =============================================================================

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info "Test simple du déclenchement conditionnel de Famine"

# Vérifier que Famine est compilé
if [ ! -f "./Famine" ]; then
    print_error "Famine non trouvé. Compilation nécessaire."
    make clean && make all
fi

# Créer l'environnement de test
print_info "Création de l'environnement de test..."
mkdir -p /tmp/test /tmp/test2

# Créer un binaire de test
print_info "Création du binaire de test..."
cat > /tmp/test/sample.c << 'EOF'
#include <stdio.h>
int main() { printf("Hello from test binary!\n"); return 0; }
EOF

gcc -m64 -static -o /tmp/test/sample /tmp/test/sample.c

print_info "Vérification avant infection..."
echo "Signatures trouvées avant infection:"
strings /tmp/test/sample | grep -i famine || echo "  → Aucune signature Famine"

# Test 1: Sans FAMINE_FORCE
print_info "Test 1: Exécution sans FAMINE_FORCE..."
unset FAMINE_FORCE
./Famine

echo "Signatures trouvées après test 1:"
strings /tmp/test/sample | grep -i famine || echo "  → Aucune signature Famine"

if strings /tmp/test/sample | grep -q "Famine version 1.0"; then
    print_success "Infection détectée (condition remplie)"
    INFECTED_NORMAL=1
else
    print_info "Pas d'infection (condition non remplie)"
    INFECTED_NORMAL=0
fi

# Restaurer le binaire
print_info "Restauration du binaire..."
gcc -m64 -static -o /tmp/test/sample /tmp/test/sample.c

# Test 2: Avec fichier de force
print_info "Test 2: Exécution avec fichier de force..."
touch /tmp/famine_force
./Famine

echo "Signatures trouvées après test 2:"
strings /tmp/test/sample | grep -i famine || echo "  → Aucune signature Famine"

if strings /tmp/test/sample | grep -q "Famine version 1.0"; then
    print_success "Infection forcée détectée"
    INFECTED_FORCE=1
else
    print_error "Pas d'infection malgré fichier de force"
    INFECTED_FORCE=0
fi

# Résumé
print_info "Résumé des tests:"
print_info "  - Condition normale: $INFECTED_NORMAL"
print_info "  - FAMINE_FORCE=1: $INFECTED_FORCE"

if [ "$INFECTED_FORCE" -eq 1 ]; then
    print_success "✓ FAMINE_FORCE=1 fonctionne correctement"
else
    print_error "✗ FAMINE_FORCE=1 ne fonctionne pas"
fi

# Nettoyage
print_info "Nettoyage..."
rm -f /tmp/test/sample.c /tmp/test/sample
rm -f /tmp/famine_force

print_success "Test simple terminé !"
