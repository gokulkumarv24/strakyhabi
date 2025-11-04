#!/bin/bash

# Streaky App Deployment Script
# This script handles the complete deployment process for both Flutter app and Cloudflare Worker

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLUTTER_VERSION="3.19.0"
NODE_VERSION="20"
APP_NAME="Streaky App"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found. Please install Flutter $FLUTTER_VERSION"
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js not found. Please install Node.js $NODE_VERSION"
        exit 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        log_error "npm not found. Please install npm"
        exit 1
    fi
    
    # Check wrangler
    if ! command -v wrangler &> /dev/null; then
        log_warning "Wrangler not found. Installing..."
        npm install -g wrangler
    fi
    
    log_success "Prerequisites check completed"
}

setup_flutter() {
    log_info "Setting up Flutter environment..."
    
    # Get dependencies
    flutter pub get
    
    # Run code generation
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    # Analyze code
    log_info "Analyzing Flutter code..."
    flutter analyze
    
    # Run tests
    log_info "Running Flutter tests..."
    flutter test
    
    log_success "Flutter setup completed"
}

setup_worker() {
    log_info "Setting up Worker environment..."
    
    cd worker
    
    # Install dependencies
    npm ci
    
    # Run linting
    log_info "Linting Worker code..."
    npm run lint
    
    # Run tests
    log_info "Running Worker tests..."
    npm test
    
    cd ..
    
    log_success "Worker setup completed"
}

build_flutter_app() {
    local build_mode=$1
    log_info "Building Flutter app in $build_mode mode..."
    
    case $build_mode in
        "debug")
            flutter build apk --debug
            ;;
        "release")
            flutter build apk --release
            ;;
        "profile")
            flutter build apk --profile
            ;;
        *)
            log_error "Invalid build mode: $build_mode"
            exit 1
            ;;
    esac
    
    log_success "Flutter app built successfully"
}

deploy_worker() {
    local environment=$1
    log_info "Deploying Worker to $environment..."
    
    cd worker
    
    case $environment in
        "development")
            npx wrangler deploy --env development
            ;;
        "staging")
            npx wrangler deploy --env staging
            ;;
        "production")
            npx wrangler deploy --env production
            ;;
        *)
            log_error "Invalid environment: $environment"
            exit 1
            ;;
    esac
    
    cd ..
    
    log_success "Worker deployed to $environment successfully"
}

create_kv_namespaces() {
    log_info "Creating KV namespaces..."
    
    cd worker
    
    # Create production namespace
    wrangler kv:namespace create "STREAKY_KV" --env production || log_warning "Production KV namespace might already exist"
    
    # Create staging namespace
    wrangler kv:namespace create "STREAKY_KV" --env staging || log_warning "Staging KV namespace might already exist"
    
    # Create development namespace
    wrangler kv:namespace create "STREAKY_KV" --env development || log_warning "Development KV namespace might already exist"
    
    cd ..
    
    log_success "KV namespaces created"
}

generate_build_info() {
    local environment=$1
    local build_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    
    cat > build_info.json << EOF
{
  "app_name": "$APP_NAME",
  "version": "$(grep '^version:' pubspec.yaml | cut -d ' ' -f 2 | tr -d '\r')",
  "build_time": "$build_time",
  "environment": "$environment",
  "git_commit": "$git_commit",
  "git_branch": "$git_branch",
  "flutter_version": "$(flutter --version | head -n 1 | cut -d ' ' -f 2)",
  "node_version": "$(node --version)"
}
EOF
    
    log_success "Build info generated"
}

run_security_checks() {
    log_info "Running security checks..."
    
    # Check for sensitive data in git
    if git log --all --full-history -- "*.key" "*.pem" "*.p12" "**/secrets/**" | grep -q "commit"; then
        log_warning "Potential sensitive files found in git history"
    fi
    
    # Check pubspec.yaml for known vulnerable packages
    if grep -q "http: ^0.13.0" pubspec.yaml; then
        log_warning "Consider updating http package to latest version"
    fi
    
    log_success "Security checks completed"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Remove build artifacts that shouldn't be committed
    rm -f build_info.json
    
    # Clean Flutter build cache if needed
    if [ "$CLEAN_BUILD" = "true" ]; then
        flutter clean
    fi
    
    log_success "Cleanup completed"
}

show_deployment_info() {
    local environment=$1
    
    echo ""
    log_success "🚀 Deployment completed successfully!"
    echo ""
    echo "📱 App Information:"
    echo "   Name: $APP_NAME"
    echo "   Version: $(grep '^version:' pubspec.yaml | cut -d ' ' -f 2 | tr -d '\r')"
    echo "   Environment: $environment"
    echo ""
    echo "🌐 API Endpoints:"
    case $environment in
        "production")
            echo "   API: https://api.yourdomain.com"
            echo "   Health: https://api.yourdomain.com/health"
            ;;
        "staging")
            echo "   API: https://api.staging.yourdomain.com"
            echo "   Health: https://api.staging.yourdomain.com/health"
            ;;
        "development")
            echo "   API: https://streaky-app-worker.your-subdomain.workers.dev"
            echo "   Health: https://streaky-app-worker.your-subdomain.workers.dev/health"
            ;;
    esac
    echo ""
    echo "📁 Build Artifacts:"
    echo "   APK: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "🔗 Next Steps:"
    echo "   1. Test the deployed API endpoints"
    echo "   2. Install the APK on Android devices"
    echo "   3. Monitor logs with: wrangler tail --env $environment"
    echo "   4. Update DNS records if needed"
    echo ""
}

# Main deployment function
deploy() {
    local environment=${1:-"development"}
    local build_mode=${2:-"debug"}
    
    log_info "Starting deployment of $APP_NAME to $environment..."
    
    # Pre-deployment checks
    check_prerequisites
    run_security_checks
    
    # Setup environments
    setup_flutter
    setup_worker
    
    # Generate build information
    generate_build_info "$environment"
    
    # Build Flutter app
    build_flutter_app "$build_mode"
    
    # Deploy Worker
    deploy_worker "$environment"
    
    # Show deployment information
    show_deployment_info "$environment"
    
    # Cleanup
    cleanup
}

# Script usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy [ENV] [MODE]  Deploy app to environment (development|staging|production)"
    echo "                       with build mode (debug|release|profile)"
    echo "  setup               Setup development environment"
    echo "  kv-create          Create KV namespaces"
    echo "  build [MODE]       Build Flutter app only"
    echo "  test               Run all tests"
    echo "  clean              Clean build artifacts"
    echo ""
    echo "Examples:"
    echo "  $0 deploy production release"
    echo "  $0 deploy staging debug"
    echo "  $0 setup"
    echo "  $0 build release"
    echo ""
}

# Parse command line arguments
case "${1:-}" in
    "deploy")
        deploy "${2:-development}" "${3:-debug}"
        ;;
    "setup")
        check_prerequisites
        setup_flutter
        setup_worker
        create_kv_namespaces
        ;;
    "kv-create")
        create_kv_namespaces
        ;;
    "build")
        build_flutter_app "${2:-debug}"
        ;;
    "test")
        setup_flutter
        setup_worker
        ;;
    "clean")
        flutter clean
        cd worker && npm run clean 2>/dev/null || true && cd ..
        cleanup
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        log_error "Unknown command: ${1:-}"
        show_usage
        exit 1
        ;;
esac