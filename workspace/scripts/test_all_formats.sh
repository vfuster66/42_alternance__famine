#!/bin/bash

# =============================================================================
# Script de test complet pour Famine (ELF32 + ELF64)
# =============================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_bonus() {
    echo -e "${PURPLE}🎯 $1${NC}"
}

# Variables
TEST_DIR="/tmp/test_famine"
FAMINE_BINARY="./Famine"

print_header "Test complet de Famine (ELF32 + ELF64)"

# Vérifier que Famine est compilé
if [ ! -f "$FAMINE_BINARY" ]; then
    print_error "Famine non trouvé. Compilation nécessaire."
    print_info "Exécution de: make clean && make all"
    make clean && make all
fi

# Créer le répertoire de test
print_info "Création du répertoire de test..."
mkdir -p "$TEST_DIR"

# =============================================================================
# TEST ELF64
# =============================================================================
print_header "Test ELF64"

# Créer un programme C simple pour ELF64
print_info "Création du programme de test ELF64..."
cat > "$TEST_DIR/sample64.c" << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("Hello from ELF64!\n");
    printf("This is a 64-bit executable.\n");
    return 0;
}
EOF

# Compiler le programme en ELF64
print_info "Compilation du programme en ELF64..."
gcc -m64 -static -o "$TEST_DIR/sample64" "$TEST_DIR/sample64.c"
print_success "Compilation ELF64 réussie"

# Vérifier le format
print_info "Vérification du format ELF64..."
readelf -h "$TEST_DIR/sample64" | grep -q "Class:.*ELF64" && print_success "Binaire ELF64 confirmé" || print_error "Le binaire n'est pas ELF64"

# Tester l'exécution
print_info "Test d'exécution du binaire ELF64..."
timeout 5s "$TEST_DIR/sample64" > /tmp/elf64_output.txt 2>&1
if [ $? -eq 0 ]; then
    print_success "Exécution ELF64 réussie"
    cat /tmp/elf64_output.txt
else
    print_error "Échec de l'exécution ELF64"
fi

# =============================================================================
# TEST ELF32 (BONUS)
# =============================================================================
print_bonus "Test ELF32 (Bonus)"

# Créer un programme C simple pour ELF32
print_info "Création du programme de test ELF32..."
cat > "$TEST_DIR/sample32.c" << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("Hello from ELF32!\n");
    printf("This is a 32-bit executable.\n");
    return 0;
}
EOF

# Compiler le programme en ELF32
print_info "Compilation du programme en ELF32..."
if command -v gcc >/dev/null 2>&1; then
    gcc -m32 -static -o "$TEST_DIR/sample32" "$TEST_DIR/sample32.c"
    print_success "Compilation ELF32 réussie"
else
    print_error "gcc non trouvé. Installation de gcc-multilib nécessaire."
    exit 1
fi

# Vérifier le format ELF32
print_info "Vérification du format ELF32..."
readelf -h "$TEST_DIR/sample32" | grep -q "Class:.*ELF32" && print_success "Binaire ELF32 confirmé" || print_error "Le binaire n'est pas ELF32"

# Tester l'exécution ELF32
print_info "Test d'exécution du binaire ELF32..."
if command -v qemu-i386 >/dev/null 2>&1; then
    timeout 5s qemu-i386 "$TEST_DIR/sample32" > /tmp/elf32_output.txt 2>&1
    if [ $? -eq 0 ]; then
        print_success "Exécution ELF32 réussie avec qemu-i386"
        cat /tmp/elf32_output.txt
    else
        print_error "Échec de l'exécution ELF32 avec qemu-i386"
    fi
else
    print_info "qemu-i386 non disponible, test direct..."
    timeout 5s "$TEST_DIR/sample32" > /tmp/elf32_output.txt 2>&1 || true
    if [ -s /tmp/elf32_output.txt ]; then
        print_success "Exécution ELF32 réussie"
        cat /tmp/elf32_output.txt
    else
        print_info "Exécution directe ELF32 échouée (normal sur système 64-bit)"
    fi
fi

# =============================================================================
# TEST D'INFECTION
# =============================================================================
print_header "Test d'infection avec Famine"

# Créer le fichier de force pour l'activation
print_info "Création du fichier de force pour activation..."
touch /tmp/famine_force

