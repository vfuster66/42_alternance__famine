; **************************************************************************** ;
;                                                                              ;
;    structures.asm                                       :::      ::::::::    ;
;                                                       :+:      :+:    :+:    ;
;    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         ;
;                                                 +#+#+#+#+#+   +#+            ;
;    Created: 2025/10/13 14:07:12 by sdestann          #+#    #+#              ;
;    Updated: 2025/10/14 20:58:19 by sdestann         ###   ########.fr        ;
; **************************************************************************** ;

; =============================================================================
; STRUCTURE: linux_dirent64
; Pour énumérer les fichiers dans un répertoire
; =============================================================================
struc linux_dirent64
    .d_ino:      resq 1      ; Inode number
    .d_off:      resq 1      ; Offset to next dirent
    .d_reclen:   resw 1      ; Length of this dirent
    .d_type:     resb 1      ; File type
    .d_name:     resb 256    ; Filename (null-terminated)
endstruc

; =============================================================================
; STRUCTURE: ELF64 Header
; En-tête principal d'un binaire ELF64
; =============================================================================
struc Elf64_Ehdr
    .e_ident:     resb 16    ; Magic number et autres infos
    .e_type:      resw 1     ; Object file type
    .e_machine:   resw 1     ; Architecture
    .e_version:   resd 1     ; Object file version
    .e_entry:     resq 1     ; Entry point virtual address
    .e_phoff:     resq 1     ; Program header table file offset
    .e_shoff:     resq 1     ; Section header table file offset
    .e_flags:     resd 1     ; Processor-specific flags
    .e_ehsize:    resw 1     ; ELF header size in bytes
    .e_phentsize: resw 1     ; Program header table entry size
    .e_phnum:     resw 1     ; Program header table entry count
    .e_shentsize: resw 1     ; Section header table entry size
    .e_shnum:     resw 1     ; Section header table entry count
    .e_shstrndx:  resw 1     ; Section header string table index
endstruc

; =============================================================================
; STRUCTURE: ELF64 Program Header
; Décrit un segment à charger en mémoire
; =============================================================================
struc Elf64_Phdr
    .p_type:   resd 1        ; Segment type
    .p_flags:  resd 1        ; Segment flags
    .p_offset: resq 1        ; Segment file offset
    .p_vaddr:  resq 1        ; Segment virtual address
    .p_paddr:  resq 1        ; Segment physical address
    .p_filesz: resq 1        ; Segment size in file
    .p_memsz:  resq 1        ; Segment size in memory
    .p_align:  resq 1        ; Segment alignment
endstruc

; =============================================================================
; STRUCTURE: File Info
; Structure interne pour garder les infos sur un fichier
; =============================================================================
struc file_info
    .fd:          resd 1     ; File descriptor
    .size:        resq 1     ; Taille du fichier
    .mapped_addr: resq 1     ; Adresse mmap
    .is_elf64:    resb 1     ; 1 si c'est un ELF64 valide
    .is_infected: resb 1     ; 1 si déjà infecté
    .padding:     resw 1     ; Alignement
endstruc

; =============================================================================
; TAILLES DES STRUCTURES
; =============================================================================
%define DIRENT64_SIZE   linux_dirent64_size
%define ELF_EHDR_SIZE   Elf64_Ehdr_size
%define ELF_PHDR_SIZE   Elf64_Phdr_size
%define FILE_INFO_SIZE  file_info_size