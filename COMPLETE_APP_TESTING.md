# 🚀 Complete Flutter App Testing Guide

## 📱 Testing the Entire Streaky Affiliate Revenue App

### 🎯 Current Status

- ✅ Backend test server running on localhost:3000
- ✅ HTML demo working in browser
- ❌ Flutter not installed yet
- 🎯 **Goal**: Test complete Flutter app with all affiliate features

---

## 🔧 Option 1: Install Flutter Locally (Recommended)

### Step 1: Download Flutter

```powershell
# Create Flutter directory
New-Item -ItemType Directory -Path "C:\flutter" -Force
cd C:\flutter

# Download Flutter (stable channel)
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip" -OutFile "flutter.zip"

# Extract Flutter
Expand-Archive -Path "flutter.zip" -DestinationPath "C:\flutter" -Force
```

### Step 2: Add to PATH

```powershell
# Add Flutter to PATH for current session
$env:PATH += ";C:\flutter\flutter\bin"

# Verify Flutter installation
flutter --version
flutter doctor
```

### Step 3: Install Dependencies

```powershell
cd C:\Users\C19759\gk\streaky_app
flutter pub get
```

### Step 4: Run the App

```powershell
# Run on Windows (desktop)
flutter run -d windows

# Or run on web browser
flutter run -d chrome
```

---

## 🌐 Option 2: GitHub Codespaces (Cloud Development)

If local installation has restrictions:

1. **Open Repository in Codespaces**:

   - Go to: https://github.com/gokulkumarv24/strakyhabi
   - Click "Code" → "Codespaces" → "Create codespace"

2. **Set up Flutter in Codespaces**:

   ```bash
   # Install Flutter in the cloud
   git clone https://github.com/flutter/flutter.git -b stable
   export PATH="$PATH:`pwd`/flutter/bin"
   flutter doctor

   # Install app dependencies
   cd /workspaces/strakyhabi
   flutter pub get

   # Run on web
   flutter run -d web-server --web-port 3000
   ```

3. **Access via browser**: Codespaces will provide a URL to test your app

---

## 📱 Option 3: Android Emulator Testing

If you have Android Studio:

```powershell
# Start Android emulator
flutter emulators --launch <emulator_name>

# Run app on emulator
flutter run
```

---

## 🧪 Option 4: Web Testing (Simplest)

Test the Flutter app in your browser:

```powershell
cd C:\Users\C19759\gk\streaky_app
flutter run -d chrome --web-port 8080
```

---

## 📋 What You'll Test in the Complete App

### 🏠 **Main App Features**:

- ✅ Streaky productivity tracking
- ✅ Task management and timers
- ✅ User profile and settings

### 💰 **Affiliate Revenue Features**:

- ✅ **Rewards Screen**: Beautiful Material Design 3 interface
- ✅ **Scratch Cards**: Gamified reward revelations with animations
- ✅ **Offer Cards**: 5 affiliate networks (Amazon, Flipkart, Myntra, etc.)
- ✅ **Earnings Tracking**: Real-time CPC/CPS revenue monitoring
- ✅ **Click Tracking**: Instant ₹5-12 rewards per click
- ✅ **Sale Conversions**: 5-25% commission on purchases
- ✅ **AI Personalization**: Smart offer ranking based on user behavior

### 🎮 **Interactive Testing Scenarios**:

1. **Open Rewards Tab**:

   - Navigate to affiliate rewards section
   - See personalized offers from 5 networks
   - Beautiful card-based interface

2. **Test Offer Interactions**:

   - Tap on Amazon Electronics offer
   - Watch scratch card animation
   - See ₹8.50 CPC earnings added instantly

3. **Simulate Purchase**:

   - Complete offer interaction flow
   - Trigger sale conversion webhook
   - Watch CPS commission (₹120 for ₹1000 purchase)

4. **Earnings Dashboard**:

   - View total earnings breakdown
   - See click history and sale conversions
   - Monitor revenue projections

5. **User Experience**:
   - Test haptic feedback on interactions
   - Verify smooth animations
   - Test offline fallback offers

---

## 🎯 Testing Checklist

### ✅ **Backend Integration**:

- [ ] App connects to localhost:3000 test server
- [ ] Offers load from 5 affiliate networks
- [ ] Click tracking works (CPC revenue)
- [ ] Sale conversion tracking (CPS revenue)
- [ ] Real-time earnings updates

### ✅ **UI/UX Testing**:

- [ ] Rewards screen loads with offers
- [ ] Scratch card animations work smoothly
- [ ] Earnings dashboard shows correct totals
- [ ] Material Design 3 theming applied
- [ ] Responsive design on different screen sizes

### ✅ **Revenue System**:

- [ ] CPC: ₹5-12 per click tracked correctly
- [ ] CPS: 5-25% commission on sales
- [ ] Multiple affiliate networks working
- [ ] AI offer ranking based on user behavior
- [ ] Real-time earnings synchronization

---

## 📊 Expected Test Results

After 10 minutes of testing:

- **Offers viewed**: 5+ from different networks
- **Clicks generated**: 3-5 (₹25-60 CPC revenue)
- **Sale simulation**: 1-2 (₹50-200 CPS revenue)
- **Total earnings**: ₹75-260 demonstrated
- **User experience**: Smooth, engaging, gamified

---

## 🚀 Quick Start Commands

Choose your preferred option:

### Local Installation:

```powershell
# Download and install Flutter
# (see detailed steps above)
cd C:\Users\C19759\gk\streaky_app
flutter run -d chrome
```

### Codespaces (Cloud):

```bash
# Open GitHub Codespaces
# Follow setup instructions above
flutter run -d web-server
```

### Test Server + HTML Demo:

```powershell
# Keep current test server running
# Use HTML demo for immediate testing
Start-Process "http://localhost:3000"
```

---

## 💡 Troubleshooting

### If Flutter installation fails:

1. Use GitHub Codespaces (cloud development)
2. Continue with HTML demo + API testing
3. Use the test server for backend validation

### If you need admin permissions:

1. Try portable Flutter installation
2. Use Codespaces for unrestricted environment
3. Test core functionality with existing tools

---

## 🎉 Success Criteria

Your complete app testing is successful when:

- ✅ Flutter app launches without errors
- ✅ Rewards screen displays affiliate offers
- ✅ Click interactions generate CPC revenue
- ✅ Sale conversions create CPS commissions
- ✅ Earnings dashboard shows real-time totals
- ✅ User experience is smooth and engaging

**Ready to test the complete affiliate revenue app!** 🚀
