#!/bin/bash

# AWS EC2 Deployment Script for Resume Builder Backend
# Run this script on your EC2 instance after connecting via SSH

echo "🚀 Starting Resume Builder Backend Deployment..."

# Update system
echo "📦 Updating system packages..."
sudo yum update -y

# Install Node.js 20.x
echo "📦 Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo yum install -y nodejs
else
    echo "✅ Node.js already installed: $(node --version)"
fi

# Install PM2
echo "📦 Installing PM2..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
else
    echo "✅ PM2 already installed"
fi

# Install Git if not present
echo "📦 Installing Git..."
sudo yum install -y git

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo "📝 Please create .env file with required environment variables"
    echo "   You can copy env.example: cp env.example .env"
    echo "   Then edit .env with your actual values"
    exit 1
fi

# Install dependencies
echo "📦 Installing npm dependencies..."
npm install

# Create logs directory
mkdir -p logs

# Start/restart the application
echo "🔄 Starting application with PM2..."
pm2 delete resume-builder-api 2>/dev/null || true
pm2 start server.js --name resume-builder-api

# Save PM2 configuration
pm2 save

# Setup PM2 startup (if not already done)
echo "⚙️  Setting up PM2 startup..."
pm2 startup | grep -v "PM2" | bash || echo "PM2 startup already configured"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Application Status:"
pm2 status
echo ""
echo "📝 Useful commands:"
echo "   - View logs: pm2 logs resume-builder-api"
echo "   - Restart: pm2 restart resume-builder-api"
echo "   - Stop: pm2 stop resume-builder-api"
echo "   - Status: pm2 status"
echo ""
echo "🌐 Your backend should be running on port 3000"
echo "   Make sure your Security Group allows inbound traffic on port 3000"
