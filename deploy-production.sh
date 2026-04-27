#!/bin/bash
set -e

echo "🚀 Deploying Dozzle Log Viewer (Production)"
echo ""

# Check required dependencies
check_dependencies() {
    local missing=()
    
    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    elif ! docker compose version &> /dev/null; then
        missing+=("docker compose")
    fi
    
    if ! command -v openssl &> /dev/null; then
        missing+=("openssl")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "❌ Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Please install them and run this script again."
        exit 1
    fi
    
    echo "✓ Dependencies verified (docker, docker compose, openssl)"
}

# Generate TLS certificates for agent communication
generate_certificates() {
    if [ -f shared_key.pem ] && [ -f shared_cert.pem ]; then
        echo "✓ TLS certificates already exist"
        return
    fi
    
    echo "Generating TLS certificates..."
    
    # Generate private key (Ed25519)
    openssl genpkey -algorithm Ed25519 -out shared_key.pem
    
    # Generate certificate signing request
    openssl req -new -key shared_key.pem -out shared_request.csr \
        -subj "/C=US/ST=California/L=San Francisco/O=Dozzle"
    
    # Generate self-signed certificate (valid for 5 years)
    openssl x509 -req -in shared_request.csr -signkey shared_key.pem \
        -out shared_cert.pem -days 1825
    
    # Clean up CSR
    rm -f shared_request.csr
    
    echo "✓ TLS certificates generated"
}

# Create environment file
setup_environment() {
    if [ -f .env ]; then
        echo "✓ Environment file (.env) exists"
    else
        echo "Creating .env from env.example..."
        cp env.example .env
        echo "✓ Environment file created with defaults"
    fi
}

# Create required directories
setup_directories() {
    mkdir -p data
    echo "✓ Data directory ready"
}

compose_prod() {
    docker compose -f docker-compose.prod.yml "$@"
}

# Build and start containers
start_services() {
    echo ""
    echo "Building and starting Dozzle..."
    compose_prod up -d --build
}

# Show success message
show_success() {
    # Load environment for port/base
    source .env 2>/dev/null || true
    local port="${DOZZLE_PORT:-8080}"
    local base="${DOZZLE_BASE:-/}"
    
    echo ""
    echo "✅ Dozzle is running!"
    echo ""
    echo "Access at:"
    echo "  - Log Viewer: http://localhost:${port}${base}"
    echo ""
    echo "📊 Container Status:"
    compose_prod ps
    echo ""
    echo "Useful commands:"
    echo "  - View logs:    docker compose -f docker-compose.prod.yml logs -f"
    echo "  - Stop:         docker compose -f docker-compose.prod.yml down"
    echo "  - Restart:      docker compose -f docker-compose.prod.yml restart"
}

# Main execution
main() {
    check_dependencies
    generate_certificates
    setup_environment
    setup_directories
    echo ""
    start_services
    show_success
}

main
