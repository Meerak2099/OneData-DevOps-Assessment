# Makefile for simple-python-app

.PHONY: build test deploy

build:
	docker build -t simple-python-app .

test:
	pytest tests/

deploy:
	kubectl apply -f k8s/deployment.yaml
	kubectl apply -f k8s/service.yaml