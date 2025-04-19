# # Use an official Node.js runtime as a parent image
# FROM node:16

# # Set the working directory in the container
# WORKDIR /app

# # Copy package.json and package-lock.json to the working directory
# COPY package*.json ./

# # Install app dependencies, including Material-UI 5
# RUN npm install

# # Copy the rest of the application code to the working directory
# COPY . .

# # Build the React app
# RUN npm run build

# # Expose the port that the app will run on (adjust if needed)
# EXPOSE 3000

# # Define the command to start the app
# CMD ["npm", "start"]


# Stage 1: Build the React app
FROM node:16-slim AS builder

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# # Install build dependencies (required for native dependencies, if any)
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     python3 \
#     build-essential \
#     && rm -rf /var/lib/apt/lists/*

# Install app dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Build the React app
RUN npm run build

# # Install serve to serve the static files
# RUN npm install -g serve

# # Copy the build output from the builder stage
# COPY --from=builder /app/build ./build

# Expose the port
EXPOSE 3000

# Serve the app
CMD ["npm", "start"]