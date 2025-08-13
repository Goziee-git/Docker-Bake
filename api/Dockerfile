# Use our shared base
FROM myapp-base:latest

# Copy API-specific dependencies
COPY package.json ./
RUN npm install --production

# Copy application code
COPY server.js ./

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
