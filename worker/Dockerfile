# Use our shared base
FROM myapp-base:latest

# Copy worker-specific dependencies
COPY package.json ./
RUN npm install --production

# Copy application code
COPY worker.js ./

# Start the application
CMD ["npm", "start"]
