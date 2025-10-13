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
COPY nest-cli.json* ./

# Copy source code
COPY src ./src

# Build NestJS application
RUN npm run build

# Production stage
FROM node:18-alpine as production

# Install runtime dependencies for canvas AND build tools for production install
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    cairo \
    cairo-dev \
    jpeg \
    jpeg-dev \
    pango \
    pango-dev \
    giflib \
    giflib-dev \
    pixman \
    pixman-dev

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies (still needs build tools for canvas)
RUN npm install --only=production --legacy-peer-deps

# Copy built application from build stage
COPY --from=build /app/dist ./dist

# Copy node_modules from build stage (this includes canvas already built)
COPY --from=build /app/node_modules ./node_modules

EXPOSE 8080

# Use the production start script from package.json
CMD ["npm", "run", "start:prod"]
