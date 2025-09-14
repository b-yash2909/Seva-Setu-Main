# Supabase PWA Issue Reporting System

A Progressive Web App for civic issue reporting powered by Supabase, featuring user authentication, role-based access control, image uploads, and real-time updates.

## 🚀 Features

- **User Authentication**: Sign up/sign in with email and password
- **Role-Based Access**: Dynamic admin management through database
- **Issue Management**: Create, read, update, and delete civic issues
- **Image Uploads**: Upload images with issues using Supabase Storage
- **Real-time Updates**: Live updates using Supabase subscriptions
- **PWA Ready**: Progressive Web App capabilities
- **Responsive Design**: Works on desktop and mobile devices

## 📋 Prerequisites

- Node.js 18+ 
- npm or yarn
- Supabase CLI
- A Supabase project

## 🛠️ Installation

### 1. Clone and Install Dependencies

```bash
# Clone the repository
git clone <your-repo-url>
cd supabase-pwa-issue-reporting

# Install frontend dependencies
npm install

# Install Supabase CLI (if not already installed)
npm install -g supabase
```

### 2. Set Up Supabase Project

```bash
# Initialize Supabase in your project
supabase init

# Link to your Supabase project
supabase link --project-ref your-project-ref

# Start local Supabase (optional for development)
supabase start
```

### 3. Database Setup

```bash
# Apply the database migration
supabase db reset

# Or manually run the migration
supabase db push
```

### 4. Environment Configuration

```bash
# Copy the environment example file
cp env.example .env

# Edit .env with your Supabase credentials
```

Update `.env` with your actual Supabase project details:

```env
REACT_APP_SUPABASE_URL=https://your-project-ref.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your_anon_key_here
REACT_APP_API_BASE_URL=http://localhost:54321/functions/v1
```

### 5. Deploy Backend Functions

```bash
# Deploy Supabase Edge Functions
supabase functions deploy

# For local development, serve functions locally
supabase functions serve
```

## 🏃‍♂️ Running the Application

### Development Mode

```bash
# Start the React development server
npm start

# In another terminal, start Supabase functions locally (if needed)
supabase functions serve
```

The app will be available at `http://localhost:3000`

### Production Build

```bash
# Build the application
npm run build

# Serve the built files (using a static server)
npx serve -s build
```

## 🧪 Testing the API

### 1. User Registration

```bash
curl -X POST http://localhost:54321/functions/v1/signup \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'
```

### 2. User Login

```bash
curl -X POST http://localhost:54321/functions/v1/signin \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'
```

Save the `access_token` from the response for authenticated requests.

### 3. Create an Issue

```bash
curl -X POST http://localhost:54321/functions/v1/api/issues \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "title=Broken Streetlight" \
  -F "description=Streetlight on Main St is not working" \
  -F "location_lat=40.7128" \
  -F "location_lng=-74.0060" \
  -F "image=@/path/to/image.jpg"
```

### 4. List Issues

```bash
# Regular user sees only their issues
curl -X GET http://localhost:54321/functions/v1/api/issues \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Admin sees all issues (same endpoint, different results based on role)
```

### 5. Update Issue (Admin Only)

```bash
curl -X PATCH http://localhost:54321/functions/v1/api/issues/ISSUE_ID \
  -H "Authorization: Bearer ADMIN_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "in_progress", "progress_report": "Work order created, contractor assigned"}'
```

### 6. Delete Issue (Admin Only)

```bash
curl -X DELETE http://localhost:54321/functions/v1/api/issues/ISSUE_ID \
  -H "Authorization: Bearer ADMIN_ACCESS_TOKEN"
```

## 👥 Admin Management

### Adding Admins

To make a user an admin, insert a record into the `admins` table:

```sql
-- Using Supabase SQL Editor
INSERT INTO admins (user_id) 
VALUES ('user-uuid-here');
```

### Multiple Admin Assignment

You can have multiple admins by adding multiple records:

