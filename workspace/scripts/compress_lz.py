#!/usr/bin/env python3
"""
Script de compression LZ pour Famine
Compresse la section .text d'un binaire ELF et génère le packer
"""

import sys
import os
import struct
import subprocess
from pathlib import Path

class LZCompressor:
    def __init__(self):
        self.window_size = 4096
        self.max_length = 127
        
    def find_match(self, data, pos):
        """Trouve la meilleure correspondance dans la fenêtre glissante"""
        best_length = 0
        best_distance = 0
        
        # Chercher dans la fenêtre glissante
        start = max(0, pos - self.window_size)
        
        for i in range(start, pos):
            length = 0
            # Compter les octets identiques
            while (length < self.max_length and 
                   pos + length < len(data) and 
                   data[i + length] == data[pos + length]):
                length += 1
            
            if length > best_length:
                best_length = length
                best_distance = pos - i
                
        return best_length, best_distance
    
    def compress(self, data):
        """Compresse les données avec l'algorithme LZ"""
        compressed = bytearray()
        pos = 0
        
        while pos < len(data):
            # Chercher une correspondance
            length, distance = self.find_match(data, pos)
            
            # Si on trouve une correspondance de 3 octets ou plus
            if length >= 3:
                # Token de référence
                token = (length - 3) & 0x7F
                compressed.append(token)
                
                # Distance (2 octets, little-endian)
                distance_bytes = struct.pack('<H', distance - 1)
                compressed.extend(distance_bytes)
                
                pos += length
            else:
                # Token littéral
                literal_length = min(128, len(data) - pos)
                token = 0x80 | (literal_length - 1)
                compressed.append(token)
                
                # Copier les données littérales
                compressed.extend(data[pos:pos + literal_length])
                pos += literal_length
        
        return bytes(compressed)

def extract_text_section(binary_path):
    """Extrait la section .text d'un binaire ELF"""
    try:
        with open(binary_path, 'rb') as f:
            # Lire l'en-tête ELF
            elf_header = f.read(64)
            
            # Vérifier la signature ELF
            if elf_header[:4] != b'\x7fELF':
                raise ValueError("Fichier non-ELF")
            
            # Lire l'offset des en-têtes de section
            shoff = struct.unpack('<Q', elf_header[40:48])[0]
            shnum = struct.unpack('<H', elf_header[60:62])[0]
            shentsize = struct.unpack('<H', elf_header[58:60])[0]
            
            # Lire la table des chaînes des sections
            f.seek(shoff + (shnum - 1) * shentsize)
            strtab_header = f.read(shentsize)
            strtab_offset = struct.unpack('<Q', strtab_header[24:32])[0]
            strtab_size = struct.unpack('<Q', strtab_header[32:40])[0]
            
            # Lire la table des chaînes
            f.seek(strtab_offset)
            strtab = f.read(strtab_size)
            
            # Chercher la section .text
            f.seek(shoff)
            text_section = None
            
            for i in range(shnum):
                section_header = f.read(shentsize)
                if len(section_header) < 64:
                    break
                
                # Lire le nom de la section
                name_offset = struct.unpack('<I', section_header[0:4])[0]
                if name_offset < len(strtab):
                    name_end = strtab.find(b'\x00', name_offset)
                    if name_end == -1:
                        name_end = len(strtab)
                    name = strtab[name_offset:name_end].decode('ascii', errors='ignore')
                    
                    if name == '.text':
                        # Lire les informations de la section
                        sh_type = struct.unpack('<I', section_header[4:8])[0]
                        sh_flags = struct.unpack('<Q', section_header[8:16])[0]
                        sh_addr = struct.unpack('<Q', section_header[16:24])[0]
                        sh_offset = struct.unpack('<Q', section_header[24:32])[0]
                        sh_size = struct.unpack('<Q', section_header[32:40])[0]
                        
                        text_section = {
                            'name': name,
                            'size': sh_size,
                            'vma': sh_addr,
                            'lma': sh_addr,
                            'file_offset': sh_offset
                        }
                        break
            
            if not text_section:
                raise ValueError("Section .text non trouvée")
            
            # Lire la section .text
            f.seek(text_section['file_offset'])
            text_data = f.read(text_section['size'])
            
            return text_data, text_section
            
    except Exception as e:
        raise RuntimeError(f"Erreur lors de l'extraction de la section .text: {e}")

