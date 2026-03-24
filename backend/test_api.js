const https = require('https');

https.get('https://booksafe-2.onrender.com/', (res) => {
  console.log('statusCode:', res.statusCode);
  console.log('headers:', res.headers);

  res.on('data', (d) => {
    process.stdout.write(d);
  });
}).on('error', (e) => {
  console.error('Error fetching API:', e);
});
