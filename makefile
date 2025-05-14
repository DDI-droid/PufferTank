# Puffertank Makefile (using uv and per‑repo branches)

SHELL := /bin/bash
.ONESHELL:

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
	@printf '%b\n' ""
	@printf '%b\n' "$(BLUE)Usage: make <target>$(RESET)"
	@printf '%b\n' ""
	@printf '%b\n' "$(YELLOW)Targets:$(RESET)"
	@printf '  %b%-17s%b %s\n' "$(GREEN)" "env" "$(RESET)" "Create/update Python env and install deps"
	@printf '  %b%-17s%b %s\n' "$(GREEN)" "clone" "$(RESET)" "Add or update Git subtrees for internal repos"
	@printf '  %b%-17s%b %s\n' "$(GREEN)" "install-internal" "$(RESET)" "Install internal repos editable via pip"
	@printf '  %b%-17s%b %s\n' "$(GREEN)" "setup" "$(RESET)" "Run env, clone, and install-internal"
	@printf '  %b%-17s%b %s\n' "$(RED)"   "clean" "$(RESET)" "Remove env and subtrees"
	@printf '%b\n' ""

env:
	@printf '%b\n' "$(BLUE)→ Creating/updating Python virtual environment with uv...$(RESET)"
	uv venv $(ENV_NAME) --python $(PYTH_VERSION)
	# @printf '%b\n' "$(BLUE)→ Activating virtual environment...$(RESET)"
	# . $(ENV_NAME)/bin/activate
	# @printf '%b\n' "$(BLUE)→ Installing third‑party dependencies...$(RESET)"
	# pip install --upgrade pip
	# pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
	# pip install -r requirements.txt
	# @printf '%b\n' "$(GREEN)✓ Environment setup complete.$(RESET)"

clone:
	@printf '%b\n' "$(BLUE)→ Syncing subtrees for internal repos...$(RESET)"
	@for rb in $(REPO_BRANCHES); do \
	  repo=$${rb%%:*}; branch=$${rb##*:}; \
	  prefix="$$repo"; remote="$(GIT_BASE)/$$repo.git"; \
	  \
	  if [ -d "$$prefix" ]; then \
	    printf '%b   • Resetting and cleaning %s…%b\n' "$(YELLOW)" "$$prefix" "$(RESET)"; \
	    git reset --hard HEAD -- $$prefix >/dev/null 2>&1; \
	    git clean -fd $$prefix >/dev/null 2>&1; \
	    printf '%b   • Removing old %s…%b\n' "$(YELLOW)" "$$prefix" "$(RESET)"; \
	    git rm -rf $$prefix >/dev/null 2>&1 || true; \
	    rm -rf $$prefix; \
	  fi; \
	  \
	  printf '%b   • Adding %s (branch %s)...%b\n' "$(YELLOW)" "$$repo" "$$branch" "$(RESET)"; \
	  git remote add $$repo $$remote 2>/dev/null || true; \
	  git fetch $$repo; \
	  git subtree add --prefix=$$prefix $$repo $$branch --squash; \
	done
	@printf '%b\n' "$(GREEN)✓ Repos synced.$(RESET)"

# install-internal:
# 	@printf '%b\n' "$(BLUE)→ Installing internal packages in editable mode...$(RESET)"
# 	@. $(ENV_NAME)/bin/activate
# 	@for rb in $(REPO_BRANCHES); do \
# 	  repo=$${rb%%:*}; \
# 	  printf '%b   • Installing %s…%b\n' "$(YELLOW)" "$$repo" "$(RESET)"; \
# 	  pip install --editable ./$$repo; \
# 	done
# 	@printf '%b\n' "$(GREEN)✓ Internal packages installed.$(RESET)"

setup: env clone
	@printf '%b\n' "$(GREEN)✓ Puffertank full setup complete!$(RESET)"

clean:
	@printf '%b\n' "$(RED)→ Cleaning up environment and subtrees...$(RESET)"
	rm -rf $(ENV_NAME)
	@for rb in $(REPO_BRANCHES); do \
	  repo=$${rb%%:*}; \
	  rm -rf $$repo; \
	done
	@printf '%b\n' "$(GREEN)✓ Cleaned.$(RESET)"
