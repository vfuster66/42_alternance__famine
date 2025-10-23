; **************************************************************************** ;
;                                                                              ;
;    file_ops.asm                                         :::      ::::::::    ;
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

global map_file
global unmap_file

section .text

; =============================================================================
; map_file: Mappe un fichier en mémoire
; Params: aucun (utilise current_file)
; Returns: rax = adresse mappée (0 si erreur)
; Side effects: modifie current_file.mapped_addr
; =============================================================================
map_file:
    push rbp
    mov rbp, rsp
    
    ; mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)
    xor rdi, rdi                        ; addr = NULL
    mov rsi, [current_file + file_info.size]  ; length
    mov rdx, PROT_READ | PROT_WRITE     ; prot
    mov r10, MAP_SHARED                 ; flags
    movsxd r8, dword [current_file + file_info.fd]  ; fd
    xor r9, r9                          ; offset = 0
    mov rax, SYS_MMAP
    syscall
    
    ; Vérifier l'erreur (MAP_FAILED = -1)
    cmp rax, -1
    je .error
    
    ; Vérifier que l'adresse est valide
    test rax, rax
    jz .error
    
    ; Sauvegarder l'adresse mappée
    mov [current_file + file_info.mapped_addr], rax
    
    leave
    ret

.error:
    xor rax, rax
    leave
    ret

; =============================================================================
; unmap_file: Démappe un fichier de la mémoire
; Params: aucun (utilise current_file)
; Returns: rien
; Side effects: libère la mémoire mappée
; =============================================================================
unmap_file:
    push rbp
    mov rbp, rsp
    
    ; Vérifier qu'il y a bien une zone mappée
    mov rdi, [current_file + file_info.mapped_addr]
    test rdi, rdi
    jz .done
    
    ; munmap(addr, length)
    mov rsi, [current_file + file_info.size]
    mov rax, SYS_MUNMAP
    syscall
    
    ; Réinitialiser l'adresse
    xor rax, rax
    mov [current_file + file_info.mapped_addr], rax
    
.done:
    leave
    ret
