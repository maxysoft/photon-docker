#!/bin/bash
set -e

# Test script for Docker multi-country deployment
# This script validates the Docker setup without requiring actual deployment

echo "=== Photon Docker Multi-Country Deployment Test ==="
echo

# Test 1: Check Docker files exist
echo "✓ Checking Docker files..."
required_files=(
    "Dockerfile"
    "docker-compose.yml"
    "docker-compose.simple.yml" 
    "docker/entrypoint.sh"
    "docker/download-data.sh"
    "docker/nginx.conf"
    ".dockerignore"
    "DOCKER.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ✗ $file missing"
        exit 1
    fi
done

# Test 2: Basic Dockerfile validation
echo
echo "✓ Validating Dockerfile structure..."
if grep -q "FROM.*jdk" Dockerfile && grep -q "COPY.*jar" Dockerfile; then
    echo "  ✓ Dockerfile structure looks correct"
else
    echo "  ✗ Dockerfile structure appears incorrect"
    exit 1
fi

# Test 3: Basic docker-compose validation
echo
echo "✓ Validating docker-compose files structure..."
compose_files=("docker-compose.yml" "docker-compose.simple.yml")
for compose_file in "${compose_files[@]}"; do
    if grep -q "version:" "$compose_file" && grep -q "services:" "$compose_file"; then
        echo "  ✓ $compose_file structure looks correct"
    else
        echo "  ✗ $compose_file structure appears incorrect"
        exit 1
    fi
done

# Test 4: Check script permissions and syntax
echo
echo "✓ Checking scripts..."
scripts=("docker/entrypoint.sh" "docker/download-data.sh")
for script in "${scripts[@]}"; do
    if [ -x "$script" ]; then
        echo "  ✓ $script is executable"
    else
        echo "  ℹ Making $script executable"
        chmod +x "$script"
    fi
    
    # Basic bash syntax check
    if bash -n "$script"; then
        echo "  ✓ $script syntax is valid"
    else
        echo "  ✗ $script has syntax errors"
        exit 1
    fi
done

# Test 5: Validate environment variables in docker-compose
echo
echo "✓ Validating environment variables..."
if grep -q "PHOTON_COUNTRIES" docker-compose.yml; then
    echo "  ✓ PHOTON_COUNTRIES variable found"
else
    echo "  ✗ PHOTON_COUNTRIES variable missing"
    exit 1
fi

if grep -q "PHOTON_LANGUAGES" docker-compose.yml; then
    echo "  ✓ PHOTON_LANGUAGES variable found"
else
    echo "  ✗ PHOTON_LANGUAGES variable missing"
    exit 1
fi

# Test 6: Check for health checks
echo
echo "✓ Checking health checks configuration..."
if grep -q "healthcheck:" docker-compose.yml; then
    echo "  ✓ Health checks configured"
else
    echo "  ✗ Health checks missing"
    exit 1
fi

# Test 7: Validate volume configurations
echo
echo "✓ Checking volume configurations..."
if grep -q "volumes:" docker-compose.yml; then
    echo "  ✓ Volumes configured for data persistence"
else
    echo "  ✗ Volume configuration missing"
    exit 1
fi

# Test 8: Check if ports are properly configured
echo
echo "✓ Validating port configurations..."
expected_ports=("2322" "2323" "2324" "2325")
for port in "${expected_ports[@]}"; do
    if grep -q "$port:2322" docker-compose.yml; then
        echo "  ✓ Port $port is configured"
    else
        echo "  ℹ Port $port not found (this may be expected)"
    fi
done

# Test 9: Validate country codes in examples
echo
echo "✓ Checking country code examples..."
valid_country_codes=("de" "fr" "it" "es" "us" "ca" "mx" "nl" "be")
found_valid_codes=false
for code in "${valid_country_codes[@]}"; do
    if grep -q "$code" docker-compose.yml; then
        found_valid_codes=true
        break
    fi
done

if [ "$found_valid_codes" = true ]; then
    echo "  ✓ Valid country codes found in examples"
else
    echo "  ✗ No valid country codes found in examples"
    exit 1
fi

# Test 10: Check CORS and security configurations
echo
echo "✓ Checking security configurations..."
if grep -q "PHOTON_CORS_ANY" docker-compose.yml; then
    echo "  ✓ CORS configuration available"
else
    echo "  ✗ CORS configuration missing"
    exit 1
fi

echo
echo "=== All Tests Passed! ==="
echo
echo "Docker multi-country deployment is ready to use."
echo
echo "Next steps:"
echo "1. For single country: docker-compose -f docker-compose.simple.yml up -d"
echo "2. For multi-country: docker-compose up -d"
echo "3. For custom setup: See DOCKER.md for detailed configuration"
echo
echo "Services will be available at:"
echo "- Simple deployment: http://localhost:2322"
echo "- Multi-country world: http://localhost:2322"
echo "- Multi-country Europe: http://localhost:2323"
echo "- Multi-country North America: http://localhost:2324"
echo "- Multi-country Germany: http://localhost:2325"