# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies
RUN npm ci

# Copy all source files
COPY . .

# Build the frontend with Vite
RUN npm run build

# Production stage
FROM node:22-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy built frontend from builder stage
COPY --from=builder /app/dist ./dist

# Copy backend source code
COPY src/ ./src/

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose port (Cloud Run uses PORT environment variable)
ENV PORT=3000
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost:3000/api/health || exit 1

# Start the application
CMD ["node", "src/index.js"]