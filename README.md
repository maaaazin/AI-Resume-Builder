# AI Resume Builder

A full-stack web application for creating and managing professional resumes with AI-powered enhancements.

## Features

- 🎨 Multiple resume templates (Classic, Modern, Minimal, Minimal-Image)
- 🤖 AI-powered resume enhancement (OpenAI integration)
- 📄 PDF resume upload and data extraction
- 🎨 Customizable colors and styling
- 📱 Responsive design
- 🔒 User authentication and secure resume management
- 🌐 Public/private resume sharing

## Tech Stack

### Frontend
- React 19
- Vite
- Redux Toolkit
- Tailwind CSS
- React Router

### Backend
- Node.js + Express
- MongoDB (Mongoose)
- JWT Authentication
- OpenAI API
- ImageKit (image storage)

## Project Structure

```
AI-Resume-Builder/
├── client/          # React frontend
│   ├── src/
│   │   ├── components/  # Reusable components
│   │   ├── pages/       # Page components
│   │   └── app/         # Redux store
│   └── package.json
│
├── server/          # Express backend
│   ├── controllers/ # Business logic
│   ├── models/      # Database models
│   ├── routes/      # API routes
│   ├── configs/     # Configuration files
│   └── server.js    # Entry point
│
├── nginx.conf              # Nginx configuration
├── deploy-fullstack.sh     # Deployment script
└── EC2_FULLSTACK_DEPLOY.md # Deployment guide
```

## Quick Start (Local Development)

### Prerequisites
- Node.js 20+
- MongoDB Atlas account (or local MongoDB)
- OpenAI API key
- ImageKit account

### Backend Setup

```bash
cd server
npm install
cp env.example .env
# Edit .env with your credentials
npm run dev
```

### Frontend Setup

```bash
cd client
npm install
npm run dev
```

## Deployment

This application is designed to run on a single EC2 instance with Nginx.

See **[EC2_FULLSTACK_DEPLOY.md](./EC2_FULLSTACK_DEPLOY.md)** for complete deployment instructions.

### Quick Deploy

1. Launch EC2 instance (t2.micro free tier)
2. SSH into instance
3. Clone repository
4. Configure backend `.env` file
5. Run `./deploy-fullstack.sh`

## Environment Variables

### Backend (`server/.env`)

```env
PORT=3000
MONGODB_URI=your-mongodb-connection-string
JWT_SECRET=your-secret-key
OPENAI_API_KEY=your-openai-key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-3.5-turbo
IMAGEKIT_PRIVATE_KEY=your-imagekit-key
ALLOWED_ORIGINS=http://localhost:5173
```

### Frontend

No environment variables needed for same-domain deployment. The API will use relative `/api` URLs.

## API Endpoints

### User Routes
- `POST /api/users/register` - Register new user
- `POST /api/users/login` - User login
- `GET /api/users/data` - Get user data
- `GET /api/users/resumes` - Get user's resumes

### Resume Routes
- `POST /api/resumes/create` - Create new resume
- `PUT /api/resumes/update` - Update resume
- `DELETE /api/resumes/delete/:id` - Delete resume
- `GET /api/resumes/get/:id` - Get resume (private)
- `GET /api/resumes/public/:id` - Get public resume

### AI Routes
- `POST /api/ai/enhance-pro-sum` - Enhance professional summary
- `POST /api/ai/enhance-job-desc` - Enhance job description
- `POST /api/ai/upload-resume` - Upload and extract PDF resume

## License

MIT
