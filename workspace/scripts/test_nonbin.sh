#!/bin/bash

# =============================================================================
# test_nonbin.sh - Test d'infection des fichiers non-binaires
# =============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Répertoires de test
TEST_DIR="/tmp/test_nonbin"
ORIG_DIR="$TEST_DIR/original"
INFECT_DIR="/tmp/test2"  # Utiliser le répertoire que Famine traite

# Déterminer la racine du projet et le chemin du binaire Famine
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FAMINE_BIN="${PROJECT_ROOT}/Famine"

echo -e "${BLUE}=== Test d'infection des fichiers non-binaires ===${RESET}"

# Nettoyer les répertoires existants
rm -rf "$TEST_DIR"
mkdir -p "$ORIG_DIR"

# Nettoyer uniquement nos fichiers de test dans /tmp/test2
mkdir -p "$INFECT_DIR"
rm -f "$INFECT_DIR"/sample.{c,sh,py,js,php,txt}

# Créer les fichiers de test
echo -e "${YELLOW}Création des fichiers de test...${RESET}"

# Fichier C
cat > "$ORIG_DIR/sample.c" << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from C!\n");
    return 0;
}
EOF

# Fichier Shell
cat > "$ORIG_DIR/sample.sh" << 'EOF'
#!/bin/bash
echo "Hello from Shell!"
EOF

# Fichier Python
cat > "$ORIG_DIR/sample.py" << 'EOF'
#!/usr/bin/env python3
print("Hello from Python!")
EOF

# Fichier JavaScript
cat > "$ORIG_DIR/sample.js" << 'EOF'
#!/usr/bin/env node
console.log("Hello from JavaScript!");
EOF

# Fichier PHP
cat > "$ORIG_DIR/sample.php" << 'EOF'
<?php
echo "Hello from PHP!\n";
?>
EOF

# Fichier texte
cat > "$ORIG_DIR/sample.txt" << 'EOF'
Hello from text file!
This is a simple text file.
EOF

# Copier les fichiers originaux dans /tmp/test2
cp "$ORIG_DIR"/* "$INFECT_DIR/"

# Créer le fichier de force pour activer Famine
touch /tmp/famine_force

echo -e "${YELLOW}Exécution de Famine...${RESET}"

# Vérifier que le binaire Famine est disponible
if [ ! -x "$FAMINE_BIN" ]; then
    echo -e "${RED}✗ Binaire Famine introuvable (${FAMINE_BIN})${RESET}"
    exit 127
fi

# Exécuter Famine sur le répertoire infecté
pushd "$PROJECT_ROOT" >/dev/null
echo -e "${BLUE}=== Logs de debug Famine ===${RESET}"
echo "Fichiers dans /tmp/test2:"
ls -la /tmp/test2/
echo "Fichier de force:"
ls -la /tmp/famine_force
"$FAMINE_BIN" 2>&1
echo -e "${BLUE}=== Fin des logs ===${RESET}"
popd >/dev/null

echo -e "${YELLOW}Vérification des infections...${RESET}"

# Vérifier chaque fichier
for file in sample.c sample.sh sample.py sample.js sample.php sample.txt; do
    echo -e "${BLUE}Vérification de $file:${RESET}"
    
    if [ -f "$ORIG_DIR/$file" ] && [ -f "$INFECT_DIR/$file" ]; then
        # Vérifier la présence de la signature
        if grep -q "Famine version 1.0" "$INFECT_DIR/$file"; then
            echo -e "  ${GREEN}✓ Signature trouvée${RESET}"
        else
            echo -e "  ${RED}✗ Signature non trouvée${RESET}"
        fi
        
        # Afficher les différences
        echo -e "  ${YELLOW}Différences:${RESET}"
        diff -u "$ORIG_DIR/$file" "$INFECT_DIR/$file" || true
        echo
    else
        echo -e "  ${RED}✗ Fichier manquant${RESET}"
    fi
done

# Test d'exécution des scripts infectés
echo -e "${YELLOW}Test d'exécution des scripts infectés...${RESET}"

# Test du script shell
if [ -f "$INFECT_DIR/sample.sh" ]; then
    echo -e "${BLUE}Exécution du script shell infecté:${RESET}"
    chmod +x "$INFECT_DIR/sample.sh"
    "$INFECT_DIR/sample.sh" || echo -e "  ${RED}✗ Échec d'exécution${RESET}"
    echo
fi


# Compilation et test du fichier C
if [ -f "$INFECT_DIR/sample.c" ]; then
    echo -e "${BLUE}Compilation et exécution du fichier C infecté:${RESET}"
    gcc -o "$INFECT_DIR/sample_c" "$INFECT_DIR/sample.c"
    "$INFECT_DIR/sample_c" || echo -e "  ${RED}✗ Échec d'exécution${RESET}"
    echo
fi

echo -e "${GREEN}=== Test terminé ===${RESET}"

# Afficher le contenu d'un fichier pour debug
echo -e "${YELLOW}Contenu du fichier C après infection:${RESET}"
cat "$INFECT_DIR/sample.c" || echo "Fichier non trouvé"
echo
echo -e "${YELLOW}Hexdump du fichier C (derniers 100 octets):${RESET}"
tail -c 100 "$INFECT_DIR/sample.c" | od -A x -t x1z -v || echo "Erreur hexdump"

# Nettoyer
rm -rf "$TEST_DIR"