```sql
-- Add multiple admins
INSERT INTO admins (user_id) VALUES 
  ('admin1-uuid'),
  ('admin2-uuid'),
  ('admin3-uuid');
```

### Checking Admin Status

```sql
-- Check if a user is an admin
SELECT EXISTS(
  SELECT 1 FROM admins 
  WHERE user_id = 'user-uuid-here'
) as is_admin;
```

## 🖼️ Image Upload Testing

### 1. Upload via API

```bash
# Test image upload with issue creation
curl -X POST http://localhost:54321/functions/v1/api/issues \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "title=Test Issue with Image" \
  -F "description=Testing image upload functionality" \
  -F "image=@test-image.jpg"
```

### 2. Verify Image URL

Check the response for the `image_url` field. It should be a public URL like:
```
https://your-project-ref.supabase.co/storage/v1/object/public/issue-images/user-id/issue-id/timestamp_filename.jpg
```

### 3. Test Image Access

Open the `image_url` in a browser to verify the image is accessible.

## 📱 PWA Features

The app includes PWA capabilities:

- **Service Worker**: Caches resources for offline functionality
- **Web App Manifest**: Enables installation on mobile devices
- **Responsive Design**: Works on all screen sizes
- **Offline Support**: Basic offline functionality

## 🔧 Development Tips

### Local Development

1. Use `supabase start` to run a local Supabase instance
2. Use `supabase functions serve` for local function development
3. Update `.env` to point to local URLs during development

### Database Queries

Use the Supabase SQL Editor for direct database queries:

```sql
-- View all issues
SELECT * FROM issues ORDER BY created_at DESC;

-- View all admins with user details
SELECT a.*, u.email 
FROM admins a 
JOIN users u ON a.user_id = u.id;

-- Check user permissions
SELECT 
  u.email,
  EXISTS(SELECT 1 FROM admins WHERE user_id = u.id) as is_admin
FROM users u;
```

### Real-time Subscriptions

The app uses Supabase real-time subscriptions for live updates:

```typescript
// Subscribe to issue changes
const subscription = supabase
  .from('issues')
  .on('*', (payload) => {
    console.log('Issue changed:', payload)
  })
  .subscribe()
```

## 🚀 Deployment

### Frontend Deployment

Deploy to platforms like Vercel, Netlify, or GitHub Pages:

```bash
npm run build
# Upload the 'build' folder to your hosting platform
```

### Backend Deployment

Deploy Supabase Edge Functions:

```bash
supabase functions deploy
```

### Environment Variables

Update your production environment variables:

```env
REACT_APP_SUPABASE_URL=https://your-project-ref.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your_production_anon_key
REACT_APP_API_BASE_URL=https://your-project-ref.supabase.co/functions/v1
```

## 🐛 Troubleshooting

### Common Issues

1. **CORS Errors**: Ensure your Supabase project allows your domain
2. **Authentication Issues**: Check that JWT tokens are valid and not expired
3. **Image Upload Failures**: Verify storage bucket policies and file size limits
4. **Permission Denied**: Check RLS policies and admin status

### Debug Mode

Enable debug logging:

```typescript
// In your service calls
console.log('API Response:', response)
console.log('Error:', error)
```

## 📚 API Reference

### Authentication Endpoints

- `POST /signup` - Create new user account
- `POST /signin` - Authenticate user and get JWT

### Issue Endpoints

- `POST /api/issues` - Create new issue (authenticated)
- `GET /api/issues` - List issues (own for users, all for admins)
- `GET /api/issues/:id` - Get single issue
- `PATCH /api/issues/:id` - Update issue (admin only)
- `DELETE /api/issues/:id` - Delete issue (admin only)

### Utility Endpoints

- `GET /health` - Health check

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:

1. Check the troubleshooting section
2. Review Supabase documentation
3. Open an issue in the repository
4. Contact the development team

---

**Happy coding! 🎉**