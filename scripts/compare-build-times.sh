#!/bin/bash

# Build Time Comparison Script
# Compares traditional Docker build vs Docker Bake for frontend service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to format time
format_time() {
    local seconds=$1
    if (( seconds < 60 )); then
        printf "%.2f seconds" "$seconds"
    else
        local minutes=$((seconds / 60))
        local remaining_seconds=$((seconds % 60))
        printf "%d minutes %.2f seconds" "$minutes" "$remaining_seconds"
    fi
}

# Function to clean up images
cleanup_images() {
    echo "Cleaning up existing images..."
    docker rmi -f myapp-frontend:latest 2>/dev/null || true
    docker rmi -f myapp-base:latest 2>/dev/null || true
    docker rmi -f localhost:5000/myapp-frontend:latest 2>/dev/null || true
    docker rmi -f localhost:5000/myapp-base:latest 2>/dev/null || true
    
    # Clean build cache
    docker builder prune -f >/dev/null 2>&1 || true
    print_success "Cleanup completed"
}

# Function to ensure buildx builder exists
setup_buildx() {
    echo "Setting up buildx builder..."
    
    # Check if mybuilder exists
    if ! docker buildx inspect mybuilder >/dev/null 2>&1; then
        print_warning "Creating buildx builder 'mybuilder'..."
        docker buildx create --name mybuilder --use >/dev/null 2>&1
        docker buildx inspect --bootstrap >/dev/null 2>&1
        print_success "Buildx builder created and bootstrapped"
    else
        docker buildx use mybuilder >/dev/null 2>&1
        print_success "Using existing buildx builder 'mybuilder'"
    fi
}

# Function to build with traditional Docker
build_traditional() {
    print_header "TRADITIONAL DOCKER BUILD TEST"
    
    echo "Building frontend service with traditional Docker build..."
    echo "This will build the base image first, then the frontend service"
    
    # Start timing
    start_time=$(date +%s.%N)
    
    # Build base image first (frontend depends on it)
    echo "Step 1: Building base image..."
    docker build -t myapp-base:latest ./shared -f ./shared/Dockerfile.base >/dev/null 2>&1
    
    # Build frontend image
    echo "Step 2: Building frontend image..."
    docker build -t myapp-frontend:latest ./frontend >/dev/null 2>&1
    
    # End timing
    end_time=$(date +%s.%N)
    traditional_time=$(echo "$end_time - $start_time" | bc)
    
    print_success "Traditional build completed"
    echo "Images built:"
    docker images | grep -E "(myapp-base|myapp-frontend)" | head -2
}

# Function to build with Docker Bake
build_bake() {
    print_header "DOCKER BAKE BUILD TEST"
    
    echo "Building frontend service with Docker Bake..."
    echo "This will build base and frontend concurrently with shared layers"
    
    # Create cache directory
    mkdir -p /tmp/.buildx-cache
    
    # Start timing
    start_time=$(date +%s.%N)
    
    # Build with bake (frontend target which depends on base)
    echo "Building with bake (base + frontend)..."
    docker buildx bake frontend -f docker-bake.hcl --load >/dev/null 2>&1
    
    # End timing
    end_time=$(date +%s.%N)
    bake_time=$(echo "$end_time - $start_time" | bc)
    
    print_success "Bake build completed"
    echo "Images built:"
    docker images | grep -E "(myapp-base|myapp-frontend|localhost:5000)" | head -4
}

# Function to test rebuild performance (simulating code change)
test_rebuild_performance() {
    print_header "REBUILD PERFORMANCE TEST"
    
    echo "Simulating a small code change in frontend..."
    
    # Make a small change to frontend
    echo "<!-- Build test comment $(date) -->" >> frontend/index.html
    
    # Test traditional rebuild
    echo -e "\n${YELLOW}Testing traditional rebuild...${NC}"
    start_time=$(date +%s.%N)
    docker build -t myapp-frontend:latest ./frontend >/dev/null 2>&1
    end_time=$(date +%s.%N)
    traditional_rebuild_time=$(echo "$end_time - $start_time" | bc)
    
    # Test bake rebuild
    echo -e "\n${YELLOW}Testing bake rebuild...${NC}"
    start_time=$(date +%s.%N)
    docker buildx bake frontend -f docker-bake.hcl --load >/dev/null 2>&1
    end_time=$(date +%s.%N)
    bake_rebuild_time=$(echo "$end_time - $start_time" | bc)
    
    # Restore original file
    git checkout frontend/index.html 2>/dev/null || sed -i '$d' frontend/index.html
}

