.PHONY: help docs

help: ## List available targets
	@echo "Orbit Audiobooks — available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

docs: ## Generate DocC documentation
	xcodebuild docbuild \
		-scheme "Orbit Audiobooks" \
		-destination 'generic/platform=iOS' \
		DOCC_HOSTING_BASE_PATH="/orbit_audiobooks"
	@echo "Documentation successfully built in derived data."
