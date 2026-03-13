#!/bin/bash

echo "========================================"
echo "HR System Mock Server"
echo "========================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "[ERROR] Node.js is not installed!"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "[INFO] Installing dependencies..."
    npm install
    echo ""
fi

echo "[INFO] Starting JSON Server on port 5000..."
echo "[INFO] Mock API will be available at: http://localhost:5000/api"
echo ""
echo "Press Ctrl+C to stop the server"
echo "========================================"
echo ""

# Start JSON Server
npm start
