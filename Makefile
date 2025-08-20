.PHONY: help start stop init demo verify clean

help: ## Show this help message
	@echo "HashiCorp Vault LDAP Service Account Rotation Demo"
	@echo "=================================================="
	@echo ""
	@echo "Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

start: ## Start Docker containers
	@echo "🚀 Starting Docker containers..."
	docker-compose up -d
	@echo "✅ Containers started!"

stop: ## Stop Docker containers
	@echo "🛑 Stopping Docker containers..."
	docker-compose down
	@echo "✅ Containers stopped!"

init: ## Initialize Vault and LDAP (run after start)
	@echo "🔧 Initializing Vault and LDAP..."
	./vault-init.sh

demo: ## Run the interactive demo
	@echo "🎭 Starting demo..."
	./demo.sh

reset: ## Reset demo environment for consistent runs
	@echo "🔄 Resetting demo environment..."
	./reset-demo.sh

verify: ## Verify the environment is working
	@echo "🔍 Verifying environment..."
	./verify.sh

clean: ## Clean up everything (containers, volumes, temp files)
	@echo "🧹 Cleaning up..."
	./cleanup.sh

setup: start init ## Complete setup (start + init)
	@echo "🎉 Setup complete! Run 'make demo' to start the demonstration."

status: ## Show status of all services
	@echo "📊 Service Status:"
	@echo ""
	@echo "Docker Containers:"
	docker-compose ps
	@echo ""
	@echo "Vault Status:"
	@VAULT_ADDR=http://localhost:8200 VAULT_TOKEN=myroot vault status 2>/dev/null || echo "Vault not accessible"
