#!/bin/bash

# =============================================================================
# Script pour créer un binaire ELF32 de test
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

# Créer le répertoire de test
mkdir -p /tmp/test_elf32

# Méthode 1: Essayer la compilation C standard
print_info "Tentative de compilation C standard..."
if gcc -m32 -static -o /tmp/test_elf32/sample32 /tmp/test_elf32/sample32.c 2>/dev/null; then
    print_success "Compilation C statique réussie"
    exit 0
fi

# Méthode 2: Essayer la compilation C sans static
print_info "Tentative de compilation C sans static..."
if gcc -m32 -o /tmp/test_elf32/sample32 /tmp/test_elf32/sample32.c 2>/dev/null; then
    print_success "Compilation C réussie"
    exit 0
fi

# Méthode 3: Installer les dépendances et réessayer
print_info "Installation des dépendances 32-bit..."
if apt-get update >/dev/null 2>&1 && apt-get install -y gcc-multilib >/dev/null 2>&1; then
    print_info "Tentative de compilation après installation des dépendances..."
    if gcc -m32 -static -o /tmp/test_elf32/sample32 /tmp/test_elf32/sample32.c 2>/dev/null; then
        print_success "Compilation C réussie après installation des dépendances"
        exit 0
    fi
fi

# Méthode 4: Créer un binaire ELF32 en assembleur pur
print_info "Création d'un binaire ELF32 en assembleur..."
cat > /tmp/test_elf32/sample32.s << 'EOF'
.section .text
.global _start
_start:
    # Appel système write
    mov $1, %rax        # sys_write
    mov $1, %rdi        # stdout
    mov $msg, %rsi      # message
    mov $msg_len, %rdx  # longueur
    syscall
    
    # Appel système exit
    mov $60, %rax       # sys_exit
    xor %rdi, %rdi      # code 0
    syscall

.section .data
msg: .ascii "Hello from ELF32!\n"
msg_len = . - msg
EOF

# Assembler et linker
if as -32 -o /tmp/test_elf32/sample32.o /tmp/test_elf32/sample32.s && \
   ld -m elf_i386 -o /tmp/test_elf32/sample32 /tmp/test_elf32/sample32.o; then
    print_success "Binaire ELF32 créé en assembleur"
    exit 0
fi

# Méthode 5: Créer un binaire ELF32 minimal avec nasm
print_info "Création d'un binaire ELF32 minimal avec nasm..."
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
if nasm -f elf32 -o /tmp/test_elf32/sample32.o /tmp/test_elf32/sample32.asm && \
   ld -m elf_i386 -o /tmp/test_elf32/sample32 /tmp/test_elf32/sample32.o; then
    print_success "Binaire ELF32 créé avec nasm"
    exit 0
fi

# Méthode 6: Créer un binaire ELF32 avec objcopy
print_info "Création d'un binaire ELF32 avec objcopy..."
# Créer un fichier binaire minimal
echo -e "\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00\x01\x00\x00\x00" > /tmp/test_elf32/sample32
echo -e "\x54\x00\x00\x00\x00\x00\x00\x00\x34\x00\x20\x00\x01\x00\x00\x00\x00\x00\x00\x00" >> /tmp/test_elf32/sample32
# Remplir avec des zéros pour avoir une taille minimale
dd if=/dev/zero of=/tmp/test_elf32/sample32 bs=1 count=1000 seek=100 2>/dev/null
chmod +x /tmp/test_elf32/sample32

if file /tmp/test_elf32/sample32 | grep -q "ELF 32-bit"; then
    print_success "Binaire ELF32 créé avec objcopy"
    exit 0
fi

print_error "Impossible de créer un binaire ELF32"
exit 1
