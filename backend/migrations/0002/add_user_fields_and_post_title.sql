-- Add name fields to User (added in earlier commits)
ALTER TABLE "User" ADD COLUMN "firstName" TEXT NOT NULL DEFAULT '';
ALTER TABLE "User" ADD COLUMN "middleName" TEXT;
ALTER TABLE "User" ADD COLUMN "lastName" TEXT NOT NULL DEFAULT '';

-- Add title, imageUrl, category to Post
ALTER TABLE "Post" ADD COLUMN "title" TEXT;
ALTER TABLE "Post" ADD COLUMN "imageUrl" TEXT;
ALTER TABLE "Post" ADD COLUMN "category" TEXT NOT NULL DEFAULT 'General';

-- Add state and city to User
ALTER TABLE "User" ADD COLUMN "state" TEXT;
ALTER TABLE "User" ADD COLUMN "city" TEXT;
