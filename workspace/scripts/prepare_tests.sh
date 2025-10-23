
#!/bin/bash
# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    prepare_tests                                      :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/10/13 14:07:12 by sdestann          #+#    #+#              #
#    Updated: 2025/10/14 20:08:19 by sdestann         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

set -e

echo "🔧 Préparation de l'environnement de test..."

# Créer les répertoires de test
mkdir -p /tmp/test /tmp/test2

# Créer un programme C simple pour les tests
cat > /tmp/sample.c << 'EOF'
#include <stdio.h>

int main(void) {
    printf("Hello, World!\n");
    return 0;
}
EOF

# Compiler le programme de test
echo "📦 Compilation des binaires de test..."
gcc -m64 /tmp/sample.c -o /tmp/test/sample
gcc -m64 /tmp/sample.c -o /tmp/test2/sample

# Créer un autre programme plus complexe
cat > /tmp/complex.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int add(int a, int b) {
    return a + b;
}

int multiply(int a, int b) {
    return a * b;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <num1> <num2>\n", argv[0]);
        return 1;
    }
    
    int a = atoi(argv[1]);
    int b = atoi(argv[2]);
    
    printf("Addition: %d + %d = %d\n", a, b, add(a, b));
    printf("Multiplication: %d * %d = %d\n", a, b, multiply(a, b));
    
    return 0;
}
EOF

gcc -m64 /tmp/complex.c -o /tmp/test/calc
gcc -m64 /tmp/complex.c -o /tmp/test2/calc

# Copier quelques binaires système (si disponibles)
if [ -f /bin/ls ]; then
    cp /bin/ls /tmp/test/ls 2>/dev/null || true
fi

if [ -f /usr/bin/file ]; then
    cp /usr/bin/file /tmp/test2/file 2>/dev/null || true
fi

echo "✅ Tests préparés:"
echo ""
echo "📁 /tmp/test:"
ls -lh /tmp/test/ 2>/dev/null || echo "  (vide)"
echo ""
echo "📁 /tmp/test2:"
ls -lh /tmp/test2/ 2>/dev/null || echo "  (vide)"
echo ""
echo "🔍 Vérification des binaires:"
file /tmp/test/* 2>/dev/null || true
echo ""
echo "✨ Prêt pour les tests!"