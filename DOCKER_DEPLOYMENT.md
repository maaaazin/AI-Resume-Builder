# Docker Deployment Guide for AI Resume Builder

This guide will help you dockerize and deploy your application on EC2 using Docker and Docker Compose.

## Prerequisites

- ✅ EC2 instance running (t2.micro or larger)
- ✅ SSH access to EC2
- ✅ Docker and Docker Compose installed on EC2

## Architecture

```
┌─────────────────────────────────┐
│     EC2 Instance                │
│                                 │
│  ┌──────────────────────────┐  │
│  │  Docker Compose          │  │
│  │                          │  │
│  │  ┌──────────┐           │  │
│  │  │ Frontend │ :80       │  │
│  │  │ (Nginx)  │           │  │
│  │  └────┬─────┘           │  │
│  │       │                 │  │
│  │  ┌────▼─────┐           │  │
│  │  │ Backend   │ :3000    │  │
│  │  │ (Node.js) │           │  │
│  │  └──────────┘           │  │
│  └──────────────────────────┘  │
└─────────────────────────────────┘
```

## Step 1: Install Docker on EC2

SSH into your EC2 instance and run:

```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group (so you don't need sudo)
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Log out and log back in for group changes to take effect
exit
```

Then SSH back in.

## Step 2: Clone Repository

```bash
cd ~
git clone <your-repo-url> AI-Resume-Builder
cd AI-Resume-Builder
```

## Step 3: Create Environment File

Create a `.env` file in the project root:

```bash
nano .env
```

Add your environment variables:

```env
# MongoDB
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this

# OpenAI
OPENAI_API_KEY=sk-your-openai-api-key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-3.5-turbo

# ImageKit
IMAGEKIT_PRIVATE_KEY=your-imagekit-private-key

# CORS (optional - use * for same-domain)
ALLOWED_ORIGINS=*
```

Save and exit (Ctrl+X, Y, Enter)

## Step 4: Build and Start Containers

### Option A: Simple Setup (Frontend + Backend)

```bash
# Build and start services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

This will:
- Build and start backend on port 3000
- Build and start frontend on port 80
- Frontend will be accessible at `http://your-ec2-ip`

### Option B: With Separate Nginx (Optional)

If you want a separate nginx container as reverse proxy:

```bash
# Start with nginx profile
docker-compose --profile with-nginx up -d
```

This adds an nginx container on port 8080.

## Step 5: Configure Security Group

Make sure your EC2 Security Group allows:
- **Port 80** (HTTP) from `0.0.0.0/0`
- **Port 3000** (Backend - optional, if you want direct access)
- **Port 22** (SSH) from your IP

## Step 6: Verify Deployment

### Check Containers

```bash
docker-compose ps
```

You should see:
- `resume-builder-backend` - Running
- `resume-builder-frontend` - Running

### Check Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Test in Browser

Open: `http://your-ec2-public-ip`

## Common Docker Commands

### Start/Stop Services

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Restart specific service
docker-compose restart backend
```

### View Logs

```bash
# Follow logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100

# Specific service
docker-compose logs -f backend
```

### Rebuild After Code Changes

```bash
# Rebuild and restart
docker-compose up -d --build

# Rebuild specific service
docker-compose up -d --build frontend
```

### Update Code

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose up -d --build

# Or restart without rebuild (if no dependency changes)
docker-compose restart
```

## Updating Your Application

### Method 1: Git Pull + Rebuild

```bash
cd ~/AI-Resume-Builder
git pull origin main
docker-compose up -d --build
```

### Method 2: Restart Only (if no code changes)

```bash
docker-compose restart
```

## Troubleshooting

### Containers Not Starting

```bash
# Check logs
docker-compose logs

# Check container status
docker-compose ps

# Check Docker daemon
sudo systemctl status docker
```

### Port Already in Use

If port 80 or 3000 is already in use:

```bash
# Find what's using the port
sudo lsof -i :80
sudo lsof -i :3000

# Stop conflicting service or change ports in docker-compose.yml
```

### Backend Connection Issues

```bash
# Check backend logs
docker-compose logs backend

# Test backend directly
curl http://localhost:3000/

# Check if MongoDB connection is working
docker-compose exec backend node -e "console.log(process.env.MONGODB_URI)"
```

### Frontend Not Loading

```bash
# Check frontend logs
docker-compose logs frontend

# Verify nginx is running in container
docker-compose exec frontend nginx -t

# Check if files are built
docker-compose exec frontend ls -la /usr/share/nginx/html
```

### Permission Issues

```bash
# Fix Docker permissions
sudo usermod -aG docker ec2-user
# Log out and back in

# Or use sudo (not recommended)
sudo docker-compose up -d
```

## Environment Variables

### Update Environment Variables

1. Edit `.env` file:
   ```bash
   nano .env
   ```

2. Restart services:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### View Environment Variables

```bash
# Check what env vars are set
docker-compose exec backend env | grep MONGODB
```

## Production Optimizations

### 1. Use Docker Compose Override

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  backend:
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
  
  frontend:
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

Use it:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 2. Set Up Log Rotation

Docker handles this automatically with the logging driver above.

### 3. Resource Limits

Add to `docker-compose.yml`:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

### 4. Health Checks

Already included in `docker-compose.yml` for backend.

## Monitoring

### View Resource Usage

```bash
# Container stats
docker stats

# Specific container
docker stats resume-builder-backend
```

### Check Container Health

```bash
# Health check status
docker inspect resume-builder-backend | grep -A 10 Health
```

## Backup and Restore

### Backup Environment

```bash
# Backup .env file
cp .env .env.backup
```

### Backup Volumes (if you add any)

```bash
# Create backup
docker run --rm -v resume-builder-data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data

# Restore
docker run --rm -v resume-builder-data:/data -v $(pwd):/backup alpine tar xzf /backup/backup.tar.gz -C /
```

## Clean Up

### Remove All Containers and Images

```bash
# Stop and remove containers
docker-compose down

# Remove images
docker-compose down --rmi all

# Remove volumes (if any)
docker-compose down -v

# Clean up unused Docker resources
docker system prune -a
```

## Advantages of Docker Deployment

✅ **Consistency**: Same environment everywhere  
✅ **Isolation**: Services don't interfere with each other  
✅ **Easy Updates**: Just rebuild and restart  
✅ **Portability**: Run anywhere Docker runs  
✅ **Scalability**: Easy to scale individual services  
✅ **Rollback**: Easy to revert to previous versions  

## Cost

**Docker itself**: FREE  
**EC2 t2.micro**: Free tier (750 hours/month for 12 months)  
**Total**: $0/month (within free tier)

## Next Steps

1. ✅ Set up automated backups
2. ✅ Configure monitoring/alerting
3. ✅ Set up CI/CD for automatic deployments
4. ✅ Add SSL/HTTPS with Let's Encrypt
5. ✅ Set up log aggregation

---

**Your application is now running in Docker! 🐳**
