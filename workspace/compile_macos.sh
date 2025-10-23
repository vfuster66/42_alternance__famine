#!/bin/bash

# Script de compilation pour Famine sur macOS
echo "=== Compilation de Famine sur macOS ==="

# Nettoyer
rm -rf build Famine
mkdir -p build

# Assembler les fichiers pour macOS
echo "Assemblage des fichiers source..."
nasm -f macho64 -I include/ -o build/famine.o src/famine.asm
nasm -f macho64 -I include/ -o build/file_ops.o src/file_ops.asm
nasm -f macho64 -I include/ -o build/elf_check.o src/elf_check.asm
nasm -f macho64 -I include/ -o build/infect.o src/infect.asm

if [ $? -ne 0 ]; then
    echo "Erreur lors de l'assemblage"
    exit 1
fi

# Lier les fichiers pour macOS
echo "Liaison des fichiers objets..."
ld -arch x86_64 -platform_version macos 10.15 0 -o Famine build/famine.o build/file_ops.o build/elf_check.o build/infect.o

if [ $? -eq 0 ]; then
    echo "✓ Compilation réussie!"
    chmod +x Famine
    ls -la Famine
else
    echo "✗ Erreur lors de la liaison"
    exit 1
fi
