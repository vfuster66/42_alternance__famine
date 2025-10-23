; **************************************************************************** ;
;                                                                              ;
;    packer.asm                                          :::      ::::::::    ;
;                                                       :+:      :+:    :+:    ;
;    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         ;
;                                                 +#+#+#+#+#+   +#+            ;
;    Created: 2025/10/22 17:30:00 by sdestann          #+#    #+#              ;
;    Updated: 2025/10/22 17:30:00 by sdestann         ###   ########.fr        ;
; **************************************************************************** ;

BITS 64

%include "include/macros.inc"
%include "include/structures.inc"

global _start
global compressed_data
global compressed_size
global original_size
global decompression_stub

; =============================================================================
; DONNÉES COMPRESSÉES
; =============================================================================
section .data
    ; Signature du packer
    packer_sig: db "Famine Packer v1.0", 0
    
    ; Données compressées (sera rempli par le script de packing)
    compressed_data: times 8192 db 0
    compressed_size: dq 0
    original_size: dq 0

; =============================================================================
; STUB DE DÉCOMPRESSION
; =============================================================================
section .text

; =============================================================================
; _start: Point d'entrée du stub de décompression
; Décompresse les données et exécute le code original
; =============================================================================
_start:
    ; Sauvegarder tous les registres
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
    add rdi, 4096                    ; Buffer supplémentaire
    mov rax, SYS_MMAP
    xor rsi, rsi                     ; addr = NULL
    mov rdx, PROT_READ | PROT_WRITE | PROT_EXEC
    mov r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1                       ; fd = -1
    xor r9, r9                       ; offset = 0
    syscall
    
    test rax, rax
    jz .decompression_error
    
    ; rax = adresse du buffer de décompression
    mov r12, rax                     ; Sauvegarder l'adresse du buffer
    mov r13, [compressed_data]       ; Pointeur vers les données compressées
    mov r14, [compressed_size]       ; Taille des données compressées
    mov r15, [original_size]         ; Taille originale
    
    ; Décompresser les données
    call lz_decompress
    
    ; Vérifier que la décompression a réussi
    test rax, rax
    jz .decompression_error
    
    ; Exécuter le code décompressé
    call r12
    
    ; Nettoyer et sortir
    mov rdi, r12
    mov rsi, r15
    mov rax, SYS_MUNMAP
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
    
    ; Sortie normale
    xor rdi, rdi
    mov rax, SYS_EXIT
    syscall

.decompression_error:
    ; En cas d'erreur, sortie silencieuse
    xor rdi, rdi
    mov rax, SYS_EXIT
    syscall

; =============================================================================
; lz_decompress: Décompression LZ simple
; Params: r12 = buffer de destination
;         r13 = données compressées
;         r14 = taille compressée
;         r15 = taille originale
; Returns: rax = 1 si succès, 0 si échec
; =============================================================================
lz_decompress:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Sauvegarder les paramètres
    mov [rbp-8], r12                 ; buffer de destination
    mov [rbp-16], r13                ; données compressées
    mov [rbp-24], r14                ; taille compressée
    mov [rbp-32], r15                ; taille originale
    
    xor r8, r8                       ; Index dans les données compressées
    xor r9, r9                       ; Index dans le buffer de destination
    
.decompress_loop:
    ; Vérifier si on a traité toutes les données
    cmp r8, r14
    jge .decompress_done
    
    ; Lire le token de contrôle
    movzx rax, byte [r13 + r8]
    inc r8
    
    ; Vérifier le type de token
    test rax, 0x80                   ; Bit de poids fort
    jnz .handle_literal
    
    ; Token de référence (compression)
    ; Format: 0xxxxxxx yyyy
    ; xxxxxxx = longueur - 3
    ; yyyy = distance - 1
    
    ; Extraire la longueur
    and rax, 0x7F
    add rax, 3                       ; longueur = (token & 0x7F) + 3
    
    ; Lire la distance (2 octets)
    movzx rbx, word [r13 + r8]
    add r8, 2
    inc rbx                          ; distance = distance + 1
    
    ; Vérifier que la distance est valide
    cmp rbx, r9
    jg .decompression_error
    
    ; Copier les données
    mov rcx, rax                     ; longueur à copier
    mov rdx, r9                      ; position de destination
    sub rdx, rbx                     ; position source
    
.copy_loop:
    test rcx, rcx
    jz .decompress_loop
    
    ; Vérifier les limites
    cmp r9, r15
    jge .decompression_error
    
    ; Copier un octet
    movzx r10, byte [r12 + rdx]
    mov byte [r12 + r9], r10
    
    inc r9
    inc rdx
    dec rcx
    jmp .copy_loop
    
.handle_literal:
    ; Token littéral
    ; Format: 1xxxxxxx
    ; xxxxxxx = longueur - 1
    
    and rax, 0x7F
    inc rax                          ; longueur = (token & 0x7F) + 1
    
    ; Copier les données littérales
    mov rcx, rax
.literal_loop:
    test rcx, rcx
    jz .decompress_loop
    
    ; Vérifier les limites
    cmp r8, r14
    jge .decompression_error
    cmp r9, r15
    jge .decompression_error
    
    ; Copier un octet
    movzx r10, byte [r13 + r8]
    mov byte [r12 + r9], r10
    
    inc r8
    inc r9
    dec rcx
    jmp .literal_loop
    
.decompress_done:
    ; Vérifier que la taille finale est correcte
    cmp r9, r15
    jne .decompression_error
    
    ; Succès
    mov rax, 1
    jmp .end
    
.decompression_error:
    xor rax, rax
    
.end:
    leave
    ret

; =============================================================================
; decompression_stub: Fonction utilitaire pour accéder au stub
; =============================================================================
decompression_stub:
    ; Cette fonction est utilisée pour obtenir l'adresse du stub
    mov rax, _start
    ret
