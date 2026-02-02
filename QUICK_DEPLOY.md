# Quick AWS Deployment Checklist

## Pre-Deployment Checklist

- [ ] AWS Account created
- [ ] MongoDB Atlas account created and cluster set up
- [ ] OpenAI API key obtained
- [ ] ImageKit account created
- [ ] Git repository ready (GitHub/GitLab/Bitbucket)

## Deployment Steps

### 1. MongoDB Atlas Setup (5 minutes)
```
1. Create free M0 cluster
2. Create database user
3. Whitelist IP: 0.0.0.0/0 (or EC2 IP later)
4. Get connection string
```

### 2. EC2 Backend Setup (15 minutes)
```bash
# On your local machine
ssh -i your-key.pem ec2-user@your-ec2-ip

# On EC2 instance
sudo yum update -y
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs git
sudo npm install -g pm2

# Clone/upload your code
cd ~
git clone <your-repo> AI-Resume-Builder
cd AI-Resume-Builder/server

# Install and configure
npm install
nano .env  # Add all environment variables
pm2 start server.js --name resume-builder-api
pm2 save
pm2 startup  # Follow instructions
```

### 3. AWS Amplify Frontend (10 minutes)
```
1. Go to AWS Amplify Console
2. New app → Host web app
3. Connect repository
4. Add environment variable: VITE_API_URL=http://your-ec2-ip:3000
5. Deploy
```

### 4. Update CORS
```bash
# On EC2, edit server.js
nano server.js
# Update ALLOWED_ORIGINS in .env with Amplify URL
pm2 restart resume-builder-api
```

## Environment Variables Template

**Backend (.env on EC2):**
```env
PORT=3000
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net
JWT_SECRET=random-secret-key-here
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-3.5-turbo
IMAGEKIT_PRIVATE_KEY=...
ALLOWED_ORIGINS=http://localhost:5173,https://your-app.amplifyapp.com
```

**Frontend (Amplify Environment Variables):**
```
VITE_API_URL=http://your-ec2-ip:3000
```

## Quick Commands

### Check Backend Status
```bash
pm2 status
pm2 logs resume-builder-api
```

### Restart Backend
```bash
pm2 restart resume-builder-api
```

### Update Backend Code
```bash
cd ~/AI-Resume-Builder/server
git pull
npm install
pm2 restart resume-builder-api
```

## Common Issues

**Backend not accessible?**
- Check Security Group: Port 3000 open to 0.0.0.0/0
- Check PM2: `pm2 status`
- Check logs: `pm2 logs`

**CORS errors?**
- Update ALLOWED_ORIGINS in .env with Amplify URL
- Restart: `pm2 restart resume-builder-api`

**Database connection failed?**
- Check MongoDB Atlas IP whitelist
- Verify connection string in .env

## Cost: $0/month (Free Tier)

- EC2: 750 hours/month free (12 months)
- Amplify: 15GB storage, 5GB bandwidth/month free
- MongoDB Atlas: 512MB free forever
- Total: $0
