const express = require('express');
const cors = require('cors');
const _ = require('lodash');
const moment = require('moment');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: moment().format(),
    service: 'api'
  });
});

app.get('/data', (req, res) => {
  const data = _.range(1, 11).map(i => ({
    id: i,
    name: `Item ${i}`,
    created: moment().subtract(i, 'days').format()
  }));
  
  res.json(data);
});

app.listen(PORT, () => {
  console.log(`API Server running on port ${PORT}`);
});
