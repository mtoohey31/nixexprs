.PHONY: home-manager
home-manager:
	$(NIX_CMD) build ".?submodules=1#homeManagerConfigurations.$$(hostname).activationPackage" --out-link "build/results/$$(hostname)-home-manager"
	"build/results/$$(hostname)-home-manager/activate"
