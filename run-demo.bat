@echo off
echo 🚀 Starting Streaky Affiliate Revenue Demo...
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed!
    echo Please install Node.js from: https://nodejs.org
    pause
    exit /b 1
)

echo ✅ Node.js found
echo.

REM Install dependencies if package.json exists
if exist package.json (
    echo 📦 Installing dependencies...
    npm install
    echo.
)

REM Start the backend server
echo 🔧 Starting affiliate revenue backend...
start /b node test-server.js

REM Wait a moment for server to start
timeout /t 3 /nobreak >nul

REM Open the demo in browser
echo 🌐 Opening demo in browser...
start complete-app-testing.html

echo.
echo ✅ Demo started successfully!
echo.
echo 📊 You can now:
echo   • Test affiliate offers and earn virtual revenue
echo   • Click offers to see CPC earnings (₹0.50-₹12)
echo   • Simulate sales for CPS commissions (5-25%%)
echo   • View real-time earnings dashboard
echo.
echo 🔗 Backend API: http://localhost:3000
echo 💻 Demo Interface: Should open automatically
echo.
echo Press any key to stop the demo...
pause >nul

REM Kill the Node.js process
taskkill /f /im node.exe >nul 2>&1
echo 🛑 Demo stopped.
pause