const express = require('express');
const { exec } = require('child_process');

const app = express();
const port = 3000;

app.get('/getAccessToken', (req, res) => {
  exec('node getAccessToken.js', (error, stdout, stderr) => {
    if (error) {
      console.error(`exec error: ${error}`);
      return res.status(500).send('Error fetching access token');
    }
    try {
      const tokenData = JSON.parse(stdout);
      res.json(tokenData);
    } catch (parseError) {
      console.error(`Parse error: ${parseError}`);
      res.status(500).send('Error parsing access token');
    }
  });
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});