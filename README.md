## Running Locally
1. Start node 

  cd nodejs
  node app.js

Mare sure you see "Express server listening on port 3000 in development mode"

2. Start phantomjs, pointing it to node server

  cd phantomjs
  phantomjs --cookies-file=/dev/null phantomWorker.coffee http://localhost:3000/phantom.html

## How it works

- node runs an express server
- express server hosts index.html (this is the UI for JSCrawl)
- index.html uses socket.io to control app.coffee (/ui socket) 
- express server hosts phantom.html (this is the API for PhantomJS)
- phantom workers load phatom.html when they start up
- phantom workers trigger JS on phatom.html
- phantom.html uses socket.io to talk to app.coffee (/phantom socket) 


