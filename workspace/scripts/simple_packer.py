#!/usr/bin/env python3
"""
Script de packing simplifié pour Famine
Crée un binaire packé avec un stub de décompression simple
"""

import sys
import os
import struct
import subprocess

def create_simple_packer(original_binary, output_path):
    """Crée un packer simple qui copie le binaire original"""
    
    # Lire le binaire original
    with open(original_binary, 'rb') as f:
        original_data = f.read()
    
    # Créer le source du packer
    packer_source = f"""
BITS 64

global _start

section .data
    ; Données du binaire original
    original_data: db {', '.join(f'0x{b:02x}' for b in original_data)}
    original_size: dq {len(original_data)}

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
    
    ; Allouer de l'espace pour le code
    mov rdi, [rel original_size]
    add rdi, 4096
    mov rax, 9                       ; mmap
    xor rsi, rsi
    mov rdx, 7                       ; PROT_READ | PROT_WRITE | PROT_EXEC
    mov r10, 34                      ; MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1
    xor r9, r9
    syscall
    
    test rax, rax
    jz .error
    
    ; Copier le code original
    mov r12, rax                     ; adresse de destination
    lea r13, [rel original_data]    ; adresse source (relative)
    mov r14, [rel original_size]     ; taille
    mov r15, 0                       ; compteur
    
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
    mov rax, 11                      ; munmap
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
"""
    
    # Écrire le source du packer
    packer_path = output_path + '.asm'
    with open(packer_path, 'w') as f:
        f.write(packer_source)
    
    return packer_path

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 simple_packer.py <input_binary> <output_packed>")
        sys.exit(1)
    
    input_binary = sys.argv[1]
    output_packed = sys.argv[2]
    
    try:
        print(f"→ Création du packer simple pour {input_binary}...")
        packer_source = create_simple_packer(input_binary, output_packed)
        print(f"✓ Source du packer créé: {packer_source}")
        
        print("→ Assemblage du packer...")
        # Détecter l'OS
        import platform
        if platform.system() == 'Darwin':
            # macOS - utiliser macho64 avec émulation x86_64
            subprocess.run([
                'nasm', '-f', 'macho64', '-o', f'{output_packed}.o', packer_source
            ], check=True)
            
            subprocess.run([
                'gcc', '-arch', 'x86_64', '-o', output_packed, f'{output_packed}.o', '-nostdlib', '-e', '_start'
            ], check=True)
        else:
            # Linux - utiliser elf64
            subprocess.run([
                'nasm', '-f', 'elf64', '-o', f'{output_packed}.o', packer_source
            ], check=True)
            
            subprocess.run([
                'ld', '-o', output_packed, f'{output_packed}.o'
            ], check=True)
        
        print(f"✓ Binaire packé créé: {output_packed}")
        
        # Nettoyer les fichiers temporaires
        os.remove(packer_source)
        os.remove(f'{output_packed}.o')
        
    except Exception as e:
        print(f"✗ Erreur: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
