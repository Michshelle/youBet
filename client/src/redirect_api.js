//
//const express = require('express');
//const request = require('request');
//
//const app = express();
//
//app.use((req, res, next) => {
//  res.header('Access-Control-Allow-Origin', '*');
//  next();
//});
//
//app.get('/v2', (req, res) => {
//  request(
//    { url: 'https://api-pub.bitfinex.com' },
//    (error, response, body) => {
//      if (error || response.statusCode !== 200) {
//        return res.status(500).json({ type: 'error', message: err.message });
//      }
//
//      res.json(JSON.parse(body));
//    }
//  )
//});
//
//const PORT = process.env.PORT || 3001;
//app.listen(PORT, () => console.log(`listening on ${PORT}`));



const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

app.use('/v2', createProxyMiddleware({ target: 'https://api-pub.bitfinex.com', changeOrigin: true }));
app.listen(3001);