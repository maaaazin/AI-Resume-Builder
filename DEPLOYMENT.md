# AWS Free Tier Deployment Guide

This guide will help you deploy the AI Resume Builder application on AWS using free tier services.

## Architecture Overview

- **Frontend**: AWS Amplify (Free Tier)
- **Backend**: EC2 t2.micro instance (Free Tier - 750 hours/month for 12 months)
- **Database**: MongoDB Atlas (Free Tier M0 cluster)

## Prerequisites

1. AWS Account (Free Tier eligible)
2. MongoDB Atlas account (Free tier available)
3. OpenAI API key
4. ImageKit account (Free tier available)
5. Domain name (optional, can use AWS provided URLs)

---

## Step 1: Set Up MongoDB Atlas (Free Tier)

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas/register)
2. Create a free account
3. Create a new cluster (select **M0 Free Tier**)
4. Create a database user:
   - Go to **Database Access** → **Add New Database User**
   - Choose **Password** authentication
   - Save the username and password
5. Whitelist IP addresses:
   - Go to **Network Access** → **Add IP Address**
   - Click **Allow Access from Anywhere** (for EC2) or add your EC2 IP
6. Get connection string:
   - Go to **Clusters** → **Connect** → **Connect your application**
   - Copy the connection string
   - Replace `<password>` with your database user password
   - Format: `mongodb+srv://username:password@cluster0.xxxxx.mongodb.net`

---

## Step 2: Deploy Backend on EC2

### 2.1 Launch EC2 Instance

1. Go to AWS Console → **EC2** → **Launch Instance**
2. Configure instance:
   - **Name**: `resume-builder-backend`
   - **AMI**: Amazon Linux 2023 (Free Tier eligible)
   - **Instance type**: `t2.micro` (Free Tier)
   - **Key pair**: Create new or use existing (download `.pem` file)
   - **Network settings**: 
     - Allow SSH (port 22) from your IP
     - Allow HTTP (port 80) from anywhere
     - Allow HTTPS (port 443) from anywhere
     - Allow Custom TCP (port 3000) from anywhere (or just Amplify IPs)
   - **Storage**: 8GB gp3 (Free Tier: 30GB)
3. Click **Launch Instance**

### 2.2 Connect to EC2 Instance

**On Mac/Linux:**
```bash
chmod 400 your-key.pem
ssh -i your-key.pem ec2-user@your-ec2-public-ip
```

**On Windows:**
Use PuTTY or WSL with the same command.

### 2.3 Install Node.js and Dependencies

```bash
# Update system
sudo yum update -y

# Install Node.js 20.x
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Verify installation
node --version
npm --version

# Install PM2 globally (process manager)
sudo npm install -g pm2

# Install Git
sudo yum install -y git
```

### 2.4 Clone and Setup Backend

```bash
# Clone your repository (or upload files)
cd ~
git clone <your-repo-url> AI-Resume-Builder
# OR upload files using SCP:
# scp -i your-key.pem -r server/ ec2-user@your-ec2-ip:~/

cd AI-Resume-Builder/server

# Install dependencies
npm install

# Create .env file
nano .env
```

### 2.5 Configure Environment Variables

Create `.env` file with:

```env
PORT=3000
MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net
JWT_SECRET=your-super-secret-jwt-key-change-this
OPENAI_API_KEY=sk-your-openai-api-key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-3.5-turbo
IMAGEKIT_PRIVATE_KEY=your-imagekit-private-key
```

Save and exit (Ctrl+X, then Y, then Enter)

### 2.6 Configure PM2

```bash
# Start the server with PM2
pm2 start server.js --name resume-builder-api

# Save PM2 configuration
pm2 save

# Setup PM2 to start on system reboot
pm2 startup
# Follow the command it outputs (usually involves sudo)
```

### 2.7 Configure Security Group

1. Go to EC2 → **Security Groups**
2. Select your instance's security group
3. **Edit inbound rules**:
   - Add rule: Type: **Custom TCP**, Port: **3000**, Source: **0.0.0.0/0** (or restrict to Amplify IPs)

