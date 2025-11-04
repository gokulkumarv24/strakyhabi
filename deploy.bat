@echo off
REM Streaky App Deployment Script for Windows
REM This script handles the complete deployment process for both Flutter app and Cloudflare Worker

setlocal enabledelayedexpansion

REM Configuration
set FLUTTER_VERSION=3.19.0
set NODE_VERSION=20
set APP_NAME=Streaky App

REM Colors (basic Windows CMD colors)
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

REM Functions
:log_info
echo %BLUE%[INFO]%NC% %~1
goto :eof

:log_success
echo %GREEN%[SUCCESS]%NC% %~1
goto :eof

:log_warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:log_error
echo %RED%[ERROR]%NC% %~1
goto :eof

:check_prerequisites
call :log_info "Checking prerequisites..."

REM Check Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    call :log_error "Flutter not found. Please install Flutter %FLUTTER_VERSION%"
    exit /b 1
)

REM Check Node.js
node --version >nul 2>&1
if errorlevel 1 (
    call :log_error "Node.js not found. Please install Node.js %NODE_VERSION%"
    exit /b 1
)

REM Check npm
npm --version >nul 2>&1
if errorlevel 1 (
    call :log_error "npm not found. Please install npm"
    exit /b 1
)

REM Check wrangler
wrangler --version >nul 2>&1
if errorlevel 1 (
    call :log_warning "Wrangler not found. Installing..."
    npm install -g wrangler
)

call :log_success "Prerequisites check completed"
goto :eof

:setup_flutter
call :log_info "Setting up Flutter environment..."

REM Get dependencies
flutter pub get
if errorlevel 1 exit /b 1

REM Run code generation
flutter packages pub run build_runner build --delete-conflicting-outputs
if errorlevel 1 exit /b 1

REM Analyze code
call :log_info "Analyzing Flutter code..."
flutter analyze
if errorlevel 1 exit /b 1

REM Run tests
call :log_info "Running Flutter tests..."
flutter test
if errorlevel 1 exit /b 1

call :log_success "Flutter setup completed"
goto :eof

:setup_worker
call :log_info "Setting up Worker environment..."

cd worker
if errorlevel 1 exit /b 1

REM Install dependencies
npm ci
if errorlevel 1 exit /b 1

REM Run linting
call :log_info "Linting Worker code..."
npm run lint
if errorlevel 1 exit /b 1

REM Run tests
call :log_info "Running Worker tests..."
npm test
if errorlevel 1 exit /b 1

cd ..

call :log_success "Worker setup completed"
goto :eof

:build_flutter_app
set build_mode=%~1
call :log_info "Building Flutter app in %build_mode% mode..."

if "%build_mode%"=="debug" (
    flutter build apk --debug
) else if "%build_mode%"=="release" (
    flutter build apk --release
) else if "%build_mode%"=="profile" (
    flutter build apk --profile
) else (
    call :log_error "Invalid build mode: %build_mode%"
    exit /b 1
)

if errorlevel 1 exit /b 1

call :log_success "Flutter app built successfully"
goto :eof

:deploy_worker
set environment=%~1
call :log_info "Deploying Worker to %environment%..."

cd worker
if errorlevel 1 exit /b 1

if "%environment%"=="development" (
    npx wrangler deploy --env development
) else if "%environment%"=="staging" (
    npx wrangler deploy --env staging
) else if "%environment%"=="production" (
    npx wrangler deploy --env production
) else (
    call :log_error "Invalid environment: %environment%"
    exit /b 1
)

if errorlevel 1 exit /b 1

cd ..

call :log_success "Worker deployed to %environment% successfully"
goto :eof

:create_kv_namespaces
call :log_info "Creating KV namespaces..."

cd worker
if errorlevel 1 exit /b 1

REM Create production namespace
wrangler kv:namespace create "STREAKY_KV" --env production 2>nul || call :log_warning "Production KV namespace might already exist"

REM Create staging namespace
wrangler kv:namespace create "STREAKY_KV" --env staging 2>nul || call :log_warning "Staging KV namespace might already exist"

REM Create development namespace
wrangler kv:namespace create "STREAKY_KV" --env development 2>nul || call :log_warning "Development KV namespace might already exist"

cd ..

call :log_success "KV namespaces created"
goto :eof

