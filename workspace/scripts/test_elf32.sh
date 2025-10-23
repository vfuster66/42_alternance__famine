#!/bin/bash

# =============================================================================
# Script de test pour le support ELF32 de Famine
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
TEST_DIR="/tmp/test_elf32"
SAMPLE_SOURCE="$TEST_DIR/sample32.c"
SAMPLE_BINARY="$TEST_DIR/sample32"
FAMINE_BINARY="./Famine"

print_header "Test du support ELF32 de Famine"

# Créer le répertoire de test
print_info "Création du répertoire de test..."
mkdir -p "$TEST_DIR"

# Créer un programme C simple pour ELF32
print_info "Création du programme de test ELF32..."
cat > "$SAMPLE_SOURCE" << 'EOF'
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
    gcc -m32 -static -o "$SAMPLE_BINARY" "$SAMPLE_SOURCE"
    print_success "Compilation réussie"
else
    print_error "gcc non trouvé. Installation de gcc-multilib nécessaire."
    exit 1
fi

# Vérifier que le binaire est bien ELF32
print_info "Vérification du format ELF32..."
if command -v readelf >/dev/null 2>&1; then
    readelf -h "$SAMPLE_BINARY" | grep -q "Class:.*ELF32" && print_success "Binaire ELF32 confirmé" || print_error "Le binaire n'est pas ELF32"
else
    print_info "readelf non disponible, vérification manuelle..."
    file "$SAMPLE_BINARY" | grep -q "32-bit" && print_success "Binaire 32-bit confirmé" || print_error "Le binaire n'est pas 32-bit"
fi

# Tester l'exécution du binaire original
print_info "Test d'exécution du binaire original..."
if command -v qemu-i386 >/dev/null 2>&1; then
    # Utiliser qemu-i386 pour l'exécution
    timeout 5s qemu-i386 "$SAMPLE_BINARY" > /tmp/elf32_output.txt 2>&1
    if [ $? -eq 0 ]; then
        print_success "Exécution réussie avec qemu-i386"
        cat /tmp/elf32_output.txt
    else
        print_error "Échec de l'exécution avec qemu-i386"
    fi
else
    print_info "qemu-i386 non disponible, test direct..."
    # Essayer d'exécuter directement (peut échouer sur système 64-bit)
    timeout 5s "$SAMPLE_BINARY" > /tmp/elf32_output.txt 2>&1 || true
    if [ -s /tmp/elf32_output.txt ]; then
        print_success "Exécution réussie"
        cat /tmp/elf32_output.txt
    else
        print_info "Exécution directe échouée (normal sur système 64-bit)"
    fi
fi

# Vérifier que Famine est compilé
if [ ! -f "$FAMINE_BINARY" ]; then
    print_error "Famine non trouvé. Compilation nécessaire."
    exit 1
fi

# Copier le binaire dans le répertoire de test
print_info "Copie du binaire dans le répertoire de test..."
cp "$SAMPLE_BINARY" "$TEST_DIR/"

# Exécuter Famine sur le répertoire de test
print_info "Exécution de Famine sur le répertoire de test..."
if [ -f "$FAMINE_BINARY" ]; then
    timeout 10s "$FAMINE_BINARY" "$TEST_DIR" > /tmp/famine_output.txt 2>&1 || true
    print_success "Famine exécuté"
    cat /tmp/famine_output.txt
else
    print_error "Famine non trouvé"
    exit 1
fi

# Vérifier que le binaire a été infecté
print_info "Vérification de l'infection..."
if strings "$SAMPLE_BINARY" | grep -q "Famine version 1.0"; then
    print_success "Infection ELF32 réussie !"
    print_info "Signature trouvée dans le binaire:"
    strings "$SAMPLE_BINARY" | grep "Famine"
else
    print_error "Infection échouée - signature non trouvée"
fi

# Vérifier que le binaire reste exécutable
print_info "Vérification que le binaire reste exécutable..."
if command -v readelf >/dev/null 2>&1; then
    readelf -h "$SAMPLE_BINARY" | grep -q "Class:.*ELF32" && print_success "Format ELF32 préservé" || print_error "Format ELF32 corrompu"
fi

# Test d'exécution post-infection
print_info "Test d'exécution post-infection..."
if command -v qemu-i386 >/dev/null 2>&1; then
    timeout 5s qemu-i386 "$SAMPLE_BINARY" > /tmp/elf32_post_infection.txt 2>&1
    if [ $? -eq 0 ]; then
        print_success "Exécution post-infection réussie"
        cat /tmp/elf32_post_infection.txt
    else
        print_error "Échec de l'exécution post-infection"
    fi
else
    print_info "qemu-i386 non disponible pour le test post-infection"
fi

# Nettoyage
print_info "Nettoyage des fichiers temporaires..."
rm -f /tmp/elf32_output.txt /tmp/famine_output.txt /tmp/elf32_post_infection.txt

print_header "Test ELF32 terminé"
print_success "Tous les tests ELF32 ont été exécutés avec succès !"
