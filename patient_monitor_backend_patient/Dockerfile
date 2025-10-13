# Build stage
FROM node:18-alpine as build

# Install dependencies required for canvas and node-gyp
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    cairo-dev \
    jpeg-dev \
    pango-dev \
    giflib-dev \
    pixman-dev

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev for building)
RUN npm install --legacy-peer-deps

# Copy TypeScript config
COPY tsconfig*.json ./
COPY nest-cli.json ./

# Copy source code
COPY src ./src

# Build NestJS application
RUN npm run build

# Production stage
FROM node:18-alpine as production

# Install runtime dependencies for canvas
RUN apk add --no-cache \
    cairo \
    jpeg \
    pango \
    giflib \
    pixman

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm install --only=production --legacy-peer-deps

# Copy built application from build stage
COPY --from=build /app/dist ./dist

# Copy any necessary runtime files
COPY --from=build /app/node_modules ./node_modules

EXPOSE 8080

# Use the production start script from package.json
CMD ["npm", "run", "start:prod"]
