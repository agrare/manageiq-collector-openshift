PROJECT = myproject
NAME = manageiq-collector-openshift
VERSION = 0.1
REGISTRY=`minishift openshift registry`

.PHONY: all tag_latest install

all:
	docker build -t $(NAME):$(VERSION) --rm .

tag_latest:
	docker tag $(NAME):$(VERSION) $(REGISTRY)/$(PROJECT)/$(NAME):latest

install: tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(REGISTRY)/$(PROJECT)/$(NAME)
	@echo "*** Don't forget to create a tag by creating an official GitHub release."
