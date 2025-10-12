# Use official Node.js LTS image
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (with legacy peer deps)
RUN npm install --legacy-peer-deps

# Copy rest of the code
COPY . .

# Build NestJS app
RUN npm run build

# Use a smaller image for running the app
FROM node:18-alpine AS production

WORKDIR /app

# Copy only needed files
COPY package*.json ./
RUN npm install --only=production --legacy-peer-deps

# Copy built app from build stage
COPY --from=build /app/dist ./dist

# Expose app port
EXPOSE 3000

# Start the application
CMD ["node", "dist/main.js"]
