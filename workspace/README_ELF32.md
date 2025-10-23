# 🎯 Support ELF32 - Bonus Famine

## 📋 Vue d'ensemble

Ce bonus ajoute le support des binaires ELF32 à Famine, permettant l'infection de programmes 32 bits en plus des programmes 64 bits existants.

## 🏗️ Architecture

### Structures ajoutées

- **`Elf32_Ehdr`** : En-tête ELF32 (52 octets)
- **`Elf32_Phdr`** : Program Header ELF32 (32 octets)
- **`file_info.format`** : Champ pour identifier le format (UNKNOWN/ELF32/ELF64)

### Fonctions ajoutées

- **`check_elf32`** : Détection des binaires ELF32
- **`check_elf_format`** : Dispatcher pour ELF32/ELF64
- **`infect_elf32`** : Infection des binaires ELF32
- **`memcpy_32`** : Copie mémoire optimisée pour ELF32

## 🔧 Implémentation

### 1. Détection automatique du format

```asm
; Dispatcher dans process_file
call check_elf_format
mov al, [current_file + file_info.format]
cmp al, FORMAT_ELF32
je .infect_elf32
cmp al, FORMAT_ELF64
je .infect_elf64
```

### 2. Infection ELF32

Méthode simple par **append** à la fin du fichier :

```asm
; Calculer la nouvelle taille
mov rax, r13
add rax, [sig_len]

; Copier la signature à la fin
lea rdi, [r12 + r13]        ; Destination
mov rsi, signature          ; Source
mov rcx, [sig_len]          ; Taille
call memcpy_32
```

### 3. Vérifications ELF32

- Magic number ELF (0x7f 'E' 'L' 'F')
- Classe ELF32 (byte 4 = 1)
- Endianness little-endian
- Type exécutable ou shared object

## 🧪 Tests

### Script de test ELF32

```bash
./scripts/test_elf32.sh
```

### Script de test complet

```bash
./scripts/test_all_formats.sh
```

### Compilation ELF32

```bash
# Compiler un programme de test
gcc -m32 -static -o sample32 sample32.c

# Vérifier le format
readelf -h sample32 | grep "Class:.*ELF32"

# Exécuter avec qemu-i386
qemu-i386 sample32
```

## 🐳 Docker

Le Dockerfile a été mis à jour pour inclure `gcc-multilib` :

```dockerfile
RUN apt-get install -y --no-install-recommends \
    build-essential \
    nasm \
    gcc \
    gcc-multilib \  # ← Nouveau
    make \
    # ...
```

## 📊 Résultats attendus

### Avant infection

```
$ file sample32
sample32: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), statically linked, not stripped

$ strings sample32
Hello from ELF32!
This is a 32-bit executable.
```

### Après infection

```
$ strings sample32
Hello from ELF32!
This is a 32-bit executable.
Famine version 1.0 (c)oded by vfuster- and sdestann
```

### Vérification de l'exécutabilité

```
$ qemu-i386 sample32
Hello from ELF32!
This is a 32-bit executable.
```

## 🔍 Détails techniques

### Différences ELF32 vs ELF64

| Aspect             | ELF32     | ELF64     |
| ------------------ | --------- | --------- |
| **En-tête**        | 52 octets | 64 octets |
| **Adresses**       | 32 bits   | 64 bits   |
| **Program Header** | 32 octets | 56 octets |
| **Entry point**    | 32 bits   | 64 bits   |

### Limites ELF32

- **Taille maximale** : 2^32 - 1 octets
- **Adresses virtuelles** : 32 bits
- **Segments** : Limités par l'espace d'adressage 32 bits

### Méthode d'infection

La méthode **append** est choisie pour sa simplicité et sa fiabilité :

1. ✅ **Simple** : Ajout à la fin du fichier
2. ✅ **Sûre** : Pas de modification des segments existants
3. ✅ **Compatible** : Fonctionne avec tous les binaires ELF32
4. ✅ **Prévisible** : Comportement inchangé garanti

## 🚀 Utilisation

### Compilation

```bash
make clean && make all
```

### Test

```bash
# Test ELF32 uniquement
./scripts/test_elf32.sh

# Test complet (ELF32 + ELF64)
./scripts/test_all_formats.sh
```

### Exécution

```bash
# Famine infecte automatiquement ELF32 et ELF64
./Famine /tmp/test
```

## 📈 Bénéfices

1. **Support complet** : ELF32 et ELF64
2. **Détection automatique** : Aucune intervention manuelle
3. **Compatibilité** : Binaires restent exécutables
4. **Robustesse** : Méthode d'infection sûre
5. **Extensibilité** : Architecture modulaire

## 🎯 Conformité

- ✅ **Format de signature** : Respecté
- ✅ **Comportement inchangé** : Garanti
- ✅ **Mode silencieux** : Préservé
- ✅ **Support multi-format** : Implémenté

Le support ELF32 est maintenant **pleinement fonctionnel** et prêt pour la production ! 🎉
