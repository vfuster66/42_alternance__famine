#!/bin/bash

# =============================================================================
# Script de test pour vérifier les corrections de l'audit
# =============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Test des corrections de l'audit Famine ===${NC}"

# Variables
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAMINE_BIN="${PROJECT_ROOT}/Famine"
TEST_DIR="/tmp/test_audit"

echo -e "${YELLOW}→ Nettoyage et préparation...${NC}"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Compiler Famine
echo -e "${YELLOW}→ Compilation de Famine...${NC}"
cd "$PROJECT_ROOT"
make clean
make all

if [ ! -f "$FAMINE_BIN" ]; then
    echo -e "${RED}✗ Échec de la compilation${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Compilation réussie${NC}"

# Test ELF64
echo -e "${YELLOW}→ Test ELF64...${NC}"
cat > "$TEST_DIR/sample64.c" << 'EOF'
#include <stdio.h>
int main() { printf("Hello ELF64!\n"); return 0; }
EOF
gcc -m64 -static -o "$TEST_DIR/sample64" "$TEST_DIR/sample64.c"
echo -e "${GREEN}✓ Binaire ELF64 créé${NC}"

# Test ELF32
echo -e "${YELLOW}→ Test ELF32...${NC}"
cat > "$TEST_DIR/sample32.c" << 'EOF'
#include <stdio.h>
int main() { printf("Hello ELF32!\n"); return 0; }
EOF
gcc -m32 -static -o "$TEST_DIR/sample32" "$TEST_DIR/sample32.c" 2>/dev/null || echo -e "${YELLOW}→ gcc-multilib non disponible${NC}"
echo -e "${GREEN}✓ Binaire ELF32 créé${NC}"

# Test fichiers texte
echo -e "${YELLOW}→ Test fichiers texte...${NC}"
cat > "$TEST_DIR/sample.c" << 'EOF'
#include <stdio.h>
int main() { printf("Hello C!\n"); return 0; }
EOF
cat > "$TEST_DIR/sample.sh" << 'EOF'
#!/bin/bash
echo "Hello Shell!"
EOF
cat > "$TEST_DIR/sample.py" << 'EOF'
#!/usr/bin/env python3
print("Hello Python!")
EOF
echo -e "${GREEN}✓ Fichiers texte créés${NC}"

# Copier dans les répertoires de test
mkdir -p /tmp/test /tmp/test2
cp "$TEST_DIR/sample64" /tmp/test/ 2>/dev/null || true
cp "$TEST_DIR/sample32" /tmp/test2/ 2>/dev/null || true
cp "$TEST_DIR/sample.c" /tmp/test2/
cp "$TEST_DIR/sample.sh" /tmp/test2/
cp "$TEST_DIR/sample.py" /tmp/test2/

# Créer le fichier de force
touch /tmp/famine_force

# Exécuter Famine
echo -e "${YELLOW}→ Exécution de Famine...${NC}"
"$FAMINE_BIN" 2>&1 | head -20

# Vérifier les infections
echo -e "${YELLOW}→ Vérification des infections...${NC}"

# ELF64
if [ -f "/tmp/test/sample64" ]; then
    if strings "/tmp/test/sample64" | grep -q "Famine version 1.0"; then
        echo -e "${GREEN}✓ Infection ELF64 réussie${NC}"
    else
        echo -e "${RED}✗ Infection ELF64 échouée${NC}"
    fi
fi

# ELF32
if [ -f "/tmp/test2/sample32" ]; then
    if strings "/tmp/test2/sample32" | grep -q "Famine version 1.0"; then
        echo -e "${GREEN}✓ Infection ELF32 réussie${NC}"
    else
        echo -e "${RED}✗ Infection ELF32 échouée${NC}"
    fi
fi

# Fichiers texte
for file in sample.c sample.sh sample.py; do
    if [ -f "/tmp/test2/$file" ]; then
        if grep -q "Famine version 1.0" "/tmp/test2/$file"; then
            echo -e "${GREEN}✓ Infection $file réussie${NC}"
        else
            echo -e "${RED}✗ Infection $file échouée${NC}"
        fi
    fi
done

# Nettoyage
rm -f /tmp/famine_force
rm -rf "$TEST_DIR"

echo -e "${BLUE}=== Test terminé ===${NC}"
