LAB ?= xrd-playground
TOPO := labs/$(LAB)/topology.clab.yml
SCRIPTS := labs/$(LAB)/scripts

.PHONY: list preflight deploy redeploy inspect verify cli-xrd1 cli-xrd2 destroy clean

list:
	@find labs -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort

preflight:
	@test -f "$(TOPO)" || { echo "Unknown lab: $(LAB)" >&2; exit 1; }
	@command -v docker >/dev/null || { echo "docker not found" >&2; exit 1; }
	@command -v containerlab >/dev/null || { echo "containerlab not found" >&2; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "Docker daemon is not available" >&2; exit 1; }
	@echo "Preflight passed for $(LAB)"

deploy: preflight
	sudo containerlab deploy --topo "$(TOPO)"

redeploy: preflight
	sudo containerlab deploy --reconfigure --topo "$(TOPO)"

inspect:
	sudo containerlab inspect --topo "$(TOPO)"

verify:
	bash "$(SCRIPTS)/verify.sh"

cli-xrd1:
	docker exec -it clab-xrd-playground-xrd1 /pkg/bin/xr_cli.sh

cli-xrd2:
	docker exec -it clab-xrd-playground-xrd2 /pkg/bin/xr_cli.sh

destroy:
	sudo containerlab destroy --topo "$(TOPO)"

clean:
	sudo containerlab destroy --cleanup --topo "$(TOPO)"
