#!/bin/bash

# Script de compilation pour Famine
# Compatible macOS et Linux

echo "=== Compilation de Famine ==="

# Nettoyer
rm -rf build Famine
mkdir -p build

# Assembler les fichiers
echo "Assemblage des fichiers source..."
nasm -f elf64 -I include/ -o build/famine.o src/famine.asm
nasm -f elf64 -I include/ -o build/file_ops.o src/file_ops.asm
nasm -f elf64 -I include/ -o build/elf_check.o src/elf_check.asm
nasm -f elf64 -I include/ -o build/infect.o src/infect.asm

if [ $? -ne 0 ]; then
    echo "Erreur lors de l'assemblage"
    exit 1
fi

# Lier les fichiers
echo "Liaison des fichiers objets..."

# Détecter le système d'exploitation
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Détection: macOS"
    /usr/bin/ld -arch x86_64 -platform_version macos 10.15 0 -o Famine build/famine.o build/file_ops.o build/elf_check.o build/infect.o
else
    # Linux
    echo "Détection: Linux"
    ld -m elf_x86_64 -o Famine build/famine.o build/file_ops.o build/elf_check.o build/infect.o
fi

if [ $? -eq 0 ]; then
    echo "✓ Compilation réussie!"
    chmod +x Famine
    ls -la Famine
else
    echo "✗ Erreur lors de la liaison"
    exit 1
fi
