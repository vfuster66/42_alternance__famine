#!/bin/bash
# Script de packing final pour Docker Linux

if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_binary> <output_packed>"
    exit 1
fi

INPUT_BINARY="$1"
OUTPUT_PACKED="$2"

echo "→ Création du packer simple pour $INPUT_BINARY..."
echo "→ Vérification des outils disponibles..."
echo "  - nasm: $(which nasm)"
echo "  - ld: $(which ld)"

# Lire le binaire original et créer le packer avec les données
BINARY_SIZE=$(wc -c < "$INPUT_BINARY")
echo "→ Taille du binaire original: $BINARY_SIZE octets"

# Créer un nouveau fichier avec les données du binaire
{
    echo "BITS 64"
    echo ""
    echo "global _start"
    echo ""
    echo "section .data"
    echo "    ; Données du binaire original"
    echo -n "    original_data: db "
    
    # Convertir le binaire en hexadécimal de manière plus simple
    hexdump -v -e '1/1 "0x%02x, "' "$INPUT_BINARY" | sed 's/, $//'
    echo ""
    echo "    original_size: dq $BINARY_SIZE"
    echo ""
    echo "section .text"
    echo "_start:"
    echo "    ; Sauvegarder les registres"
    echo "    push rax"
    echo "    push rbx"
    echo "    push rcx"
    echo "    push rdx"
    echo "    push rsi"
    echo "    push rdi"
    echo "    push rbp"
    echo "    push r8"
    echo "    push r9"
    echo "    push r10"
    echo "    push r11"
    echo "    push r12"
    echo "    push r13"
    echo "    push r14"
    echo "    push r15"
    echo ""
    echo "    ; Allouer de l'espace pour le code avec mmap"
    echo "    mov rdi, [original_size]"
    echo "    add rdi, 4096"
    echo "    mov rax, 9                       ; mmap"
    echo "    mov rsi, 0                       ; addr"
    echo "    mov rdx, 7                       ; PROT_READ | PROT_WRITE | PROT_EXEC"
    echo "    mov r10, 34                      ; MAP_PRIVATE | MAP_ANONYMOUS"
    echo "    mov r8, -1"
    echo "    xor r9, r9"
    echo "    syscall"
    echo ""
    echo "    test rax, rax"
    echo "    jz .error"
    echo ""
    echo "    ; Copier le code original"
    echo "    mov r12, rax                     ; adresse de destination"
    echo "    mov r13, original_data            ; adresse source"
    echo "    mov r14, [original_size]          ; taille"
    echo "    mov r15, 0                       ; compteur"
    echo ""
    echo ".copy_loop:"
    echo "    cmp r15, r14"
    echo "    jge .copy_done"
    echo ""
    echo "    movzx rbx, byte [r13 + r15]"
    echo "    mov byte [r12 + r15], bl"
    echo ""
    echo "    inc r15"
    echo "    jmp .copy_loop"
    echo ""
    echo ".copy_done:"
    echo "    ; Exécuter le code copié"
    echo "    call r12"
    echo ""
    echo "    ; Nettoyer"
    echo "    mov rdi, r12"
    echo "    mov rsi, r14"
    echo "    mov rax, 11                      ; munmap"
    echo "    syscall"
    echo ""
    echo "    ; Restaurer les registres"
    echo "    pop r15"
    echo "    pop r14"
    echo "    pop r13"
    echo "    pop r12"
    echo "    pop r11"
    echo "    pop r10"
    echo "    pop r9"
    echo "    pop r8"
    echo "    pop rbp"
    echo "    pop rdi"
    echo "    pop rsi"
    echo "    pop rdx"
    echo "    pop rcx"
    echo "    pop rbx"
    echo "    pop rax"
    echo ""
    echo "    ; Sortie"
    echo "    xor rdi, rdi"
    echo "    mov rax, 60"
    echo "    syscall"
    echo ""
    echo ".error:"
    echo "    xor rdi, rdi"
    echo "    mov rax, 60"
    echo "    syscall"
} > "${OUTPUT_PACKED}.asm"

echo "✓ Source du packer créé: ${OUTPUT_PACKED}.asm"

echo "→ Assemblage du packer..."
echo "  - Commande: nasm -f macho64 -o ${OUTPUT_PACKED}.o ${OUTPUT_PACKED}.asm"
nasm -f macho64 -o "${OUTPUT_PACKED}.o" "${OUTPUT_PACKED}.asm"
if [ $? -ne 0 ]; then
    echo "✗ Erreur lors de l'assemblage"
    echo "→ Vérification du fichier source..."
    echo "  - Premières lignes:"
    head -10 "${OUTPUT_PACKED}.asm"
    echo "  - Ligne 7 (problématique):"
    sed -n '7p' "${OUTPUT_PACKED}.asm"
    exit 1
fi

echo "✓ Assemblage réussi"
echo "→ Vérification du fichier objet..."
echo "  - Fichier objet créé: $(ls -la "${OUTPUT_PACKED}.o")"
echo "  - Type de fichier: $(file "${OUTPUT_PACKED}.o")"

echo "→ Édition de liens..."
echo "  - Commande: ld -o $OUTPUT_PACKED ${OUTPUT_PACKED}.o"
ld -o "$OUTPUT_PACKED" "${OUTPUT_PACKED}.o"
if [ $? -ne 0 ]; then
    echo "✗ Erreur lors de l'édition de liens"
    echo "→ Tentative avec gcc..."
    gcc -arch x86_64 -o "$OUTPUT_PACKED" "${OUTPUT_PACKED}.o" -nostdlib -e _start
    if [ $? -ne 0 ]; then
        echo "✗ Erreur avec gcc aussi"
        exit 1
    fi
fi

echo "✓ Binaire packé créé: $OUTPUT_PACKED"

# Nettoyer les fichiers temporaires
rm -f "${OUTPUT_PACKED}.asm" "${OUTPUT_PACKED}.o"

echo "✓ Packing terminé avec succès"
