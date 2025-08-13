# Use our shared base
FROM myapp-base:latest

# Copy frontend-specific dependencies
COPY package.json ./
RUN npm install --production

# Copy application files
COPY server.js ./
COPY index.html ./

# Expose port
EXPOSE 8080

# Start the application
CMD ["npm", "start"]
