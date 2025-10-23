# **************************************************************************** #
#                                                                              #
#    .gdbinit - Configuration GDB pour débugger Famine                        #
#                                                                              #
#    Usage: gdb -x .gdbinit ./Famine                                          #
#           ou copier dans ~/.gdbinit                                         #
#                                                                              #
# **************************************************************************** #

# Configuration de base
set disassembly-flavor intel
set pagination off
set print pretty on

# Breakpoints stratégiques
break _start
break process_directory
break process_file
break map_file
break check_elf64
break check_infected
break infect_binary

# ============================================================================
# COMMANDES PERSONNALISÉES
# ============================================================================

# Afficher l'état général
define status
    echo \n
    echo ========================================\n
    echo   État actuel du programme\n
    echo ========================================\n
    info frame
    echo \n
    info registers rax rbx rcx rdx rsi rdi r12 r13 r14 r15
    echo \n
end
document status
Affiche l'état général: frame, registres principaux
end

# Afficher la structure current_file
define show_current_file
    echo \n
    echo ========================================\n
    echo   Structure current_file\n
    echo ========================================\n
    printf "fd:          %d\n", *(int*)&current_file
    printf "size:        %ld\n", *(long*)((char*)&current_file + 8)
    printf "mapped_addr: 0x%lx\n", *(long*)((char*)&current_file + 16)
    printf "is_elf64:    %d\n", *(char*)((char*)&current_file + 24)
    printf "is_infected: %d\n", *(char*)((char*)&current_file + 25)
    echo \n
end
document show_current_file
Affiche le contenu de la structure current_file
end

# Afficher l'en-tête ELF pointé par rdi
define show_elf_header
    if $argc == 0
        set $addr = $rdi
    else
        set $addr = $arg0
    end
    
    echo \n
    echo ========================================\n
    echo   ELF Header\n
    echo ========================================\n
    printf "Magic:           %02x %c%c%c\n", *(char*)$addr, *((char*)$addr+1), *((char*)$addr+2), *((char*)$addr+3)
    printf "Class:           %d (", *((char*)$addr+4)
    if *((char*)$addr+4) == 1
        printf "32-bit)\n"
    else
        if *((char*)$addr+4) == 2
            printf "64-bit)\n"
        else
            printf "unknown)\n"
        end
    end
    printf "Type:            %d\n", *(short*)((char*)$addr+16)
    printf "Entry point:     0x%lx\n", *(long*)((char*)$addr+24)
    printf "Program headers: offset=0x%lx, count=%d\n", *(long*)((char*)$addr+32), *(short*)((char*)$addr+56)
    echo \n
end
document show_elf_header
Affiche l'en-tête ELF.
Usage: show_elf_header [adresse]
Sans argument, utilise $rdi
end

# Afficher un Program Header
define show_phdr
    if $argc == 0
        echo Usage: show_phdr <adresse>\n
    else
        set $addr = $arg0
        echo \n
        echo ========================================\n
        echo   Program Header\n
        echo ========================================\n
        printf "Type:     %d\n", *(int*)$addr
        printf "Flags:    0x%x\n", *(int*)((char*)$addr+4)
        printf "Offset:   0x%lx\n", *(long*)((char*)$addr+8)
        printf "Vaddr:    0x%lx\n", *(long*)((char*)$addr+16)
        printf "Filesz:   %ld\n", *(long*)((char*)$addr+32)
        printf "Memsz:    %ld\n", *(long*)((char*)$addr+40)
        echo \n
    end
end
document show_phdr
Affiche un Program Header ELF.
Usage: show_phdr <adresse>
end

# Chercher une string dans la mémoire mappée
define search_signature
    echo \n
    echo Recherche de la signature...\n
    set $addr = *(long*)((char*)&current_file + 16)
    set $size = *(long*)((char*)&current_file + 8)
    
    if $addr == 0
        echo Erreur: Aucun fichier mappé\n
    else
        find /b $addr, $addr+$size, 'F','a','m','i','n','e'
    end
    echo \n
end
document search_signature
Cherche la signature "Famine" dans le fichier mappé
end

