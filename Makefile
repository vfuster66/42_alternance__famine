# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: virginie <virginie@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/10/13 08:10:10 by sdestann          #+#    #+#              #
#    Updated: 2025/10/21 20:27:29 by virginie         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

IMAGE       := famine-playground:debian
CONTAINER   := famine_playground
DOCKER_DIR  := docker
WORKDIR     := $(shell pwd)
MOUNT_SRC   := $(WORKDIR)
MOUNT_DEST  := /workspace

# ---------------------------------------------------------------------------
.PHONY: build up run down shell logs prepare-tests run-tests clean-image exec

build:
	@echo "→ Building Docker image $(IMAGE) from $(DOCKER_DIR)/Dockerfile..."
	@ARCH=$$(uname -m); \
	if [ "$$ARCH" = "arm64" ] || [ "$$ARCH" = "aarch64" ]; then \
		echo "→ Detected ARM64 architecture, using x86-64 emulation..."; \
		docker build --platform linux/amd64 -t $(IMAGE) -f $(DOCKER_DIR)/Dockerfile .; \
	else \
		echo "→ Detected x86-64 architecture, building natively..."; \
		docker build -t $(IMAGE) -f $(DOCKER_DIR)/Dockerfile .; \
	fi

# Démarrer le conteneur (root par défaut) avec volume monté
up: build
	@echo "→ Starting container $(CONTAINER)..."
	-docker rm -f $(CONTAINER) 2>/dev/null || true
	docker run -d --name $(CONTAINER) \
	  -v "$(MOUNT_SRC):$(MOUNT_DEST)" \
	  -v "$(WORKDIR)/workspace/scripts:/home/dev/scripts:ro" \
	  --hostname famine-playground \
	  --workdir /home/dev \
	  --tty \
	  $(IMAGE)
	@echo "→ Container $(CONTAINER) started."

# Lancer le conteneur en mode interactif (utile pour debugging)
run: build
	@echo "→ Running interactive container (temporary)..."
	docker run --rm -it \
	  -v "$(MOUNT_SRC):$(MOUNT_DEST)" \
	  -v "$(WORKDIR)/scripts:/home/dev/scripts:ro" \
	  --workdir /home/dev \
	  $(IMAGE)

# Entrer dans un shell du conteneur déjà lancé
shell:
	@echo "→ Entering container $(CONTAINER) shell..."
	docker exec -it $(CONTAINER) /bin/bash

# Exécuter une commande dans le conteneur (ex : make inside)
exec:
	@docker exec -it $(CONTAINER) /bin/bash -c "$(CMD)"

# Afficher logs
logs:
	docker logs -f $(CONTAINER)

# Stop + remove container
down:
	@echo "→ Stopping and removing container $(CONTAINER)..."
	-docker rm -f $(CONTAINER) 2>/dev/null || true
	@echo "→ Done."

# Préparer les tests (appelle le script prepare_tests.sh dans le conteneur)
prepare-tests: up
	@chmod +x workspace/scripts/*.sh
	@echo "→ Preparing tests inside container..."
	docker exec -it $(CONTAINER) /bin/bash -lc "cd /home/dev && /home/dev/scripts/prepare_tests.sh"

# Exécuter les tests (run_tests.sh)
run-tests: prepare-tests
	@echo "→ Running tests inside container..."
	docker exec -it $(CONTAINER) /bin/bash -lc "cd /home/dev && /home/dev/scripts/run_tests.sh"

# Supprimer l'image (nettoyage)
clean-image:
	-docker image rm -f $(IMAGE) 2>/dev/null || true
	@echo "→ Docker image removed (if existed)."

# Aide
help:
	@echo "Makefile targets:"
	@echo "  make build         - build docker image"
	@echo "  make up            - build image and start background container"
	@echo "  make run           - run temporary interactive container"
	@echo "  make shell         - open bash shell in running container"
	@echo "  make prepare-tests - run test-preparation script inside container"
	@echo "  make run-tests     - run test runner inside container"
	@echo "  make down          - stop & remove container"
	@echo "  make clean-image   - remove the built image"

# Nettoyer les containers, volumes et images
stop:
	docker stop $(CONTAINER)

fclean: stop
	docker compose down -v
	docker volume prune -f
	docker system prune -f
