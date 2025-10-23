# Guide de conception — Assembleur (principes et patterns, usage pédagogique)

> Objectif : fournir une méthodologie propre, maintenable et modulaire pour développer des projets bas‑niveaux en assembleur (éducation, bootloaders, loaders, utilitaires systèmes non‑invasifs), en s’inspirant des design patterns. Le guide **évite toute instruction permettant la création, propagation ou modification malveillante de binaires**.

---

## 1. Introduction

L’assembleur impose des contraintes (pas d’objets, gestion explicite de la mémoire, appels système bas‑niveau). Cela n’empêche pas d’appliquer des **principes de conception** éprouvés : séparation des responsabilités, abstraction via routines bien nommées, factorisation, documentation et tests.

Ce guide donne :

* des patterns conceptuels transposables en ASM ;
* des règles d’organisation de projet ;
* des conventions de code et macros utiles ;
* des pratiques de test, debug et revue de code ;
* une checklist éthique et de sécurité.

---

## 2. Principes généraux (KISS, SRP, YAGNI)

* **KISS** (Keep It Simple, Stupid) : privilégier des routines courtes, lisibles et testables.
* **SRP** (Single Responsibility Principle) : une routine = une responsabilité claire (ex : parsing d’un en‑tête, formatage de sortie, calcul d’un checksum).
* **YAGNI** (You Aren’t Gonna Need It) : n’ajoute pas des abstractions complexes tant que le besoin réel n’est pas prouvé.
* **Interfaces explicites** : documenter les registres utilisés pour les paramètres, la convention d’appel, et les effets secondaires (flags, écriture mémoire).

---

## 3. Transposer des design patterns en assembleur (conceptuel)

> Rappel : on parle ici de **transposition conceptuelle** — pas d’implémentations qui manipulent des programmes tiers.

### 3.1 Singleton (état global contrôlé)

* But : garantir une unique zone d’état réutilisable (ex : table de configuration, buffer d’options).
* Mise en œuvre : réserver une variable en `.data`/`.bss` et documenter le protocole d’initialisation / vérification.
* Bonnes pratiques : protéger l’accès (flag d’initialisation) et toujours vérifier l’état avant utilisation.

### 3.2 Facade

* But : fournir une routine haute‑niveau qui encapsule une séquence d’étapes complexes.
* En ASM : écrire une routine `main_routine` qui appelle `_init`, `_process`, `_cleanup` — chaque routine reste testable seule.

### 3.3 Strategy

* But : pouvoir choisir dynamiquement la méthode à exécuter.
* En ASM : utiliser une **jump table** (table d’adresses) ou des `cmp` + `jmp` pour rediriger vers la stratégie choisie.

### 3.4 Template Method

* But : définir un squelette d’algorithme, avec des étapes spécifiques déléguées à des sous‑routines.
* En ASM : implémenter une routine `squelette` qui effectue les vérifications communes puis appelle `step1`, `step2` — qui peuvent être remplacées.

### 3.5 Factory (fabrique légère)

* But : sélectionner et retourner l’adresse d’une routine adaptée à un contexte.
* En ASM : routine `get_handler` qui renvoie une adresse via registre (p.ex. `rax`) ou qui effectue un `jmp` indirect.

### 3.6 State

* But : comportement variant selon l’état courant.
* En ASM : stocker un code d’état en mémoire et faire `cmp`/`jmp` pour le dispatcher.

---

## 4. Organisation du projet (fichiers et modules)

Structure recommandée (exemple pédagogique) :

```
project/
├── src/
│   ├── entry.asm        # point d’entrée, orchestration
│   ├── syscalls.asm     # wrappers sûrs autour d'appels système pour debug
│   ├── utils.asm        # routines utilitaires réutilisables
│   ├── parser.asm       # parsing d'entêtes / formats (lecture sûre en mémoire)
│   ├── processing.asm   # logique métier non invasive
│   └── macros.inc       # macros et conventions
├── test/                # tests unitaires / scripts QEMU
├── build/               # artefacts (binaires, maps)
├── Makefile
└── README.md
```

> Principe : séparer le code en unités logiques faciles à relire et tester.

---

## 5. Conventions de code (lisibilité & maintenance)

* **Nommer les routines** avec un préfixe (ex : `util_`, `parse_`, `proc_`) ;
* **Prologue / épilogue standardisés** : sauvegarde/restauration des registres utilisés ;
* **Documenter** : commentaire en tête de routine décrivant paramètres (registres), renvoyé et effets secondaires ;
* **Limiter les registres modifiés** : respecter la convention d’appel que tu choisis (System V, ou autre selon cible) ;
* **Macros** : factoriser les motifs répétitifs (push/pop pairs, checks, logs de debug) dans `macros.inc` ;
* **Formatage** : indentation, colonnes pour labels, instructions et commentaires.

