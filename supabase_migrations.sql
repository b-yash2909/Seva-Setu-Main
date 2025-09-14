-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create admins table
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create issues table
CREATE TABLE issues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    image_path VARCHAR(500),
    image_url VARCHAR(500),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    progress_report TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_admins_user_id ON admins(user_id);
CREATE INDEX idx_issues_author_id ON issues(author_id);
CREATE INDEX idx_issues_status ON issues(status);
CREATE INDEX idx_issues_created_at ON issues(created_at);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at on issues table
CREATE TRIGGER update_issues_updated_at 
    BEFORE UPDATE ON issues 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create storage bucket for issue images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('issue-images', 'issue-images', true);

-- Create storage policy for issue images (authenticated users can upload)
CREATE POLICY "Authenticated users can upload issue images" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'issue-images' AND 
    auth.role() = 'authenticated'
);

-- Create storage policy for public read access to issue images
CREATE POLICY "Public can view issue images" ON storage.objects
FOR SELECT USING (bucket_id = 'issue-images');

-- Create storage policy for users to update their own images
CREATE POLICY "Users can update their own issue images" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'issue-images' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Create storage policy for users to delete their own images
CREATE POLICY "Users can delete their own issue images" ON storage.objects
FOR DELETE USING (
    bucket_id = 'issue-images' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Create RLS policies for users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile" ON users
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
FOR UPDATE USING (auth.uid() = id);

-- Create RLS policies for admins table
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all admins" ON admins
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM admins 
        WHERE user_id = auth.uid()
    )
);

-- Create RLS policies for issues table
ALTER TABLE issues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own issues" ON issues
FOR SELECT USING (auth.uid() = author_id);

CREATE POLICY "Admins can view all issues" ON issues
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM admins 
        WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Users can create their own issues" ON issues
FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Admins can update any issue" ON issues
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM admins 
        WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Admins can delete any issue" ON issues
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM admins 
        WHERE user_id = auth.uid()
    )
);

-- Create function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admins 
        WHERE user_id = user_uuid
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get user issues with pagination
CREATE OR REPLACE FUNCTION get_user_issues(
    user_uuid UUID,
    limit_count INTEGER DEFAULT 20,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    title VARCHAR(255),
    description TEXT,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    image_path VARCHAR(500),
    image_url VARCHAR(500),
    author_id UUID,
    status VARCHAR(50),
    progress_report TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    IF is_admin(user_uuid) THEN
        RETURN QUERY
        SELECT i.id, i.title, i.description, i.location_lat, i.location_lng,
               i.image_path, i.image_url, i.author_id, i.status, i.progress_report,
               i.created_at, i.updated_at
        FROM issues i
        ORDER BY i.created_at DESC
        LIMIT limit_count OFFSET offset_count;
    ELSE
        RETURN QUERY
        SELECT i.id, i.title, i.description, i.location_lat, i.location_lng,
               i.image_path, i.image_url, i.author_id, i.status, i.progress_report,
               i.created_at, i.updated_at
        FROM issues i
        WHERE i.author_id = user_uuid
        ORDER BY i.created_at DESC
        LIMIT limit_count OFFSET offset_count;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
