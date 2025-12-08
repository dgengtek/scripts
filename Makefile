.PHONY: install
.DEFAULT_GOAL: install

install:
	uv sync
	bash install.sh

ci: install
	echo "run ci test"
