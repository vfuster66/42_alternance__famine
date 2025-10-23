#!/bin/bash
# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    debug_helper                                       :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/10/13 14:07:12 by sdestann          #+#    #+#              #
#    Updated: 2025/10/14 20:08:19 by sdestann         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

set -e

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

echo -e "${COLOR_BLUE}═══════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_BLUE}     Famine Debug Helper${COLOR_RESET}"
echo -e "${COLOR_BLUE}═══════════════════════════════════════════════════${COLOR_RESET}"
echo ""

# Fonction pour afficher une section
section() {
    echo -e "${COLOR_YELLOW}▶ $1${COLOR_RESET}"
}

# Fonction pour afficher un succès
success() {
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $1"
}

# Fonction pour afficher une erreur
error() {
    echo -e "  ${COLOR_RED}✗${COLOR_RESET} $1"
}

# Fonction pour afficher une info
info() {
    echo -e "  ${COLOR_BLUE}ℹ${COLOR_RESET} $1"
}

# Vérifier si Famine existe
section "1. Vérification du binaire Famine"
if [ -f "./Famine" ]; then
    success "Famine trouvé"
    info "Taille: $(ls -lh ./Famine | awk '{print $5}')"
    info "Type: $(file ./Famine | cut -d: -f2)"
else
    error "strace non disponible"
fi

echo ""

# Vérifier les infections
section "6. Vérification des infections"
echo ""
infected_count=0
total_count=0