:generate_build_info
set environment=%~1
for /f "tokens=1-6 delims=:.-, " %%a in ('echo %date% %time%') do set build_time=%%c-%%a-%%b_%%d-%%e-%%f

REM Get version from pubspec.yaml
for /f "tokens=2 delims: " %%a in ('findstr "^version:" pubspec.yaml') do set app_version=%%a

REM Create build info file
(
echo {
echo   "app_name": "%APP_NAME%",
echo   "version": "%app_version%",
echo   "build_time": "%build_time%",
echo   "environment": "%environment%",
echo   "platform": "windows"
echo }
) > build_info.json

call :log_success "Build info generated"
goto :eof

:cleanup
call :log_info "Cleaning up temporary files..."

if exist build_info.json del build_info.json

if "%CLEAN_BUILD%"=="true" (
    flutter clean
)

call :log_success "Cleanup completed"
goto :eof

:show_deployment_info
set environment=%~1

echo.
call :log_success "🚀 Deployment completed successfully!"
echo.
echo 📱 App Information:
echo    Name: %APP_NAME%
for /f "tokens=2 delims: " %%a in ('findstr "^version:" pubspec.yaml') do echo    Version: %%a
echo    Environment: %environment%
echo.
echo 🌐 API Endpoints:
if "%environment%"=="production" (
    echo    API: https://api.yourdomain.com
    echo    Health: https://api.yourdomain.com/health
) else if "%environment%"=="staging" (
    echo    API: https://api.staging.yourdomain.com
    echo    Health: https://api.staging.yourdomain.com/health
) else (
    echo    API: https://streaky-app-worker.your-subdomain.workers.dev
    echo    Health: https://streaky-app-worker.your-subdomain.workers.dev/health
)
echo.
echo 📁 Build Artifacts:
echo    APK: build\app\outputs\flutter-apk\app-release.apk
echo.
echo 🔗 Next Steps:
echo    1. Test the deployed API endpoints
echo    2. Install the APK on Android devices
echo    3. Monitor logs with: wrangler tail --env %environment%
echo    4. Update DNS records if needed
echo.
goto :eof

:deploy
set environment=%~1
set build_mode=%~2
if "%environment%"=="" set environment=development
if "%build_mode%"=="" set build_mode=debug

call :log_info "Starting deployment of %APP_NAME% to %environment%..."

REM Pre-deployment checks
call :check_prerequisites
if errorlevel 1 exit /b 1

REM Setup environments
call :setup_flutter
if errorlevel 1 exit /b 1

call :setup_worker
if errorlevel 1 exit /b 1

REM Generate build information
call :generate_build_info "%environment%"

REM Build Flutter app
call :build_flutter_app "%build_mode%"
if errorlevel 1 exit /b 1

REM Deploy Worker
call :deploy_worker "%environment%"
if errorlevel 1 exit /b 1

REM Show deployment information
call :show_deployment_info "%environment%"

REM Cleanup
call :cleanup

goto :eof

:show_usage
echo Usage: %0 [COMMAND] [OPTIONS]
echo.
echo Commands:
echo   deploy [ENV] [MODE]  Deploy app to environment (development^|staging^|production^)
echo                        with build mode (debug^|release^|profile^)
echo   setup               Setup development environment
echo   kv-create          Create KV namespaces
echo   build [MODE]       Build Flutter app only
echo   test               Run all tests
echo   clean              Clean build artifacts
echo.
echo Examples:
echo   %0 deploy production release
echo   %0 deploy staging debug
echo   %0 setup
echo   %0 build release
echo.
goto :eof

REM Main script logic
if "%1"=="deploy" (
    call :deploy "%2" "%3"
) else if "%1"=="setup" (
    call :check_prerequisites
    call :setup_flutter
    call :setup_worker
    call :create_kv_namespaces
) else if "%1"=="kv-create" (
    call :create_kv_namespaces
) else if "%1"=="build" (
    call :build_flutter_app "%2"
) else if "%1"=="test" (
    call :setup_flutter
    call :setup_worker
) else if "%1"=="clean" (
    flutter clean
    cd worker && npm run clean 2>nul && cd ..
    call :cleanup
) else if "%1"=="help" (
    call :show_usage
) else if "%1"=="-h" (
    call :show_usage
) else if "%1"=="--help" (
    call :show_usage
) else if "%1"=="" (
    call :show_usage
) else (
    call :log_error "Unknown command: %1"
    call :show_usage
    exit /b 1
)