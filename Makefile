.PHONY: install
.DEFAULT_GOAL: install

install:
	pip3 install --user -r requirements.txt
	bash install.sh
