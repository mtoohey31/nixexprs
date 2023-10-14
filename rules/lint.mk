STATIX_CONFIG := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))/../.statix.toml

.PHONY: lint
lint: format-check deadnix-check statix-check

.PHONY: format
format:
	nixpkgs-fmt .

.PHONY: format-check
format-check:
	nixpkgs-fmt --check .

.PHONY: deadnix
deadnix:
	deadnix --edit

.PHONY: deadnix-check
deadnix-check:
	deadnix --fail

.PHONY: statix
statix:
	statix fix --config $(STATIX_CONFIG)

.PHONY: statix-check
statix-check:
	statix check --config $(STATIX_CONFIG)
