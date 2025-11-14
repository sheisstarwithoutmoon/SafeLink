Write-Host "Setting up SMS functionality for Safe Ride App" -ForegroundColor Green
Write-Host ""

Write-Host "Step 1: Installing Firebase Functions dependencies..." -ForegroundColor Yellow
Set-Location functions
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error installing dependencies" -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit 1
}

Write-Host ""
Write-Host "Step 2: Building TypeScript..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error building TypeScript" -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit 1
}

Set-Location ..

Write-Host ""
Write-Host "Step 3: Deploying Firebase Functions..." -ForegroundColor Yellow
firebase deploy --only functions
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error deploying functions" -ForegroundColor Red
    Write-Host "Please check your Firebase configuration" -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit 1
}

Write-Host ""
Write-Host "Step 4: Installing Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error installing Flutter dependencies" -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit 1
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: You still need to configure Twilio:" -ForegroundColor Yellow
Write-Host "1. Get your Twilio credentials from https://console.twilio.com/"
Write-Host "2. Run these commands:"
Write-Host "   firebase functions:config:set twilio.account_sid=`"YOUR_ACCOUNT_SID`""
Write-Host "   firebase functions:config:set twilio.auth_token=`"YOUR_AUTH_TOKEN`""
Write-Host "   firebase functions:config:set twilio.phone_number=`"YOUR_TWILIO_PHONE_NUMBER`""
Write-Host "3. Deploy again: firebase deploy --only functions"
Write-Host ""
Write-Host "See SMS_SETUP_GUIDE.md for detailed instructions." -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to continue"
