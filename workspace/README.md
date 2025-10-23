# Famine - Virus Informatique

## Description

Famine est un virus informatique développé en assembleur x86-64 qui infecte les binaires ELF64 et ELF32 en ajoutant une signature. Le projet respecte strictement les exigences du sujet et implémente des fonctionnalités bonus avancées.

## Fonctionnalités

### Partie Obligatoire

- ✅ Infection des binaires ELF64
- ✅ Signature : `"Famine version 1.0 (c)oded by vfuster- and sdestann"`
- ✅ Cibles : `/tmp/test` et `/tmp/test2` uniquement
- ✅ Aucune sortie (furtivité)
- ✅ Infection unique par binaire

### Partie Bonus

- ✅ Support ELF32
- ✅ Infection de fichiers non-binaires (.c, .sh, .py, .txt, .js, .php)
- ✅ Système de packing avec compression LZ
- ✅ **Déclenchement conditionnel** (Bonus 2)

## Bonus 2 - Déclenchement Conditionnel

### Fonctionnement

Le virus ne s'active que si certaines conditions sont remplies :

1. **Hash du hostname** : Le hash du hostname doit correspondre à une valeur prédéfinie
2. **Plage horaire** : L'activation n'a lieu qu'entre 9h et 17h
3. **Variable d'environnement** : `FAMINE_FORCE=1` force l'activation pour le debug

### Configuration

La configuration se trouve dans `src/control.asm` :

```assembly
trigger_config:
    .hostname_hash:     dq 0x123456789ABCDEF0  ; Hash attendu du hostname
    .time_start:        db 9                    ; Heure de début (9h)
    .time_end:          db 17                   ; Heure de fin (17h)
    .force_env:         db "FAMINE_FORCE", 0    ; Variable d'environnement de debug
```

### Activation/Désactivation pendant la défense

#### Pour activer le virus :

```bash
# Méthode 1: Variable d'environnement (recommandée pour les tests)
export FAMINE_FORCE=1
./Famine

# Méthode 2: Modifier le hash du hostname
# Calculer le hash de votre hostname et modifier trigger_config.hostname_hash
# dans src/control.asm, puis recompiler

# Méthode 3: Exécuter entre 9h et 17h avec le bon hostname
./Famine
```

#### Pour désactiver le virus :

```bash
# Ne pas définir FAMINE_FORCE=1
# Exécuter en dehors de la plage horaire 9h-17h
# Utiliser un hostname différent
```

### Tests

Le script de test `scripts/test_condition.sh` permet de vérifier le fonctionnement :

```bash
# Exécuter tous les tests
./scripts/test_condition.sh

# Tests inclus :
# - Condition normale (sans FAMINE_FORCE)
# - Force avec FAMINE_FORCE=1
# - Tests avec Docker (environnement différent)
```

### Modification du Hash du Hostname

Pour calculer le hash de votre hostname :

```bash
# Obtenir le hostname
hostname

# Calculer le hash (script Python simple)
python3 -c "
import sys
hostname = sys.argv[1]
hash_val = 0
for char in hostname:
    hash_val = hash_val * 31 + ord(char)
print(f'Hash: 0x{hash_val:016X}')
" $(hostname)
```

Puis modifier `trigger_config.hostname_hash` dans `src/control.asm` avec la valeur calculée.

## Compilation

```bash
# Compilation standard
make clean && make all

# Tests
make test

# Tests du déclenchement conditionnel
./scripts/test_condition.sh
```

## Structure du Code

```
src/
├── famine.asm      # Point d'entrée principal
├── control.asm     # Déclenchement conditionnel (Bonus 2)
├── elf_check.asm   # Vérification des formats ELF
├── infect.asm      # Infection ELF64
├── infect32.asm    # Infection ELF32 (bonus)
├── file_ops.asm    # Opérations sur les fichiers
└── handlers.asm    # Gestion des fichiers non-binaires (bonus)
```

## Sécurité

⚠️ **ATTENTION** : Ce projet est destiné à des fins éducatives uniquement. L'utilisation de ce code à des fins malveillantes est strictement interdite.

- Utilisez uniquement dans un environnement virtuel isolé
- Ne jamais exécuter sur un système de production
- Respectez les lois locales sur la cybersécurité

## Auteurs

- vfuster-
- sdestann

## Licence

Projet éducatif - 42 School