# Function to display results
show_results() {
    print_header "BUILD TIME COMPARISON RESULTS"
    
    echo -e "${BLUE}📊 INITIAL BUILD TIMES:${NC}"
    echo -e "Traditional Docker Build: ${RED}$(format_time $traditional_time)${NC}"
    echo -e "Docker Bake Build:       ${GREEN}$(format_time $bake_time)${NC}"
    
    # Calculate time difference
    time_diff=$(echo "$traditional_time - $bake_time" | bc)
    percentage_saved=$(echo "scale=1; ($time_diff / $traditional_time) * 100" | bc)
    
    if (( $(echo "$time_diff > 0" | bc -l) )); then
        echo -e "Time Saved:              ${GREEN}$(format_time $time_diff) (${percentage_saved}% faster)${NC}"
    else
        time_diff=$(echo "$time_diff * -1" | bc)
        percentage_slower=$(echo "scale=1; ($time_diff / $bake_time) * 100" | bc)
        echo -e "Time Difference:         ${YELLOW}$(format_time $time_diff) (${percentage_slower}% slower)${NC}"
    fi
    
    echo -e "\n${BLUE}🔄 REBUILD TIMES (after code change):${NC}"
    echo -e "Traditional Rebuild:     ${RED}$(format_time $traditional_rebuild_time)${NC}"
    echo -e "Bake Rebuild:           ${GREEN}$(format_time $bake_rebuild_time)${NC}"
    
    # Calculate rebuild time difference
    rebuild_diff=$(echo "$traditional_rebuild_time - $bake_rebuild_time" | bc)
    rebuild_percentage=$(echo "scale=1; ($rebuild_diff / $traditional_rebuild_time) * 100" | bc)
    
    if (( $(echo "$rebuild_diff > 0" | bc -l) )); then
        echo -e "Rebuild Time Saved:      ${GREEN}$(format_time $rebuild_diff) (${rebuild_percentage}% faster)${NC}"
    else
        rebuild_diff=$(echo "$rebuild_diff * -1" | bc)
        rebuild_percentage=$(echo "scale=1; ($rebuild_diff / $bake_rebuild_time) * 100" | bc)
        echo -e "Rebuild Difference:      ${YELLOW}$(format_time $rebuild_diff) (${rebuild_percentage}% slower)${NC}"
    fi
    
    echo -e "\n${BLUE}💡 KEY INSIGHTS:${NC}"
    echo "• Docker Bake builds base and frontend layers efficiently"
    echo "• Shared layers are reused across builds"
    echo "• Rebuilds only affect changed layers"
    echo "• Parallel building can reduce overall build time"
    
    if (( $(echo "$bake_time < $traditional_time" | bc -l) )); then
        echo -e "\n${GREEN}🎉 Docker Bake is faster for this build!${NC}"
    else
        echo -e "\n${YELLOW}ℹ️  For this simple example, times may be similar.${NC}"
        echo -e "${YELLOW}   Bake benefits increase with more complex dependencies.${NC}"
    fi
}

# Main execution
main() {
    print_header "DOCKER BUILD TIME COMPARISON"
    echo "This script compares build times between traditional Docker build and Docker Bake"
    echo "using the frontend service as an example."
    echo ""
    echo "Test will include:"
    echo "1. Initial build comparison"
    echo "2. Rebuild performance after code change"
    echo ""
    read -p "Press Enter to continue..."
    
    # Check prerequisites
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v bc &> /dev/null; then
        print_error "bc calculator is not installed. Please install it: sudo apt-get install bc"
        exit 1
    fi
    
    # Setup
    cleanup_images
    setup_buildx
    
    # Run tests
    build_traditional
    cleanup_images  # Clean between tests for fair comparison
    build_bake
    
    # Test rebuild performance
    test_rebuild_performance
    
    # Show results
    show_results
    
    print_header "TEST COMPLETED"
    echo "You can now run 'docker images' to see the built images"
    echo "To clean up: docker rmi myapp-frontend:latest myapp-base:latest"
}

# Run main function
main "$@"
