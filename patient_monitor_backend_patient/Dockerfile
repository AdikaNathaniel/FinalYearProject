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

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .

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

# Copy package files and node_modules from build stage
COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app .

EXPOSE 3000

CMD ["node", "server.js"]