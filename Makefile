LAB ?=
TOPO := labs/$(LAB)/topology.clab.yml
SCRIPTS := labs/$(LAB)/scripts

.PHONY: list require-lab preflight deploy redeploy inspect verify save-configs cli destroy clean

list:
	@find labs -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort

require-lab:
	@test -n "$(LAB)" || { echo "Usage: make LAB=<lab-name> <target>" >&2; exit 1; }

preflight: require-lab
	@test -f "$(TOPO)" || { echo "Unknown lab: $(LAB)" >&2; exit 1; }
	@command -v docker >/dev/null || { echo "docker not found" >&2; exit 1; }
	@command -v containerlab >/dev/null || { echo "containerlab not found" >&2; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "Docker daemon is not available" >&2; exit 1; }
	@echo "Preflight passed for $(LAB)"

deploy: preflight
	sudo containerlab deploy --topo "$(TOPO)"

redeploy: preflight
	sudo containerlab deploy --reconfigure --topo "$(TOPO)"

inspect: require-lab
	sudo containerlab inspect --topo "$(TOPO)"

verify: require-lab
	bash "$(SCRIPTS)/verify.sh"

save-configs: require-lab
	bash "scripts/save-configs.sh" "$(TOPO)"

cli: require-lab
	@test -n "$(NODE)" || { echo "Usage: make LAB=<lab-name> cli NODE=<node>" >&2; exit 1; }
	docker exec -it "clab-$(LAB)-$(NODE)" /pkg/bin/xr_cli.sh

destroy: require-lab
	sudo containerlab destroy --topo "$(TOPO)"

clean: require-lab
	sudo containerlab destroy --cleanup --topo "$(TOPO)"