def create_packed_binary(original_binary, compressed_data, original_size, output_path):
    """Crée le binaire packé avec le stub de décompression"""
    
    # Lire le binaire original
    with open(original_binary, 'rb') as f:
        original_data = f.read()
    
    # Assembler le packer
    packer_source = """
BITS 64

global _start
global compressed_data
global compressed_size
global original_size

section .data
    compressed_data: db """
    
    # Ajouter les données compressées
    hex_data = ', '.join(f'0x{b:02x}' for b in compressed_data)
    packer_source += hex_data + "\n"
    packer_source += f"    compressed_size: dq {len(compressed_data)}\n"
    packer_source += f"    original_size: dq {original_size}\n"
    
    # Ajouter le stub de décompression
    packer_source += """
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
    
    ; Allouer de l'espace pour les données décompressées
    mov rdi, [original_size]
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
    
    ; Décompresser
    mov r12, rax
    mov r13, compressed_data
    mov r14, [compressed_size]
    mov r15, [original_size]
    
    call decompress
    
    ; Exécuter le code décompressé
    call r12
    
    ; Nettoyer
    mov rdi, r12
    mov rsi, r15
    mov rax, 11                      ; munmap
    syscall
    
    ; Restaurer et sortir
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
    
    xor rdi, rdi
    mov rax, 60
    syscall

.error:
    xor rdi, rdi
    mov rax, 60
    syscall

decompress:
    push rbp
    mov rbp, rsp
    
    xor r8, r8                       ; pos dans compressed
    xor r9, r9                       ; pos dans output
    
.loop:
    cmp r8, r14
    jge .done
    
    movzx rax, byte [r13 + r8]
    inc r8
    
    test rax, 0x80
    jnz .literal
    
    ; Reference
    and rax, 0x7F
    add rax, 3
    
    movzx rbx, word [r13 + r8]
    add r8, 2
    inc rbx
    
    mov rcx, rax
    mov rdx, r9
    sub rdx, rbx
    
.copy_ref:
    test rcx, rcx
    jz .loop
    
    cmp r9, r15
    jge .error
    
    movzx r10, byte [r12 + rdx]
    mov byte [r12 + r9], r10
    
    inc r9
    inc rdx
    dec rcx
    jmp .copy_ref
    
.literal:
    and rax, 0x7F
    inc rax
    
    mov rcx, rax
.copy_lit:
    test rcx, rcx
    jz .loop
    
    cmp r8, r14
    jge .error
    cmp r9, r15
    jge .error
    
    movzx r10, byte [r13 + r8]
    mov byte [r12 + r9], r10
    
    inc r8
    inc r9
    dec rcx
    jmp .copy_lit
    
.done:
    cmp r9, r15
    jne .error
    
    mov rax, 1
    jmp .end
    
.error:
    xor rax, rax
    
.end:
    leave
    ret
"""
    
    # Écrire le source du packer
    packer_path = output_path + '.asm'
    with open(packer_path, 'w') as f:
        f.write(packer_source)
    
    return packer_path

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 compress_lz.py <input_binary> <output_packed>")
        sys.exit(1)
    
    input_binary = sys.argv[1]
    output_packed = sys.argv[2]
    
    try:
        print(f"→ Extraction de la section .text de {input_binary}...")
        text_data, text_section = extract_text_section(input_binary)
        print(f"✓ Section .text extraite ({len(text_data)} octets)")
        
        print("→ Compression LZ...")
        compressor = LZCompressor()
        compressed_data = compressor.compress(text_data)
        print(f"✓ Données compressées ({len(compressed_data)} octets)")
        
        compression_ratio = len(compressed_data) / len(text_data) * 100
        print(f"→ Ratio de compression: {compression_ratio:.1f}%")
        
        print("→ Création du binaire packé...")
        packer_source = create_packed_binary(
            input_binary, 
            compressed_data, 
            len(text_data), 
            output_packed
        )
        print(f"✓ Source du packer créé: {packer_source}")
        
        print("→ Assemblage du packer...")
        subprocess.run([
            'nasm', '-f', 'elf64', '-o', f'{output_packed}.o', packer_source
        ], check=True)
        
        subprocess.run([
            'ld', '-m', 'elf_x86_64', '-o', output_packed, f'{output_packed}.o'
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