Exemple de header de routine (template, sans code sensible) :

```
; ------------------------------------------------------------------
; parse_header
; Params: rdi -> adresse buffer, rsi -> taille
; Returns: rax = 0 on success, <0 on error
; Side effects: aucune zone globale modifiée
; ------------------------------------------------------------------
```

---

## 6. Macros et snippets utiles (génériques)

Dans `macros.inc` :

* `PUSH_CALLEE_SAVE` / `POP_CALLEE_SAVE` pour sauvegarder les registres callee‑saved ;
* `CHECK_NULL` pour effectuer un contrôle d’argument et retourner une erreur propre ;
* `TRACE_ENTER` / `TRACE_EXIT` pour instrumentation (activable via macro conditionnelle) — utile en dev, désactivé en build release.

Ces macros restent abstraites et ne doivent pas inclure d’exemples d’appels système dangereux.

---

## 7. Gestion des erreurs & robustesse

* Toujours vérifier les pré‑conditions (pointeurs, tailles) avant d’accéder à la mémoire ;
* Retourner des codes d’erreur explicites (valeurs négatives) et documentés ;
* Instrumenter le code avec des traces conditionnelles (macro DEBUG) pour faciliter le débogage ;
* Préférer l’échappement sûr sur erreur (cleanup) plutôt que des comportements indéterminés.

---

## 8. Tests, debug et environnement d’exécution

### 8.1 VM / sandbox

* Toujours développer et tester dans une VM isolée (qemu/kvm, container) ;
* Ne jamais exécuter des binaires expérimentaux sur une machine de production.

### 8.2 Outils recommandés

* `nasm` / `gas` pour assembler ;
* `ld` / `gcc` pour linker (si besoin) ;
* `gdb` / `gef` pour le debugging ;
* `qemu-user` / `qemu-system` pour exécuter et tracer dans un environnement contrôlé ;
* `objdump`, `readelf`, `file`, `hexdump` pour l’inspection passive des binaires.

### 8.3 Tests unitaires en assembleur

* Isoler petites routines et écrire de petits « harnesses » (programmes de test qui appellent la routine et vérifient le résultat).
* Automatiser avec un `Makefile` : build test -> run in qemu -> assert exit code.

Exemple de workflow test (conceptuel) :

```
make test-unit TARGET=util_checksum
qemu-x86_64 ./build/test_util_checksum || echo "FAIL"
```

---

## 9. CI & artefacts

* Mettre en place un pipeline CI qui assemble et exécute les tests dans une VM/sandbox ;
* Générer des artefacts non exécutables pour revue (dumps, mapfiles, listings) ;
* Ne jamais exposer des binaires expérimentaux publiquement sans audit.

---

## 10. Revue de code et documentation

* Demander une revue sur les points suivants : gestion mémoire, invariants, effets de bord, contrats d’interface (registres), tests de bord ;
* Fournir un `README.md` qui documente le but pédagogique, le protocole de build, et les scénarios de test.

---

## 11. Sécurité & éthique (obligatoire)

* Ne pas écrire ni tester de code qui modifie ou altère d’autres binaires sans autorisation explicite ;
* Respecter les lois et la politique de l’établissement (exécuter uniquement sur machines et dossiers de test) ;
* Documenter l’intention pédagogique et obtenir un accord si le projet touche à des sujets sensibles ;
* Mettre en place des garde‑fous (checks qui empêchent toute exécution hors sandbox), et privilégier les modes « lecture seule » pour l’analyse.

---

## 12. Checklist rapide avant soumission / démo

* [ ] Tous les fichiers sont bien nommés et organisés.
* [ ] Chaque routine est documentée (params, retour, effets secondaires).
* [ ] Les macros sont centralisées et expliquées.
* [ ] Des tests unitaires couvrent les cas normaux et les erreurs.
* [ ] Le projet se construit automatiquement (`Makefile`).
* [ ] Débogage possible via gdb/qemu et traces activables.
* [ ] Le code n’effectue aucune opération invasive sur d’autres programmes.
* [ ] README explique l’usage, le but pédagogique et les risques.

---

## 13. Annexes — Ressources & lectures recommandées

* Manuel d’architecture System V ABI (conventions d’appel) ;
* Documentation `nasm`, `gas`, `ld` ;
* Tutoriels `gdb` + `qemu` pour developer en environnement isolé ;
* Articles sur l’adaptation des design patterns à des langages procéduraux.

---

> Si tu veux, je peux produire dans le dépôt :
>
> * un `macros.inc` template (sécurisé, sans syscalls) ;
> * un `Makefile` prêt pour tests en qemu ;
> * un exemple de `test harness` non invasif pour démontrer le pattern Strategy.

