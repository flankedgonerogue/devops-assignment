# Multi-stage Dockerfile for React + Node/Express Application

# Stage 1: Build React application
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build React application
RUN npm run build-react

# Stage 2: Production image
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy built React app from builder stage
COPY --from=builder /app/build ./build

# Copy server files
COPY index.js carts.js ./

# Expose port 80
EXPOSE 80

# Set environment variable for port
ENV PORT=80
ENV NODE_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:80', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the server
CMD ["node", "index.js"]

