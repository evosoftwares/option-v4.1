SHELL := /bin/bash
FLUTTER ?= flutter

# Asaas endpoints (no secrets here)
SANDBOX_BASE_URL := https://api-sandbox.asaas.com/
PROD_BASE_URL    := https://api.asaas.com/

# -----------------------------------------------------------------------------
# Usage:
#   export ASAAS_API_KEY=your_key_here
#   make help
#   make run-sandbox
#   make run-prod
#   make run-web-sandbox
#   make build-apk-prod
#   make build-ios-sandbox
# -----------------------------------------------------------------------------

.PHONY: help check-api-key run-sandbox run-prod run-web-sandbox run-web-prod \
        build-apk-sandbox build-apk-prod build-ios-sandbox build-ios-prod

help:
	@echo "Targets disponíveis:"
	@echo "  help                 -> mostra este help"
	@echo "  run-sandbox          -> flutter run com ASAAS sandbox (requer ASAAS_API_KEY)"
	@echo "  run-prod             -> flutter run com ASAAS produção (requer ASAAS_API_KEY)"
	@echo "  run-web-sandbox      -> flutter run (web/chrome) sandbox (requer ASAAS_API_KEY)"
	@echo "  run-web-prod         -> flutter run (web/chrome) produção (requer ASAAS_API_KEY)"
	@echo "  build-apk-sandbox    -> build APK release (sandbox)"
	@echo "  build-apk-prod       -> build APK release (produção)"
	@echo "  build-ios-sandbox    -> build iOS (sandbox, --no-codesign)"
	@echo "  build-ios-prod       -> build iOS (produção, --no-codesign)"
	@echo ""
	@echo "Antes, exporte a variável ASAAS_API_KEY (não versione suas chaves):"
	@echo "  export ASAAS_API_KEY=seu_token"

check-api-key:
	@if [ -z "$$ASAAS_API_KEY" ]; then \
		echo "[ERRO] ASAAS_API_KEY não definida. Ex.: export ASAAS_API_KEY=seu_token"; \
		exit 1; \
	fi

run-sandbox: check-api-key
	$(FLUTTER) run \
		--dart-define=ASAAS_BASE_URL=$(SANDBOX_BASE_URL) \
		--dart-define=ASAAS_API_KEY=$$ASAAS_API_KEY

run-prod: check-api-key
	$(FLUTTER) run \
		--dart-define=ASAAS_BASE_URL=$(PROD_BASE_URL) \
		--dart-define=ASAAS_API_KEY=$$ASAAS_API_KEY

run-web-sandbox: check-api-key
	$(FLUTTER) run -d chrome --web-renderer html \
		--dart-define=ASAAS_BASE_URL=$(SANDBOX_BASE_URL) \
		--dart-define=ASAAS_API_KEY=$$ASAAS_API_KEY

run-web-prod: check-api-key
	$(FLUTTER) run -d chrome --web-renderer html \
		--dart-define=ASAAS_BASE_URL=$(PROD_BASE_URL) \
		--dart-define=ASAAS_API_KEY=$$ASAAS_API_KEY

build-apk-sandbox: check-api-key
	$(FLUTTER) build apk --release \
		--dart-define=ASAAS_BASE_URL=$(SANDBOX_BASE_URL) \
		--dart-define=ASAAS_API_KEY=$$ASAAS_API_KEY

build-apk-prod: check-api-key
	$(FLUTTER) build apk --release \
		--dart-define=ASAAS_BASE_URL=$(PROD_BASE_URL) \
		--dart-define=ASAAS_API_KEY=$$ASAAS_API_KEY

build-ios-sandbox: check-api-key
	$(FLUTTER) build ios --no-codesign \
		--dart-define=ASAAS_BASE_URL=$(SANDBOX_BASE_URL) \
		--dart-define=ASAAS_API_KEY=$$ASAAS_API_KEY

build-ios-prod: check-api-key
	$(FLUTTER) build ios --no-codesign \
		--dart-define=ASAAS_BASE_URL=$(PROD_BASE_URL) \
		--dart-define=ASAAS_API_KEY=$$ASAAS_API_KEY