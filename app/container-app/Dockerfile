# Use official Node.js LTS image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY server.js ./

# Expose port
EXPOSE 8080

# Set NODE_ENV
ENV NODE_ENV=production

# Run as non-root user for security
USER node

# Start the application
CMD ["node", "server.js"]
