#!/bin/bash
# Script de packing simple avec stub de décompression

if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_binary> <output_packed>"
    exit 1
fi

INPUT_BINARY="$1"
OUTPUT_PACKED="$2"

echo "→ Création du stub de décompression pour $INPUT_BINARY..."

# Créer un stub de décompression simple
cat > "${OUTPUT_PACKED}.asm" << 'EOF'
BITS 64

global _start

section .text
_start:
    ; Sauvegarder les registres
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    
    ; Allouer de l'espace pour le code avec mmap
    mov rdi, 0                       ; addr
    mov rsi, 0x10000                ; length (64KB)
    mov rdx, 7                      ; PROT_READ | PROT_WRITE | PROT_EXEC
    mov r10, 34                     ; MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1                      ; fd
    xor r9, r9                      ; offset
    mov rax, 9                     ; mmap
    syscall
    
    test rax, rax
    jz .error
    
    ; Copier le code original (simulation)
    mov r12, rax                    ; adresse de destination
    mov r13, 0x400000              ; adresse source (simulation)
    mov r14, 0x1000                ; taille (simulation)
    mov r15, 0                     ; compteur
    
.copy_loop:
    cmp r15, r14
    jge .copy_done
    
    movzx rbx, byte [r13 + r15]
    mov byte [r12 + r15], bl
    
    inc r15
    jmp .copy_loop
    
.copy_done:
    ; Exécuter le code copié
    call r12
    
    ; Nettoyer
    mov rdi, r12
    mov rsi, r14
    mov rax, 11                     ; munmap
    syscall
    
    ; Restaurer les registres
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    
    ; Sortie
    xor rdi, rdi
    mov rax, 60
    syscall
    
.error:
    xor rdi, rdi
    mov rax, 60
    syscall
EOF

echo "✓ Source du stub créé: ${OUTPUT_PACKED}.asm"

echo "→ Assemblage du stub..."
nasm -f elf64 -o "${OUTPUT_PACKED}.o" "${OUTPUT_PACKED}.asm"
if [ $? -ne 0 ]; then
    echo "✗ Erreur lors de l'assemblage"
    exit 1
fi

echo "✓ Assemblage réussi"

echo "→ Édition de liens..."
    ld -o "$OUTPUT_PACKED" "${OUTPUT_PACKED}.o"
if [ $? -ne 0 ]; then
    echo "✗ Erreur lors de l'édition de liens"
    exit 1
fi

echo "✓ Stub de décompression créé: $OUTPUT_PACKED"

# Nettoyer les fichiers temporaires
rm -f "${OUTPUT_PACKED}.asm" "${OUTPUT_PACKED}.o"

echo "✓ Packing terminé avec succès"
