#!/bin/bash

# =============================================================================
# Script simple pour créer un binaire ELF32 de test
# =============================================================================

set -e

# Créer le répertoire
mkdir -p /tmp/test_elf32

# Créer un binaire ELF32 minimal avec nasm (qui est disponible)
cat > /tmp/test_elf32/sample32.asm << 'EOF'
BITS 32

section .text
global _start

_start:
    ; Appel système write
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, msg        ; message
    mov edx, msg_len    ; longueur
    int 0x80
    
    ; Appel système exit
    mov eax, 1          ; sys_exit
    mov ebx, 0          ; code 0
    int 0x80

section .data
msg: db "Hello from ELF32!", 10
msg_len equ $ - msg
EOF

# Assembler avec nasm
nasm -f elf32 -o /tmp/test_elf32/sample32.o /tmp/test_elf32/sample32.asm

# Linker avec ld
ld -m elf_i386 -o /tmp/test_elf32/sample32 /tmp/test_elf32/sample32.o

echo "✓ Binaire ELF32 créé avec nasm"
