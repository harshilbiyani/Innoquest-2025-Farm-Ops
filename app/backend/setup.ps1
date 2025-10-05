# FarmOps Backend Quick Start Script
# This script helps you set up the backend quickly

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  FarmOps Backend Setup Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if virtual environment exists
if (Test-Path "venv") {
    Write-Host "✓ Virtual environment found" -ForegroundColor Green
} else {
    Write-Host "✗ Virtual environment not found. Creating..." -ForegroundColor Yellow
    python -m venv venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
}

Write-Host ""

# Check if .env exists
if (Test-Path ".env") {
    Write-Host "✓ .env file found" -ForegroundColor Green
} else {
    Write-Host "✗ .env file not found. Creating from .env.example..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "✓ .env file created. Please update it with your MongoDB credentials" -ForegroundColor Green
    Write-Host "  Edit .env file and set your MONGO_URI" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
& .\venv\Scripts\Activate.ps1

Write-Host ""
Write-Host "Installing dependencies..." -ForegroundColor Cyan
pip install -r requirements.txt --quiet

Write-Host ""
Write-Host "====================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "To start the server, run:" -ForegroundColor Cyan
Write-Host "  python main.py" -ForegroundColor Yellow
Write-Host ""
Write-Host "Make sure MongoDB is running!" -ForegroundColor Yellow
Write-Host ""