### 2.8 Get Your Backend URL

Your backend will be available at:
```
http://your-ec2-public-ip:3000
```

**Note**: For production, consider using a domain name with Route 53 or Elastic IP.

---

## Step 3: Deploy Frontend on AWS Amplify

### 3.1 Prepare Frontend

1. Update `client/src/configs/api.js` to use your backend URL:
   - You'll set this in Amplify environment variables

2. Build the frontend locally to test:
```bash
cd client
npm install
npm run build
```

### 3.2 Deploy to Amplify

1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify)
2. Click **New app** → **Host web app**
3. Connect your repository:
   - Choose your Git provider (GitHub, GitLab, Bitbucket)
   - Authorize and select your repository
   - Select branch: `main` or `master`
4. Configure build settings:
   - **App name**: `resume-builder`
   - **Environment**: `production`
   - **Build settings**: Use the provided `amplify.yml` (we'll create this)
5. Add environment variables:
   - Go to **App settings** → **Environment variables**
   - Add: `VITE_API_URL` = `http://your-ec2-public-ip:3000`
6. Deploy:
   - Click **Save and deploy**

### 3.3 Create Amplify Build Configuration

Create `amplify.yml` in the `client` directory (we'll create this file).

---

## Step 4: Configure CORS (Important!)

Update your backend `server.js` to allow Amplify domain:

```javascript
app.use(cors({
  origin: [
    'http://localhost:5173', // Local development
    'https://your-amplify-app-id.amplifyapp.com', // Amplify URL
    'https://*.amplifyapp.com' // All Amplify apps (less secure but easier)
  ],
  credentials: true
}));
```

---

## Step 5: Get Elastic IP (Recommended)

EC2 public IPs change when you restart. Get an Elastic IP:

1. EC2 → **Elastic IPs** → **Allocate Elastic IP address**
2. Select your instance → **Actions** → **Networking** → **Associate Elastic IP address**
3. Update Amplify environment variable with new IP

---

## Step 6: Optional - Add Domain Name

1. **Route 53** (Free tier: Hosted zone for first year)
   - Create hosted zone
   - Update nameservers in your domain registrar
   - Create A record pointing to Elastic IP

2. **Update Amplify**:
   - App settings → **Domain management** → Add domain

3. **Update Backend CORS** with your domain

---

## Cost Breakdown (Free Tier)

- **EC2 t2.micro**: 750 hours/month free for 12 months
- **AWS Amplify**: Free tier includes 15GB storage, 5GB bandwidth/month
- **MongoDB Atlas**: Free M0 cluster (512MB storage)
- **Elastic IP**: Free when attached to running instance
- **Route 53**: First hosted zone free for 12 months

**Total Monthly Cost**: $0 (within free tier limits)

---

## Monitoring & Maintenance

### Check Backend Logs
```bash
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

### Monitor EC2 Resources
- EC2 Dashboard → **CloudWatch** (free tier: 10 metrics)

---

## Troubleshooting

### Backend not accessible
- Check Security Group rules
- Check PM2 status: `pm2 status`
- Check logs: `pm2 logs`

### CORS errors
- Verify CORS configuration in `server.js`
- Check Amplify environment variable `VITE_API_URL`

### Database connection issues
- Verify MongoDB Atlas IP whitelist includes EC2 IP
- Check connection string in `.env`

---

## Security Best Practices

1. **Never commit `.env` files** to Git
2. Use **strong JWT_SECRET** (random string)
3. **Restrict Security Group** to specific IPs when possible
4. **Regular updates**: `sudo yum update -y`
5. **Use HTTPS** with domain (free SSL via Amplify)

---

## Next Steps

1. Set up automated backups for MongoDB Atlas
2. Configure CloudWatch alarms for monitoring
3. Set up CI/CD pipeline
4. Add custom domain with SSL
5. Implement rate limiting on API

---

## Support

If you encounter issues:
1. Check AWS CloudWatch logs
2. Check PM2 logs on EC2
3. Verify all environment variables are set
4. Check Security Group configurations
