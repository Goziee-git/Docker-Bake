const express = require('express');
const path = require('path');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 8080;
const API_URL = process.env.API_URL || 'http://api:3000';

// Serve static files
app.use(express.static(__dirname));

// Proxy API requests
app.get('/api/*', async (req, res) => {
  try {
    const apiPath = req.path.replace('/api', '');
    const response = await axios.get(`${API_URL}${apiPath}`);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'API request failed' });
  }
});

app.listen(PORT, () => {
  console.log(`Frontend server running on port ${PORT}`);
});
