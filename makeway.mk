define MAKEWAY

$(1):
	@echo "########################################################################################"
	@echo "## Make dir $(1)"
	$(PRECMD)mkdir -p $(1)
endef
