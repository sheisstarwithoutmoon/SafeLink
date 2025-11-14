@echo off
echo Setting up SMS functionality for Safe Ride App
echo.

echo Step 1: Installing Firebase Functions dependencies...
cd functions
call npm install
if %errorlevel% neq 0 (
    echo Error installing dependencies
    pause
    exit /b 1
)

echo.
echo Step 2: Building TypeScript...
call npm run build
if %errorlevel% neq 0 (
    echo Error building TypeScript
    pause
    exit /b 1
)

cd ..

echo.
echo Step 3: Deploying Firebase Functions...
firebase deploy --only functions
if %errorlevel% neq 0 (
    echo Error deploying functions
    echo Please check your Firebase configuration
    pause
    exit /b 1
)

echo.
echo Step 4: Installing Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Error installing Flutter dependencies
    pause
    exit /b 1
)

echo.
echo Setup complete!
echo.
echo IMPORTANT: You still need to configure Twilio:
echo 1. Get your Twilio credentials from https://console.twilio.com/
echo 2. Run these commands:
echo    firebase functions:config:set twilio.account_sid="YOUR_ACCOUNT_SID"
echo    firebase functions:config:set twilio.auth_token="YOUR_AUTH_TOKEN"
echo    firebase functions:config:set twilio.phone_number="YOUR_TWILIO_PHONE_NUMBER"
echo 3. Deploy again: firebase deploy --only functions
echo.
echo See SMS_SETUP_GUIDE.md for detailed instructions.
echo.
pause