# Dump hexadécimal d'une zone
define hexdump
    if $argc < 2
        echo Usage: hexdump <adresse> <taille>\n
    else
        set $addr = $arg0
        set $size = $arg1
        x/${size}bx $addr
    end
end
document hexdump
Affiche un dump hexadécimal.
Usage: hexdump <adresse> <taille>
end

# Suivre l'exécution d'une fonction
define trace_function
    if $argc == 0
        echo Usage: trace_function <nom_fonction>\n
    else
        break $arg0
        commands
            silent
            printf "→ Entrée dans %s\n", "$arg0"
            printf "  rdi=0x%lx rsi=0x%lx rdx=0x%lx\n", $rdi, $rsi, $rdx
            continue
        end
    end
end
document trace_function
Place un breakpoint traçant sur une fonction.
Usage: trace_function <nom_fonction>
end

# Afficher tous les registres
define regs
    echo \n
    echo ========================================\n
    echo   Registres\n
    echo ========================================\n
    printf "rax: 0x%016lx   rbx: 0x%016lx\n", $rax, $rbx
    printf "rcx: 0x%016lx   rdx: 0x%016lx\n", $rcx, $rdx
    printf "rsi: 0x%016lx   rdi: 0x%016lx\n", $rsi, $rdi
    printf "rbp: 0x%016lx   rsp: 0x%016lx\n", $rbp, $rsp
    printf "r8:  0x%016lx   r9:  0x%016lx\n", $r8, $r9
    printf "r10: 0x%016lx   r11: 0x%016lx\n", $r10, $r11
    printf "r12: 0x%016lx   r13: 0x%016lx\n", $r12, $r13
    printf "r14: 0x%016lx   r15: 0x%016lx\n", $r14, $r15
    printf "rip: 0x%016lx\n", $rip
    echo \n
end
document regs
Affiche tous les registres
end

# Afficher la stack
define stack
    if $argc == 0
        set $count = 16
    else
        set $count = $arg0
    end
    echo \n
    echo ========================================\n
    echo   Stack (top)\n
    echo ========================================\n
    x/${count}gx $rsp
    echo \n
end
document stack
Affiche la stack.
Usage: stack [nombre_de_qwords]
Par défaut: 16
end

# Continuer jusqu'au prochain syscall
define next_syscall
    catch syscall
    continue
    delete
end
document next_syscall
Continue jusqu'au prochain appel système
end

# Afficher les syscalls
define trace_syscalls
    catch syscall
    commands
        silent
        printf "SYSCALL: rax=%ld (", $rax
        if $rax == 0
            printf "read"
        end
        if $rax == 1
            printf "write"
        end
        if $rax == 2
            printf "open"
        end
        if $rax == 3
            printf "close"
        end
        if $rax == 9
            printf "mmap"
        end
        if $rax == 11
            printf "munmap"
        end
        if $rax == 217
            printf "getdents64"
        end
        printf ")\n"
        printf "  args: rdi=0x%lx rsi=0x%lx rdx=0x%lx\n", $rdi, $rsi, $rdx
        continue
    end
    continue
end
document trace_syscalls
Trace tous les appels système
end

# ============================================================================
# MESSAGES D'ACCUEIL
# ============================================================================

echo \n
echo ========================================================================\n
echo   Famine GDB Debug Session\n
echo ========================================================================\n
echo \n
echo Breakpoints définis:\n
echo   • _start, process_directory, process_file\n
echo   • map_file, check_elf64, check_infected, infect_binary\n
echo \n
echo Commandes disponibles:\n
echo   • status                - État général\n
echo   • regs                  - Tous les registres\n
echo   • stack [n]             - Stack (n qwords)\n
echo   • show_current_file     - Structure current_file\n
echo   • show_elf_header [addr]- En-tête ELF\n
echo   • show_phdr <addr>      - Program Header\n
echo   • search_signature      - Chercher la signature\n
echo   • trace_syscalls        - Tracer les syscalls\n
echo   • next_syscall          - Prochain syscall\n
echo \n
echo Lancez 'run' pour démarrer le debug\n
echo \n
echo ========================================================================\n
echo \n