const cron = require('node-cron');
const _ = require('lodash');
const moment = require('moment');
const axios = require('axios');

console.log('Worker service starting...');

// Simulate background job every 30 seconds
cron.schedule('*/30 * * * * *', async () => {
  const timestamp = moment().format();
  const randomData = _.random(1, 100);
  
  console.log(`[${timestamp}] Processing job with data: ${randomData}`);
  
  // Simulate some work
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  console.log(`[${timestamp}] Job completed`);
});

console.log('Worker service started. Jobs scheduled.');

// Keep the process running
process.on('SIGTERM', () => {
  console.log('Worker service shutting down...');
  process.exit(0);
});
