1. Start node 

  cd nodejs
  node app.js

Mare sure you see "Express server listening on port 3000 in development mode"

2. Start phantomjs, pointing it to node server

  cd phantomjs
  phantomjs --cookies-file=/dev/null screenshot.coffee http://localhost:3000/render.html