for dir in /tmp/test /tmp/test2; do
    if [ -d "$dir" ]; then
        for file in "$dir"/*; do
            if [ -f "$file" ] && [ -x "$file" ]; then
                total_count=$((total_count + 1))
                if strings "$file" 2>/dev/null | grep -qi "famine"; then
                    infected_count=$((infected_count + 1))
                    success "$(basename $file) - INFECTÉ"
                else
                    info "$(basename $file) - Non infecté"
                fi
            fi
        done
    fi
done

echo ""
info "Résumé: $infected_count/$total_count binaires infectés"

echo ""

# Analyse hexadécimale
section "7. Analyse hexadécimale d'un binaire infecté"
sample_file=""
for dir in /tmp/test /tmp/test2; do
    if [ -d "$dir" ]; then
        for file in "$dir"/*; do
            if [ -f "$file" ] && strings "$file" 2>/dev/null | grep -qi "famine"; then
                sample_file="$file"
                break 2
            fi
        done
    fi
done

if [ -n "$sample_file" ]; then
    info "Fichier analysé: $(basename $sample_file)"
    echo ""
    echo "  Recherche de la signature:"
    hexdump -C "$sample_file" | grep -A2 -B2 "Famine" | head -10 || echo "  Signature non trouvée en hex"
else
    error "Aucun binaire infecté trouvé pour l'analyse"
fi

echo ""

# Proposer des actions
section "8. Actions disponibles"
echo ""
echo "  Commandes utiles:"
echo ""
echo "  • Recompiler:        make re"
echo "  • Debug avec GDB:    make gdb"
echo "  • Nettoyer tests:    make clean-test"
echo "  • Préparer tests:    make test"
echo "  • Désassembler:      objdump -d -M intel ./Famine | less"
echo "  • Voir sections:     readelf -S ./Famine"
echo "  • Voir segments:     readelf -l ./Famine"
echo "  • Tracer syscalls:   strace ./Famine"
echo ""

# GDB script helper
section "9. Helper GDB"
info "Créer un script GDB automatique..."

cat > /tmp/famine_gdb.cmd << 'EOF'
# Script GDB pour débugger Famine

# Configuration
set disassembly-flavor intel
set pagination off

# Breakpoints utiles
break _start
break process_directory
break process_file
break check_elf64
break infect_binary

# Commandes personnalisées
define show_regs
    info registers rax rbx rcx rdx rsi rdi
end

define show_stack
    x/16gx $rsp
end

define show_elf_header
    x/16gx $rdi
end

# Messages
echo \n
echo ========================================\n
echo   Famine Debug Session\n
echo ========================================\n
echo \n
echo Breakpoints définis:\n
echo   • _start\n
echo   • process_directory\n
echo   • process_file\n
echo   • check_elf64\n
echo   • infect_binary\n
echo \n
echo Commandes utiles:\n
echo   • show_regs  : Afficher les registres\n
echo   • show_stack : Afficher la stack\n
echo   • show_elf_header : Afficher l'en-tête ELF\n
echo \n
echo Lancez 'run' pour démarrer\n
echo \n
EOF

success "Script GDB créé: /tmp/famine_gdb.cmd"
info "Usage: gdb -x /tmp/famine_gdb.cmd ./Famine"

echo ""

# Tests recommandés
section "10. Tests recommandés"
echo ""
echo "  Test 1: Infection simple"
echo "    $ make clean-test && make test"
echo "    $ ./Famine"
echo "    $ strings /tmp/test/sample | grep Famine"
echo ""
echo "  Test 2: Double infection"
echo "    $ ./Famine"
echo "    $ ./Famine  # Ne doit PAS réinfecter"
echo ""
echo "  Test 3: Comportement préservé"
echo "    $ /tmp/test/sample  # Doit afficher 'Hello, World!'"
echo ""
echo "  Test 4: Avec strace"
echo "    $ strace -e trace=open,getdents64,mmap ./Famine"
echo ""
echo "  Test 5: Binaires système"
echo "    $ cp /bin/ls /tmp/test/"
echo "    $ ./Famine"
echo "    $ /tmp/test/ls -la"
echo ""

# Checklist de debug
section "11. Checklist de debug"
echo ""
checks=(
    "Les répertoires /tmp/test et /tmp/test2 existent"
    "Des binaires ELF64 sont présents dans ces répertoires"
    "Famine compile sans erreur"
    "Famine s'exécute sans segfault"
    "Les binaires sont bien marqués comme infectés"
    "Les binaires infectés s'exécutent correctement"
    "Une double infection ne modifie pas le binaire"
    "Aucune sortie sur stdout/stderr"
)

for check in "${checks[@]}"; do
    echo "  ☐ $check"
done

echo ""
echo -e "${COLOR_BLUE}═══════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}Debug helper terminé !${COLOR_RESET}"
echo -e "${COLOR_BLUE}═══════════════════════════════════════════════════${COLOR_RESET}"
echo "" "Famine non trouvé. Compilez d'abord avec 'make'"
    exit 1
fi

echo ""

# Vérifier les répertoires de test
section "2. Vérification de l'environnement"
for dir in /tmp/test /tmp/test2; do
    if [ -d "$dir" ]; then
        success "$dir existe"
        info "Contenu: $(ls $dir 2>/dev/null | wc -l) fichier(s)"
    else
        error "$dir n'existe pas"
        info "Créez-le avec: mkdir -p $dir"
    fi
done

echo ""

# Analyser les binaires de test
section "3. Analyse des binaires de test"
for dir in /tmp/test /tmp/test2; do
    if [ -d "$dir" ]; then
        echo -e "  📁 $dir:"
        for file in "$dir"/*; do
            if [ -f "$file" ] && [ -x "$file" ]; then
                echo -e "    • $(basename $file)"
                
                # Vérifier si c'est un ELF
                if file "$file" | grep -q "ELF 64-bit"; then
                    info "    → ELF 64-bit ✓"
                elif file "$file" | grep -q "ELF 32-bit"; then
                    info "    → ELF 32-bit (non supporté actuellement)"
                else
                    error "    → Pas un ELF"
                fi
                
                # Vérifier si déjà infecté
                if strings "$file" 2>/dev/null | grep -qi "famine"; then
                    success "    → Déjà infecté"
                else
                    info "    → Non infecté"
                fi
                
                # Tester l'exécution
                if timeout 1 "$file" >/dev/null 2>&1; then
                    success "    → Exécutable"
                else
                    error "    → Problème d'exécution"
                fi
            fi
        done
    fi
done

echo ""

# Vérifier les symboles de Famine
section "4. Symboles et sections de Famine"
info "Sections:"
readelf -S ./Famine | grep -E "\[.*\]" | head -10

echo ""
info "Symboles principaux:"
nm ./Famine 2>/dev/null | grep -E "(start|process|infect|check)" | head -10

echo ""

# Tester les appels système
section "5. Test d'exécution avec strace (aperçu)"
info "Lancement de Famine avec strace..."
if command -v strace >/dev/null 2>&1; then
    strace -c -o /tmp/famine_strace.log ./Famine 2>/dev/null || true
    if [ -f /tmp/famine_strace.log ]; then
        echo ""
        info "Résumé des syscalls:"
        cat /tmp/famine_strace.log | head -20
        rm -f /tmp/famine_strace.log
    fi
else
    error