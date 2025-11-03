# Network Error Troubleshooting Guide

## Current Status
✅ Build succeeded
✅ Network entitlements enabled
✅ Better error messages added

## What Changed

### Improved Error Handling
The AI service now provides detailed error messages:
- Shows the actual network error details
- Logs HTTP status codes
- Parses API error messages
- Prints debug info to console

### Debug Logs
When you run the app from Xcode, you'll now see:
```
Network error: [detailed error]
Error code: [code]
Error domain: [domain]
HTTP Status: [status code]
API Error: [message from Gemini]
```

## Troubleshooting Steps

### 1. Check Your API Key

**Get a valid API key:**
1. Go to: https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key (starts with "AIza...")

**Verify in app:**
- Settings → AI Assistant
- Paste your API key
- It should save automatically

### 2. Test API Key Manually

Run this command in Terminal (replace YOUR_KEY):
```bash
./test_gemini_api.sh YOUR_API_KEY
```

Or test directly with curl:
```bash
curl -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=YOUR_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
```

**Expected response:**
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "Hello! How can I help you today?"
          }
        ]
      }
    }
  ]
}
```

### 3. Check Network Connection

**Test internet:**
```bash
ping -c 3 generativelanguage.googleapis.com
```

**Test DNS:**
```bash
nslookup generativelanguage.googleapis.com
```

### 4. Check Console Logs

**In Xcode:**
1. Run the app (Cmd+R)
2. Open the Debug Console (Cmd+Shift+Y)
3. Try sending an AI message
4. Look for error messages in the console

**Common errors:**

#### "Network error: The Internet connection appears to be offline"
- Check your WiFi/Ethernet connection
- Try opening a website in Safari

#### "Network error: Could not connect to the server"
- Firewall might be blocking the connection
- VPN might be interfering
- Try disabling VPN temporarily

#### "API Error: API key not valid"
- Your API key is incorrect
- Get a new one from https://makersuite.google.com/app/apikey

#### "HTTP 403"
- API key doesn't have permission
- Make sure Gemini API is enabled for your key

#### "HTTP 429"
- Rate limit exceeded
- Wait a few minutes and try again

### 5. Check Firewall Settings

**macOS Firewall:**
1. System Settings → Network → Firewall
2. Make sure StrontiumNotes is allowed
3. Or temporarily disable firewall to test

**Little Snitch / Other Firewalls:**
- Allow connections to: `generativelanguage.googleapis.com`
- Port: 443 (HTTPS)

### 6. Verify Entitlements

The app should have these entitlements (already configured):
```xml
<key>com.apple.security.network.client</key>
<true/>
```

Check in: `Strontium Notes/Strontium_Notes.entitlements`

### 7. Try a Different Network

Sometimes corporate/school networks block API calls:
- Try using your phone's hotspot
- Try a different WiFi network
- Try at home vs. work

## Still Not Working?

### Check Xcode Console Output

Run the app and look for these debug messages:
```
Network error: [details]
Error code: [number]
Error domain: [domain]
HTTP Status: [code]
API Error: [message]
Response JSON keys: [keys]
```

### Common Issues

**Issue:** "The resource could not be loaded because the App Transport Security policy requires the use of a secure connection"
**Fix:** Already handled - we use HTTPS

**Issue:** "A server with the specified hostname could not be found"
**Fix:** DNS issue - check internet connection

**Issue:** "The request timed out"
**Fix:** Slow connection - try again or check network

**Issue:** "Could not connect to the server"
**Fix:** Firewall or network blocking - check firewall settings

## API Endpoint Details

**URL:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`

**Method:** POST

**Headers:**
- Content-Type: application/json

**Body:**
```json
{
  "contents": [{
    "parts": [{
      "text": "Your message here"
    }]
  }],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 2048
  }
}
```

## Next Steps

1. **Run the app from Xcode** (not just build)
2. **Open the Debug Console** (Cmd+Shift+Y)
3. **Try sending an AI message**
4. **Copy the error from console** and share it

The improved error messages will tell us exactly what's wrong!

## Quick Test

To quickly test if the API works on your machine:

```bash
# Test 1: Can you reach Google?
ping -c 3 google.com

# Test 2: Can you reach Gemini API?
ping -c 3 generativelanguage.googleapis.com

# Test 3: Can you make an API call?
curl -I https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent
```

All three should succeed for the AI to work.
