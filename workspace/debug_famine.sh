#!/bin/bash

echo "=== Debug Famine ==="
echo ""

echo "1. Vérification des répertoires:"
ls -la /tmp/test/ 2>/dev/null || echo "  /tmp/test n'existe pas"
ls -la /tmp/test2/ 2>/dev/null || echo "  /tmp/test2 n'existe pas"
echo ""

echo "2. Type des fichiers:"
for f in /tmp/test/* /tmp/test2/*; do
    [ -f "$f" ] && echo "  $(basename $f): $(file $f | cut -d: -f2)"
done
echo ""

echo "3. Avant infection:"
strings /tmp/test/sample 2>/dev/null | grep -i famine && echo "  Déjà infecté!" || echo "  Pas encore infecté"
echo ""

echo "4. Exécution avec strace (premiers appels):"
strace -e trace=open,openat,getdents64 ./Famine 2>&1 | head -20
echo ""

echo "5. Après infection:"
strings /tmp/test/sample 2>/dev/null | grep -i famine && echo "  INFECTÉ ✓" || echo "  PAS INFECTÉ ✗"
echo ""

echo "6. Test d'exécution du binaire:"
/tmp/test/sample 2>&1 || echo "  Erreur d'exécution"