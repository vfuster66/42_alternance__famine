; **************************************************************************** ;
;                                                                              ;
;    macros.inc                                            :::      ::::::::    ;
;                                                       :+:      :+:    :+:    ;
;    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         ;
;                                                 +#+#+#+#+#+   +#+            ;
;    Created: 2025/10/13 14:07:12 by sdestann          #+#    #+#              ;
;    Updated: 2025/10/14 20:58:19 by sdestann         ###   ########.fr        ;
; **************************************************************************** ;

; =============================================================================
; CONSTANTES SYSTÈME
; =============================================================================

%define SYS_READ        0
%define SYS_WRITE       1
%define SYS_OPEN        2
%define SYS_CLOSE       3
%define SYS_LSEEK       8
%define SYS_MMAP        9
%define SYS_MUNMAP      11
%define SYS_EXIT        60
%define SYS_GETDENTS64  217
%define SYS_GETTIMEOFDAY 96

%define O_RDONLY        0
%define O_WRONLY        1
%define O_RDWR          2

%define PROT_READ       1
%define PROT_WRITE      2
%define MAP_SHARED      1
%define MAP_PRIVATE     2
%define MAP_ANONYMOUS   0x20

%define DT_REG          8       ; Type fichier régulier

; =============================================================================
; CONSTANTES ELF64
; =============================================================================

%define ELFCLASS32      1
%define ELFCLASS64      2
%define ELFDATA2LSB     1
%define ELF_MAGIC       0x464c457f  ; 0x7f, 'E', 'L', 'F'

%define ET_EXEC         2
%define ET_DYN          3

%define PT_LOAD         1
%define PT_NOTE         4

%define PF_X            1
%define PF_W            2
%define PF_R            4

; Offsets dans l'en-tête ELF64
%define E_IDENT         0
%define E_TYPE          16
%define E_MACHINE       18
%define E_PHOFF         32
%define E_PHENTSIZE     54
%define E_PHNUM         56

; Taille de l'en-tête ELF64
%define EHDR_SIZE       64

; Offsets dans Program Header
%define P_TYPE          0
%define P_FLAGS         4
%define P_OFFSET        8
%define P_VADDR         16
%define P_FILESZ        32
%define P_MEMSZ         40

; Taille d'un Program Header
%define PHDR_SIZE       56

; =============================================================================
; MACROS DE SAUVEGARDE REGISTRES
; =============================================================================

%macro PUSH_CALLEE_SAVE 0
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
%endmacro

%macro POP_CALLEE_SAVE 0
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
%endmacro

; =============================================================================
; MACROS DE SYSCALLS SÉCURISÉS
; =============================================================================

%macro SYSCALL_SAFE 1
    mov rax, %1
    syscall
%endmacro

; =============================================================================
; MACROS DE DEBUG (désactivé en production)
; =============================================================================

%ifdef DEBUG
    %macro DEBUG_PRINT 1
        ; Code de debug ici si nécessaire
    %endmacro
%else
    %macro DEBUG_PRINT 1
        ; Rien en production
    %endmacro
%endif

; =============================================================================
; MACROS DE VÉRIFICATION
; =============================================================================

%macro CHECK_NULL 2
    test %1, %1
    jz %2
%endmacro

%macro CHECK_ERROR 2
    cmp rax, 0
    jl %1
    test rax, rax
    jz %2
%endmacro