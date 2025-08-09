#!/bin/bash

echo "🔍 FirstShot API Connectivity Test"
echo "=================================="
echo ""

# Test 1: Basic internet connectivity
echo "1. Testing basic internet connectivity..."
if ping -c 1 google.com > /dev/null 2>&1; then
    echo "✅ Internet connection: OK"
else
    echo "❌ Internet connection: FAILED"
    exit 1
fi

echo ""

# Test 2: DNS resolution
echo "2. Testing DNS resolution for firstshot.my..."
if nslookup firstshot.my > /dev/null 2>&1; then
    echo "✅ DNS resolution: OK"
    nslookup firstshot.my | grep "Address:"
else
    echo "❌ DNS resolution: FAILED"
fi

echo ""

# Test 3: HTTP connectivity to different endpoints
echo "3. Testing HTTP connectivity..."

endpoints=(
    "https://firstshot.my/api/auth/courts"
    "https://firstshot.my/api/auth"
    "https://firstshot.my/api"
    "https://firstshot.my"
    "http://firstshot.my/api/auth/courts"
    "http://firstshot.my/api/auth"
    "http://firstshot.my/api"
    "http://firstshot.my"
)

for endpoint in "${endpoints[@]}"; do
    echo "Testing: $endpoint"
    if curl -s --connect-timeout 10 --max-time 15 "$endpoint" > /dev/null 2>&1; then
        status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 15 "$endpoint")
        echo "✅ Status: $status_code"
        
        # Get response body for successful requests
        if [ "$status_code" = "200" ]; then
            echo "📄 Response preview:"
            curl -s --connect-timeout 10 --max-time 15 "$endpoint" | head -c 200
            echo ""
        fi
    else
        echo "❌ Failed to connect"
    fi
    echo ""
done

echo "4. Testing with specific headers..."
echo "Testing: https://firstshot.my/api/auth/courts"
if curl -s -H "Content-Type: application/json" -H "Accept: application/json" --connect-timeout 10 --max-time 15 "https://firstshot.my/api/auth/courts" > /dev/null 2>&1; then
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -H "Accept: application/json" --connect-timeout 10 --max-time 15 "https://firstshot.my/api/auth/courts")
    echo "✅ Status: $status_code"
    
    if [ "$status_code" = "200" ]; then
        echo "📄 Response body:"
        curl -s -H "Content-Type: application/json" -H "Accept: application/json" --connect-timeout 10 --max-time 15 "https://firstshot.my/api/auth/courts"
        echo ""
    fi
else
    echo "❌ Failed to connect"
fi

echo ""
echo "=================================="
echo "Test completed!"
echo ""
echo "Troubleshooting tips:"
echo "• If DNS fails: Check your network configuration"
echo "• If HTTP fails: Check if the server is running"
echo "• If you get HTML instead of JSON: Check API endpoint configuration"
echo "• If you get 404: Check if the route exists on the server"
echo "• If you get 500: Check server logs for errors"