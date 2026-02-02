#!/bin/bash

# Full Stack Deployment Script for Resume Builder
# Deploys both frontend and backend on the same EC2 instance
# Run this script on your EC2 instance after connecting via SSH

echo "🚀 Starting Full Stack Deployment (Frontend + Backend)..."

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

# Install Nginx
echo "📦 Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo yum install -y nginx
else
    echo "✅ Nginx already installed"
fi

# Install Git if not present
echo "📦 Installing Git..."
sudo yum install -y git

# Navigate to project directory
PROJECT_DIR="$HOME/AI-Resume-Builder"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory not found at $PROJECT_DIR"
    echo "Please clone your repository first:"
    echo "  git clone <your-repo-url> $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# ============================================
# BACKEND SETUP
# ============================================
echo ""
echo "🔧 Setting up Backend..."

cd server

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo "📝 Please create .env file with required environment variables"
    echo "   You can copy env.example: cp env.example .env"
    echo "   Then edit .env with your actual values"
    exit 1
fi

# Install backend dependencies
echo "📦 Installing backend dependencies..."
npm install

# Create logs directory
mkdir -p logs

# Start/restart backend with PM2
echo "🔄 Starting backend with PM2..."
pm2 delete resume-builder-api 2>/dev/null || true
pm2 start server.js --name resume-builder-api

# ============================================
# FRONTEND SETUP
# ============================================
echo ""
echo "🔧 Setting up Frontend..."

cd ../client

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
npm install

# Build frontend
echo "🏗️  Building frontend..."
npm run build

if [ ! -d "dist" ]; then
    echo "❌ Frontend build failed - dist directory not found"
    exit 1
fi

# ============================================
# NGINX SETUP
# ============================================
echo ""
echo "🔧 Configuring Nginx..."

# Create web directory
sudo mkdir -p /var/www/resume-builder

# Copy built frontend files
echo "📦 Copying frontend files to web directory..."
sudo cp -r dist/* /var/www/resume-builder/

# Copy nginx configuration
echo "📦 Setting up Nginx configuration..."
sudo cp "$PROJECT_DIR/nginx.conf" /etc/nginx/conf.d/resume-builder.conf

# Test nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Nginx configuration test failed!"
    exit 1
fi

# Start and enable Nginx
echo "🔄 Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# ============================================
# FIREWALL CONFIGURATION
# ============================================
echo ""
echo "🔧 Configuring firewall..."

# Allow HTTP (port 80)
sudo firewall-cmd --permanent --add-service=http 2>/dev/null || true
sudo firewall-cmd --reload 2>/dev/null || true

# ============================================
# FINALIZE
# ============================================
# Save PM2 configuration
pm2 save

# Setup PM2 startup (if not already done)
echo "⚙️  Setting up PM2 startup..."
pm2 startup | grep -v "PM2" | bash || echo "PM2 startup already configured"

echo ""
echo "✅ Full Stack Deployment Complete!"
echo ""
echo "📊 Application Status:"
pm2 status
echo ""
echo "🌐 Your application is now available at:"
echo "   http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo ""
echo "📝 Useful commands:"
echo "   Backend logs: pm2 logs resume-builder-api"
echo "   Restart backend: pm2 restart resume-builder-api"
echo "   Nginx status: sudo systemctl status nginx"
echo "   Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "   Restart Nginx: sudo systemctl restart nginx"
echo ""
echo "🔄 To update frontend after changes:"
echo "   cd $PROJECT_DIR/client"
echo "   npm run build"
echo "   sudo cp -r dist/* /var/www/resume-builder/"
echo "   sudo systemctl reload nginx"
echo ""
echo "⚠️  Make sure your EC2 Security Group allows:"
echo "   - Inbound HTTP (port 80) from 0.0.0.0/0"
echo "   - Inbound HTTPS (port 443) from 0.0.0.0/0 (if using SSL)"
