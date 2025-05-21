# Base image
FROM node:23.0-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Build the application (if needed)
# RUN npm run build

# Expose the port the app runs on
EXPOSE 5000

# Set environment variables
ENV NODE_ENV=development

# Command to run the application
CMD ["npm", "run", "dev"]