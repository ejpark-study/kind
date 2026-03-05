SHELL := /bin/bash

.ONESHELL:

up:
	$(MAKE) cilium

cilium:
	./cni/cilium.sh
	./app/metrics.sh
