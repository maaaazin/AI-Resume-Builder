# AWS Free Tier Deployment - Summary

## 📋 What Was Created

I've set up everything you need to deploy your AI Resume Builder on AWS for **FREE** using the free tier services.

## 📁 Files Created

1. **`DEPLOYMENT.md`** - Complete step-by-step deployment guide
2. **`QUICK_DEPLOY.md`** - Quick checklist and commands
3. **`amplify.yml`** - AWS Amplify build configuration (root directory)
4. **`server/ecosystem.config.js`** - PM2 process manager configuration
5. **`server/deploy.sh`** - Automated deployment script for EC2
6. **`server/env.example`** - Environment variables template
7. **`.gitignore`** - Updated to exclude sensitive files

## 🔧 Code Changes

- **`server/server.js`** - Updated CORS configuration to support production origins

## 🚀 Deployment Architecture

```
┌─────────────────┐
│  AWS Amplify    │  ← Frontend (Free Tier)
│  (React App)    │
└────────┬────────┘
         │
         │ HTTP Requests
         │
┌────────▼────────┐
│  EC2 t2.micro   │  ← Backend API (Free Tier - 12 months)
│  (Node.js/PM2)  │
└────────┬────────┘
         │
         │ MongoDB Connection
         │
┌────────▼────────┐
│ MongoDB Atlas   │  ← Database (Free Tier Forever)
│  (M0 Cluster)   │
└─────────────────┘
```

## 💰 Cost Breakdown

| Service | Free Tier | Monthly Cost |
|---------|-----------|--------------|
| EC2 t2.micro | 750 hrs/month (12 months) | **$0** |
| AWS Amplify | 15GB storage, 5GB bandwidth | **$0** |
| MongoDB Atlas | 512MB M0 cluster | **$0** |
| **Total** | | **$0/month** |

## ⚡ Quick Start (3 Steps)

### Step 1: Set Up MongoDB Atlas (5 min)
1. Create account at mongodb.com/cloud/atlas
2. Create M0 free cluster
3. Get connection string

### Step 2: Deploy Backend on EC2 (15 min)
```bash
# On EC2 instance
git clone <your-repo>
cd AI-Resume-Builder/server
cp env.example .env
nano .env  # Add your values
chmod +x deploy.sh
./deploy.sh
```

### Step 3: Deploy Frontend on Amplify (10 min)
1. Go to AWS Amplify Console
2. Connect your Git repository
3. Add environment variable: `VITE_API_URL=http://your-ec2-ip:3000`
4. Deploy

## 📝 Required Environment Variables

### Backend (.env on EC2)
```env
PORT=3000
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net
JWT_SECRET=your-random-secret-key
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-3.5-turbo
IMAGEKIT_PRIVATE_KEY=...
ALLOWED_ORIGINS=http://localhost:5173,https://your-app.amplifyapp.com
```

### Frontend (Amplify Console)
```
VITE_API_URL=http://your-ec2-ip:3000
```

## 🔐 Security Checklist

- [ ] Use strong JWT_SECRET (random string)
- [ ] Never commit .env files
- [ ] Restrict Security Group to specific IPs when possible
- [ ] Use Elastic IP for stable backend URL
- [ ] Enable HTTPS with custom domain (free SSL via Amplify)

## 📚 Documentation

- **Full Guide**: See `DEPLOYMENT.md` for detailed instructions
- **Quick Reference**: See `QUICK_DEPLOY.md` for commands
- **Troubleshooting**: Check `DEPLOYMENT.md` troubleshooting section

## 🛠️ Useful Commands

### On EC2 Instance
```bash
# Check status
pm2 status

# View logs
pm2 logs resume-builder-api

# Restart
pm2 restart resume-builder-api

# Update code
cd ~/AI-Resume-Builder/server
git pull
npm install
pm2 restart resume-builder-api
```

## 🎯 Next Steps After Deployment

1. **Get Elastic IP** - Prevents IP changes on restart
2. **Add Custom Domain** - Use Route 53 (free for first year)
3. **Set Up Monitoring** - CloudWatch alarms
4. **Enable Backups** - MongoDB Atlas automated backups
5. **Add SSL** - Free via Amplify for custom domains

## ⚠️ Important Notes

1. **EC2 Free Tier**: Only lasts 12 months, then ~$8-10/month
2. **Amplify Free Tier**: Limited bandwidth, but usually sufficient
3. **MongoDB Atlas**: Free tier is permanent (512MB storage)
4. **Elastic IP**: Free when attached to running instance

## 🆘 Need Help?

1. Check logs: `pm2 logs` on EC2
2. Verify Security Groups allow port 3000
3. Check CORS configuration matches Amplify URL
4. Verify all environment variables are set correctly

---

**Ready to deploy?** Start with `DEPLOYMENT.md` for the complete guide!
