# Famine - Projet éducatif d'injection de code

## ⚠️ Avertissement

Ce projet est **strictement éducatif** et doit être exécuté **uniquement dans un environnement isolé** (VM, conteneur Docker). 

**Ne jamais exécuter ce code sur un système de production ou sur des fichiers non destinés aux tests.**

## 📋 Description

Famine est un programme assembleur x86-64 qui démontre les concepts suivants :
- Manipulation de binaires ELF64
- Parcours de système de fichiers
- Mapping mémoire (mmap)
- Injection de signature dans des exécutables
- Appels système Linux bas niveau

Le programme injecte une signature textuelle dans les binaires ELF64 présents dans `/tmp/test` et `/tmp/test2` sans altérer leur comportement.

## 🏗️ Architecture du projet

```
workspace/
├── src/
│   ├── famine.asm       # Point d'entrée et orchestration
│   ├── file_ops.asm     # Opérations fichiers (mmap/munmap)
│   ├── elf_check.asm    # Vérification et analyse ELF
│   └── infect.asm       # Logique d'injection
├── include/
│   ├── macros.inc       # Macros et constantes
│   └── structures.inc   # Structures de données
├── test/
│   └── sample.c         # Programme de test simple
├── build/               # Fichiers compilés
├── Makefile            # Build automation
└── README.md           # Ce fichier
```

## 🔧 Compilation

### Dans le conteneur Docker

```bash
# Lancer le conteneur
make

# Entrer dans le shell
make shell

# Dans le conteneur :
cd /workspace/workspace
make all
```

## 🧪 Tests

### Préparation automatique

```bash
make prepare-test          # Prépare l'environnement
make run-test      # Exécute un test complet
```

### Test manuel

```bash
# 1. Préparer les répertoires
mkdir -p /tmp/test /tmp/test2

# 2. Compiler un programme de test
gcc -m64 test/sample.c -o /tmp/test/sample

# 3. Vérifier avant infection
/tmp/test/sample
strings /tmp/test/sample | grep -i famine

# 4. Exécuter Famine
./Famine

# 5. Vérifier après infection
strings /tmp/test/sample | grep -i famine
/tmp/test/sample   # Le programme doit toujours fonctionner
```

## 📊 Inspection

```bash
# Informations sur le binaire
make inspect

# Désassemblage
make objdump

# Contenu hexadécimal
make hexdump
```

## 🎯 Fonctionnement

### 1. Énumération des fichiers
- Parcours de `/tmp/test` et `/tmp/test2`
- Utilisation de `getdents64` pour lister les entrées

### 2. Vérification des binaires
- Validation du magic number ELF (`0x7f 'E' 'L' 'F'`)
- Vérification de l'architecture (64 bits)
- Détection des fichiers déjà infectés

### 3. Injection de la signature
Deux méthodes sont implémentées :

**Méthode 1 : Réutilisation de segment PT_NOTE**
- Recherche d'un segment PT_NOTE
- Conversion en PT_LOAD
- Injection de la signature

**Méthode 2 : Append**
- Ajout de la signature en fin de fichier

### 4. Garanties
- Comportement original préservé
- Pas de corruption de binaire
- Pas de sortie (mode silencieux)
- Une seule infection par binaire

## 🔍 Détails techniques

### Appels système utilisés
- `open(2)` - Ouverture de fichiers/répertoires
- `close(3)` - Fermeture de descripteurs
- `getdents64(2)` - Énumération de répertoires
- `mmap(2)` - Mapping mémoire
- `munmap(2)` - Démapping mémoire
- `lseek(2)` - Positionnement dans un fichier
- `write(2)` - Écriture (méthode append)
- `exit(60)` - Terminaison

### Format ELF64
Le programme manipule les structures suivantes :
- `Elf64_Ehdr` - En-tête ELF principal
- `Elf64_Phdr` - Program Headers (segments)
- Segments PT_LOAD, PT_NOTE

### Signature
```
Famine version 1.0 (c)oded by vfuster- and sdestann
```

## 🧹 Nettoyage

```bash
make clean       # Nettoie les objets
make fclean      # Nettoie tout
make clean-test  # Nettoie l'environnement de test
```

## 📚 Ressources

- [ELF Format Specification](https://refspecs.linuxfoundation.org/elf/elf.pdf)
- [Linux System Calls](https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)
- [NASM Documentation](https://www.nasm.us/doc/)
- [Intel x86-64 Reference](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)

## ⚖️ Considérations éthiques

Ce projet est conçu à des fins **strictement pédagogiques** pour comprendre :
- Le format ELF
- L'assembleur x86-64
- Les appels système Linux
- Les concepts de sécurité informatique

**Ne jamais utiliser ce code à des fins malveillantes.**

## 📝 Licence

Projet éducatif - 42 School

## 👤 Auteurs

vfuster- and sdestann