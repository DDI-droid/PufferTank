# Puffertank Makefile (using uv and per-repo branches, with colors)

# === Configuration ===
UV            := uv
REPO_BRANCHES := pufferlib:2.0 cleanrl:master
GIT_BASE      := https://github.com/DDI-droid
ENV_NAME      := env
PYTH_VERSION  := 3.11

# === Colors ===
RESET  := \033[0m
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
BLUE   := \033[1;34m

# === Phony Targets ===
.PHONY: all env clone install-internal clean help setup

help:
	@echo ""
	@echo "$(BLUE)Usage: make <target>$(RESET)"
	@echo ""
	@echo "$(YELLOW)Targets:$(RESET)"
	@echo "  $(GREEN)env$(RESET)                Create/update Python env with uv and install deps"
	@echo "  $(GREEN)clone$(RESET)              Add or update Git subtrees for internal repos"
	@echo "  $(GREEN)install-internal$(RESET)   Install internal repos editable via uv pip"
	@echo "  $(GREEN)setup$(RESET)              Run env, clone, and install-internal"
	@echo "  $(RED)clean$(RESET)                Remove env and subtrees"
	@echo ""

env:
	@echo "$(BLUE)→ Creating/updating Python virtual environment with uv...$(RESET)"
	@$(UV) venv $(ENV_NAME) --python $(PYTH_VERSION)
	@echo "$(BLUE)→ Installing third-party dependencies...$(RESET)"
	@$(UV) pip install --upgrade pip
	@$(UV) pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
	@$(UV) pip install -r requirements.txt
	@echo "$(GREEN)✓ Environment setup complete.$(RESET)"

clone:
	@echo "$(BLUE)→ Syncing subtrees for internal repos...$(RESET)"
	@for rb in $(REPO_BRANCHES); do \
	  repo=$${rb%%:*}; branch=$${rb##*:}; \
	  remote="$(GIT_BASE)/$$repo.git"; \
	  prefix="$$repo"; \
	  if [ ! -d $$prefix ]; then \
	    echo "$(YELLOW)   • Adding $$repo (branch $$branch)...$(RESET)"; \
	    git remote add $$repo $$remote 2>/dev/null || true; \
	    git fetch $$repo; \
	    git subtree add --prefix=$$prefix $$repo $$branch --squash; \
	  else \
	    echo "$(YELLOW)   • Updating $$repo (branch $$branch)...$(RESET)"; \
	    git fetch $$repo; \
	    git subtree pull --prefix=$$prefix $$repo $$branch --squash; \
	  fi \
	done
	@echo "$(GREEN)✓ Repos synced.$(RESET)"

install-internal:
	@echo "$(BLUE)→ Installing internal packages in editable mode...$(RESET)"
	@for rb in $(REPO_BRANCHES); do \
	  repo=$${rb%%:*}; \
	  echo "$(YELLOW)   • uv pip install -e $$repo$(RESET)"; \
	  $(UV) pip install -e $$repo; \
	done
	@echo "$(GREEN)✓ Internal packages installed.$(RESET)"

setup: env clone install-internal
	@echo "$(GREEN)✓ Puffertank full setup complete!$(RESET)"

clean:
	@echo "$(RED)→ Cleaning up environment and subtrees...$(RESET)"
	@rm -rf $(ENV_NAME)
	@for rb in $(REPO_BRANCHES); do \
	  repo=$${rb%%:*}; \
	  rm -rf $$repo; \
	done
	@echo "$(GREEN)✓ Cleaned.$(RESET)"
