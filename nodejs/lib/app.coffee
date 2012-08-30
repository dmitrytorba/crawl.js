
express = require('express');

app = express()

app.get('/', (request, response) -> 
  response.send('Hello World!')


port = process.env.PORT || 80
app.listen port,  -> 
  console.log("Listening on " + port)
