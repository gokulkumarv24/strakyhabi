# Flutter Setup Script for Windows
# Run this script after the download completes

Write-Host "🚀 Setting up Flutter for Streaky App..." -ForegroundColor Green

# Check if flutter.zip exists
$flutterZip = "C:\Users\C19759\flutter\flutter.zip"
if (Test-Path $flutterZip) {
    Write-Host "✅ Flutter SDK found. Extracting..." -ForegroundColor Green
    
    # Extract Flutter SDK
    try {
        Expand-Archive -Path $flutterZip -DestinationPath "C:\Users\C19759\flutter" -Force
        Write-Host "✅ Flutter SDK extracted successfully!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error extracting Flutter: $_" -ForegroundColor Red
        exit 1
    }
    
    # Add Flutter to PATH for current session
    $env:PATH += ";C:\Users\C19759\flutter\flutter\bin"
    Write-Host "✅ Flutter added to PATH" -ForegroundColor Green
    
    # Verify Flutter installation
    Write-Host "🔍 Verifying Flutter installation..." -ForegroundColor Yellow
    try {
        flutter --version
        Write-Host "✅ Flutter verification successful!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Flutter verification failed. Manually add to PATH." -ForegroundColor Red
    }
    
    # Navigate to Streaky app and install dependencies
    Write-Host "📦 Installing app dependencies..." -ForegroundColor Yellow
    Set-Location "C:\Users\C19759\gk\streaky_app"
    
    try {
        flutter pub get
        Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error installing dependencies: $_" -ForegroundColor Red
        Write-Host "Try running 'flutter pub get' manually" -ForegroundColor Yellow
    }
    
    # Run Flutter doctor
    Write-Host "🩺 Running Flutter doctor..." -ForegroundColor Yellow
    flutter doctor
    
    Write-Host "`n🎉 Flutter setup complete!" -ForegroundColor Green
    Write-Host "Ready to run: flutter run -d chrome" -ForegroundColor Cyan
    
} else {
    Write-Host "❌ Flutter SDK not found at $flutterZip" -ForegroundColor Red
    Write-Host "Please wait for download to complete or download manually from:" -ForegroundColor Yellow
    Write-Host "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip" -ForegroundColor Cyan
}

Write-Host "`n📱 Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: flutter run -d chrome" -ForegroundColor White
Write-Host "2. Open Rewards tab to test affiliate revenue system" -ForegroundColor White
Write-Host "3. Start earning with CPC clicks and CPS sales!" -ForegroundColor White