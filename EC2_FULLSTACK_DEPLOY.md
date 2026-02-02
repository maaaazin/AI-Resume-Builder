# Deploy Both Frontend & Backend on EC2 - Complete Guide

This guide shows you how to deploy both frontend and backend on the same EC2 instance using Nginx.

## Architecture

```
Internet
   ↓
EC2 Instance (Port 80)
   ↓
Nginx (Port 80)
   ├─→ Serves Frontend (React static files)
   └─→ Proxies /api → Backend (Node.js on Port 3000)
```

## Prerequisites

- ✅ EC2 instance running (t2.micro free tier)
- ✅ Security Group allows HTTP (port 80) from anywhere
- ✅ SSH access to EC2 instance

## Step 1: Launch EC2 Instance

1. Go to AWS Console → EC2 → Launch Instance
2. Configure:
   - **AMI**: Amazon Linux 2023
   - **Instance type**: t2.micro (Free Tier)
   - **Key pair**: Create/download .pem file
   - **Security Group**: 
     - Allow SSH (port 22) from your IP
     - Allow HTTP (port 80) from anywhere (0.0.0.0/0)
     - Allow HTTPS (port 443) from anywhere (optional, for SSL later)
3. Launch instance

## Step 2: Connect to EC2

```bash
# On Mac/Linux
chmod 400 your-key.pem
ssh -i your-key.pem ec2-user@your-ec2-public-ip

# On Windows (use WSL or PuTTY)
```

## Step 3: Clone Repository

```bash
cd ~
git clone <your-repo-url> AI-Resume-Builder
cd AI-Resume-Builder
```

Or upload files using SCP:
```bash
# From your local machine
scp -i your-key.pem -r . ec2-user@your-ec2-ip:~/AI-Resume-Builder/
```

## Step 4: Configure Backend Environment

```bash
cd ~/AI-Resume-Builder/server
cp env.example .env
nano .env
```

Add your environment variables:
```env
PORT=3000
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net
JWT_SECRET=your-random-secret-key
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-3.5-turbo
IMAGEKIT_PRIVATE_KEY=...
ALLOWED_ORIGINS=http://localhost:5173,http://your-ec2-ip
```

**Important**: For same-domain deployment, you can set `ALLOWED_ORIGINS` to your EC2 IP or leave it as `*` since everything is on the same domain.

Save and exit (Ctrl+X, Y, Enter)

## Step 5: Run Deployment Script

```bash
cd ~/AI-Resume-Builder
chmod +x deploy-fullstack.sh
./deploy-fullstack.sh
```

This script will:
- ✅ Install Node.js, PM2, Nginx
- ✅ Install backend dependencies
- ✅ Start backend with PM2
- ✅ Build frontend
- ✅ Configure Nginx to serve frontend
- ✅ Set up reverse proxy for API calls

## Step 6: Verify Deployment

### Check Backend
```bash
pm2 status
pm2 logs resume-builder-api
```

### Check Nginx
```bash
sudo systemctl status nginx
```

### Test in Browser
Open: `http://your-ec2-public-ip`

You should see your application!

## How It Works

### Nginx Configuration

1. **Frontend Routes** (`/`):
   - Serves static files from `/var/www/resume-builder`
   - Handles client-side routing (React Router)

2. **API Routes** (`/api`):
   - Proxies requests to `http://localhost:3000`
   - Backend runs on port 3000 (internal only)

### API Configuration

The frontend uses relative URLs:
- If `VITE_API_URL` is set → uses that
- Otherwise → uses `/api` (proxied by Nginx)

Since everything is on the same domain, no CORS issues!

## Updating Your Application

### Update Frontend

```bash
cd ~/AI-Resume-Builder/client
git pull  # or make changes
npm run build
sudo cp -r dist/* /var/www/resume-builder/
sudo systemctl reload nginx
```

### Update Backend

```bash
cd ~/AI-Resume-Builder/server
git pull  # or make changes
npm install
pm2 restart resume-builder-api
```

### Update Both

```bash
cd ~/AI-Resume-Builder
git pull
cd server && npm install && pm2 restart resume-builder-api
cd ../client && npm run build && sudo cp -r dist/* /var/www/resume-builder/ && sudo systemctl reload nginx
```

## Useful Commands

### Backend
```bash
pm2 status                    # Check status
pm2 logs resume-builder-api   # View logs
pm2 restart resume-builder-api # Restart
pm2 stop resume-builder-api    # Stop
```

### Nginx
```bash
sudo systemctl status nginx    # Check status
sudo systemctl restart nginx   # Restart
sudo systemctl reload nginx    # Reload config
sudo nginx -t                  # Test config
sudo tail -f /var/log/nginx/error.log  # View errors
```

### View Logs
```bash
# Backend logs
pm2 logs resume-builder-api

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

## Troubleshooting

### Frontend Not Loading

1. Check Nginx is running:
   ```bash
   sudo systemctl status nginx
   ```

2. Check files are in place:
   ```bash
   ls -la /var/www/resume-builder
   ```

3. Check Nginx config:
   ```bash
   sudo nginx -t
   ```

### API Calls Failing

1. Check backend is running:
   ```bash
   pm2 status
   ```

2. Check backend logs:
   ```bash
   pm2 logs resume-builder-api
   ```

3. Test backend directly:
   ```bash
   curl http://localhost:3000/
   ```

4. Check Nginx proxy:
   ```bash
   curl http://localhost/api/
   ```

### 502 Bad Gateway

- Backend might not be running
- Check: `pm2 status`
- Restart: `pm2 restart resume-builder-api`

### 404 Errors

- Frontend files not copied correctly
- Rebuild and copy:
  ```bash
  cd ~/AI-Resume-Builder/client
  npm run build
  sudo cp -r dist/* /var/www/resume-builder/
  ```

## Adding SSL/HTTPS (Optional)

### Using Let's Encrypt (Free)

```bash
# Install Certbot
sudo yum install -y certbot python3-certbot-nginx

# Get certificate (replace with your domain)
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is set up automatically
```

Then update Nginx config to listen on port 443.

## Cost

**EC2 t2.micro**: 
- Free for 750 hours/month (12 months)
- Then ~$8-10/month

**Everything else**: FREE (Nginx, PM2, etc.)

**Total**: $0/month (within free tier)

## Advantages of This Setup

✅ **Simpler**: One server, one deployment  
✅ **No CORS issues**: Same domain  
✅ **Cost-effective**: Only pay for EC2  
✅ **Easy updates**: Single server to manage  
✅ **Better performance**: No network latency between frontend/backend  

## Disadvantages

⚠️ **Single point of failure**: If EC2 goes down, everything goes down  
⚠️ **Resource sharing**: Frontend and backend share same resources  
⚠️ **Scaling**: Harder to scale frontend and backend independently  

For a small-medium app, this is perfect! 🚀
