#!/bin/bash

# Test script to verify Gemini API is accessible
# Replace YOUR_API_KEY with your actual API key

API_KEY="${1:-YOUR_API_KEY}"

if [ "$API_KEY" = "YOUR_API_KEY" ]; then
    echo "Usage: ./test_gemini_api.sh YOUR_API_KEY"
    exit 1
fi

echo "Testing Gemini API..."
echo "Endpoint: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
echo ""

curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": [{
      "parts": [{
        "text": "Say hello"
      }]
    }]
  }' | python3 -m json.tool

echo ""
echo "If you see a response with 'candidates', the API is working!"
echo "If you see an error, check:"
echo "  1. Your API key is correct"
echo "  2. You have internet connection"
echo "  3. The API key has Gemini API enabled"
