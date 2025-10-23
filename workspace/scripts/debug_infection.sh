#!/bin/bash

# =============================================================================
# Script de diagnostic pour l'infection ELF64
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

print_header "Diagnostic de l'infection ELF64"

# Vérifier que Famine est compilé
if [ ! -f "./Famine" ]; then
    print_error "Famine non trouvé. Compilation nécessaire."
    make clean && make all
fi

# Créer l'environnement de test
print_info "Création de l'environnement de test..."
mkdir -p /tmp/test_elf64_debug
mkdir -p /tmp/test

# Créer un programme de test simple
print_info "Création du programme de test..."
cat > /tmp/test_elf64_debug/sample64.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from ELF64 debug!\n");
    return 0;
}
EOF

# Compiler le programme
print_info "Compilation du programme..."
if command -v docker >/dev/null 2>&1; then
    # Utiliser Docker pour la compilation
    docker run --rm -v "$(pwd):/workspace" -w /workspace ubuntu:20.04 bash -c "
        apt-get update >/dev/null 2>&1
        apt-get install -y gcc >/dev/null 2>&1
        gcc -m64 -static -o /tmp/test_elf64_debug/sample64 /tmp/test_elf64_debug/sample64.c
    "
    print_success "Programme compilé avec Docker"
else
    # Essayer la compilation native
    gcc -m64 -static -o /tmp/test_elf64_debug/sample64 /tmp/test_elf64_debug/sample64.c 2>/dev/null || {
        print_error "Compilation native échouée, Docker requis"
        exit 1
    }
    print_success "Programme compilé"
fi

# Vérifier le format
print_info "Vérification du format ELF64..."
readelf -h /tmp/test_elf64_debug/sample64 | grep "Class:.*ELF64" && print_success "Format ELF64 confirmé" || print_error "Format ELF64 incorrect"

# Tester l'exécution avant infection
print_info "Test d'exécution avant infection..."
/tmp/test_elf64_debug/sample64 && print_success "Exécution réussie" || print_error "Échec d'exécution"

# Vérifier qu'il n'est pas encore infecté
print_info "Vérification avant infection..."
if strings /tmp/test_elf64_debug/sample64 | grep -q "Famine"; then
    print_error "Le binaire est déjà infecté avant le test !"
else
    print_success "Binaire propre avant infection"
fi

# Copier vers /tmp/test pour Famine
print_info "Copie vers /tmp/test pour Famine..."
cp /tmp/test_elf64_debug/sample64 /tmp/test/

# Exécuter Famine
print_info "Exécution de Famine..."
echo "=== Sortie de Famine ==="
./Famine
echo "=== Fin de la sortie de Famine ==="

# Vérifier l'infection
print_info "Vérification de l'infection..."
echo "=== Contenu du binaire après infection ==="
strings /tmp/test/sample64 | grep -i famine || echo "Aucune signature Famine trouvée"

echo ""
echo "=== Toutes les chaînes dans le binaire ==="
strings /tmp/test/sample64 | head -20

echo ""
echo "=== Recherche de la signature complète ==="
if strings /tmp/test/sample64 | grep -q "Famine version 1.0"; then
    print_success "Signature complète trouvée !"
    strings /tmp/test/sample64 | grep "Famine version 1.0"
else
    print_error "Signature complète non trouvée"
fi

# Copier le résultat pour analyse
cp /tmp/test/sample64 /tmp/test_elf64_debug/sample64_infected

# Tester l'exécution après infection
print_info "Test d'exécution après infection..."
/tmp/test_elf64_debug/sample64_infected && print_success "Exécution post-infection réussie" || print_error "Échec d'exécution post-infection"

# Comparer les tailles
print_info "Comparaison des tailles..."
echo "Binaire original: $(stat -c%s /tmp/test_elf64_debug/sample64) octets"
echo "Binaire infecté: $(stat -c%s /tmp/test_elf64_debug/sample64_infected) octets"

# Analyse hexadécimale de la fin du fichier
print_info "Analyse hexadécimale de la fin du fichier infecté..."
tail -c 100 /tmp/test_elf64_debug/sample64_infected | hexdump -C

print_header "Diagnostic terminé"
