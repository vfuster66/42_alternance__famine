#!/bin/bash

# =============================================================================
# Script de test pour les logs de debug des fichiers non-binaires
# =============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_header "Test des logs de debug pour les fichiers non-binaires"

# Vérifier que Famine est compilé
if [ ! -f "./Famine" ]; then
    print_error "Famine non trouvé. Compilation nécessaire."
    make clean && make all
fi

# Créer l'environnement de test
print_info "Création de l'environnement de test..."
mkdir -p /tmp/test2

# Créer des fichiers texte de test
print_info "Création des fichiers texte de test..."

# Fichier C
cat > /tmp/test2/sample.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from C!\n");
    return 0;
}
EOF

# Fichier Python
cat > /tmp/test2/sample.py << 'EOF'
#!/usr/bin/env python3

def main():
    print("Hello from Python!")

if __name__ == "__main__":
    main()
EOF

# Fichier Shell
cat > /tmp/test2/sample.sh << 'EOF'
#!/bin/bash

echo "Hello from Shell!"
EOF

# Fichier JavaScript
cat > /tmp/test2/sample.js << 'EOF'
console.log("Hello from JavaScript!");
EOF

# Fichier PHP
cat > /tmp/test2/sample.php << 'EOF'
<?php
echo "Hello from PHP!\n";
?>
EOF

# Fichier texte
cat > /tmp/test2/sample.txt << 'EOF'
Hello from text file!
EOF

print_success "Fichiers texte créés"

# Créer le fichier de force
print_info "Création du fichier de force..."
touch /tmp/famine_force

# Exécuter Famine avec les logs de debug
print_info "Exécution de Famine avec logs de debug..."
echo "=== Sortie de Famine ==="
./Famine
echo "=== Fin de la sortie de Famine ==="

# Supprimer le fichier de force
rm -f /tmp/famine_force

# Vérifier l'infection
print_info "Vérification de l'infection..."
for file in /tmp/test2/sample.*; do
    if [ -f "$file" ]; then
        echo ""
        echo "Fichier: $(basename $file)"
        if strings "$file" | grep -q "Famine"; then
            print_success "Infection réussie !"
            strings "$file" | grep "Famine"
        else
            print_error "Pas d'infection"
        fi
    fi
done

# Nettoyer
print_info "Nettoyage..."
rm -rf /tmp/test2

print_header "Test terminé"
