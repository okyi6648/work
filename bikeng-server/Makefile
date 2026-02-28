.PHONY: build run test clean docker-up docker-down migrate lint

# Build the server binary
build:
	go build -o bin/bikeng-server ./cmd/server

# Run the server locally
run:
	go run ./cmd/server

# Run all tests
test:
	go test ./... -v

# Clean build artifacts
clean:
	rm -rf bin/

# Start Docker Compose services
docker-up:
	docker-compose up -d

# Stop Docker Compose services
docker-down:
	docker-compose down

# Start only infrastructure (MySQL + Redis)
infra-up:
	docker-compose up -d mysql redis

# Run database migrations (requires running MySQL)
migrate:
	@for f in migrations/*.sql; do \
		echo "Running $$f..."; \
		mysql -h 127.0.0.1 -u bikeng -pbikeng123 bikeng < $$f; \
	done

# Run linter
lint:
	golangci-lint run ./...

# Tidy go modules
tidy:
	go mod tidy

# Build Docker image
docker-build:
	docker build -t bikeng-server .