# Exécuter Famine sur le répertoire de test
print_info "Exécution de Famine sur le répertoire de test..."
timeout 10s "$FAMINE_BINARY" "$TEST_DIR" > /tmp/famine_output.txt 2>&1 || true
print_success "Famine exécuté"
cat /tmp/famine_output.txt

# Supprimer le fichier de force
print_info "Suppression du fichier de force..."
rm -f /tmp/famine_force

# =============================================================================
# VÉRIFICATION DES INFECTIONS
# =============================================================================
print_header "Vérification des infections"

# Vérifier l'infection ELF64
print_info "Vérification de l'infection ELF64..."
if strings "$TEST_DIR/sample64" | grep -q "Famine version 1.0"; then
    print_success "Infection ELF64 réussie !"
    print_info "Signature trouvée dans le binaire ELF64:"
    strings "$TEST_DIR/sample64" | grep "Famine"
else
    print_error "Infection ELF64 échouée - signature non trouvée"
fi

# Vérifier l'infection ELF32
print_info "Vérification de l'infection ELF32..."
if strings "$TEST_DIR/sample32" | grep -q "Famine version 1.0"; then
    print_success "Infection ELF32 réussie !"
    print_info "Signature trouvée dans le binaire ELF32:"
    strings "$TEST_DIR/sample32" | grep "Famine"
else
    print_error "Infection ELF32 échouée - signature non trouvée"
fi

# =============================================================================
# VÉRIFICATION DE L'EXÉCUTABILITÉ POST-INFECTION
# =============================================================================
print_header "Vérification de l'exécutabilité post-infection"

# Test ELF64 post-infection
print_info "Test d'exécution ELF64 post-infection..."
timeout 5s "$TEST_DIR/sample64" > /tmp/elf64_post_infection.txt 2>&1
if [ $? -eq 0 ]; then
    print_success "Exécution ELF64 post-infection réussie"
    cat /tmp/elf64_post_infection.txt
else
    print_error "Échec de l'exécution ELF64 post-infection"
fi

# Test ELF32 post-infection
print_info "Test d'exécution ELF32 post-infection..."
if command -v qemu-i386 >/dev/null 2>&1; then
    timeout 5s qemu-i386 "$TEST_DIR/sample32" > /tmp/elf32_post_infection.txt 2>&1
    if [ $? -eq 0 ]; then
        print_success "Exécution ELF32 post-infection réussie"
        cat /tmp/elf32_post_infection.txt
    else
        print_error "Échec de l'exécution ELF32 post-infection"
    fi
else
    print_info "qemu-i386 non disponible pour le test ELF32 post-infection"
fi

# =============================================================================
# VÉRIFICATION DES FORMATS
# =============================================================================
print_header "Vérification des formats post-infection"

# Vérifier que les binaires restent dans leur format original
print_info "Vérification du format ELF64 post-infection..."
readelf -h "$TEST_DIR/sample64" | grep -q "Class:.*ELF64" && print_success "Format ELF64 préservé" || print_error "Format ELF64 corrompu"

print_info "Vérification du format ELF32 post-infection..."
readelf -h "$TEST_DIR/sample32" | grep -q "Class:.*ELF32" && print_success "Format ELF32 préservé" || print_error "Format ELF32 corrompu"

# =============================================================================
# RÉSUMÉ
# =============================================================================
print_header "Résumé des tests"

# Compter les infections réussies
elf64_infected=$(strings "$TEST_DIR/sample64" | grep -c "Famine version 1.0" || echo "0")
elf32_infected=$(strings "$TEST_DIR/sample32" | grep -c "Famine version 1.0" || echo "0")

print_info "Résultats:"
print_info "  - ELF64 infecté: $elf64_infected"
print_info "  - ELF32 infecté: $elf32_infected"

if [ "$elf64_infected" -gt 0 ] && [ "$elf32_infected" -gt 0 ]; then
    print_success "Tous les tests ont réussi ! Support ELF32 et ELF64 fonctionnel."
elif [ "$elf64_infected" -gt 0 ]; then
    print_success "Support ELF64 fonctionnel."
    print_info "Support ELF32 à vérifier."
else
    print_error "Problème avec l'infection."
fi

# Nettoyage
print_info "Nettoyage des fichiers temporaires..."
rm -f /tmp/elf64_output.txt /tmp/elf32_output.txt /tmp/famine_output.txt
rm -f /tmp/elf64_post_infection.txt /tmp/elf32_post_infection.txt

print_header "Tests terminés"
print_success "Script de test complet exécuté avec succès !"
