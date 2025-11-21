#!/bin/bash

# MQTT Testing Script

echo "🧪 MQTT Testing Menu"
echo "===================="
echo ""
echo "1. Test MQTT Connection (Listen for messages)"
echo "2. Send Simulated Earthquake Data"
echo "3. Run Both (Listener + Simulator)"
echo "4. Check Backend Dependencies"
echo ""
read -p "Select option (1-4): " option

case $option in
  1)
    echo ""
    echo "🎧 Starting MQTT Listener..."
    echo "Press Ctrl+C to stop"
    echo ""
    cd backend && node test-mqtt-connection.js
    ;;
  2)
    echo ""
    echo "📡 Sending Simulated Earthquake Data..."
    echo ""
    cd backend && node simulate-earthquake.js
    ;;
  3)
    echo ""
    echo "🚀 Starting Listener in background..."
    cd backend && node test-mqtt-connection.js &
    LISTENER_PID=$!
    
    echo "Waiting 2 seconds..."
    sleep 2
    
    echo ""
    echo "📡 Sending Simulated Data..."
    cd backend && node simulate-earthquake.js
    
    echo ""
    echo "⏸️  Stopping listener..."
    kill $LISTENER_PID 2>/dev/null
    echo "✅ Done!"
    ;;
  4)
    echo ""
    echo "📦 Checking Node.js dependencies..."
    cd backend
    if [ -f "package.json" ]; then
      echo "✅ package.json found"
      if [ -d "node_modules" ]; then
        echo "✅ node_modules exists"
        if [ -d "node_modules/mqtt" ]; then
          echo "✅ mqtt package installed"
        else
          echo "❌ mqtt package not found"
          echo "Run: cd backend && npm install"
        fi
      else
        echo "❌ node_modules not found"
        echo "Run: cd backend && npm install"
      fi
    else
      echo "❌ package.json not found"
    fi
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac
