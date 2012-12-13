## Running Locally
1. Start node 

    cd nodejs
    node app.js

Mare sure you see "Express server listening on port 3000 in development mode"

2. Start phantomjs, pointing it to node server

    cd phantomjs
    phantomjs --cookies-file=/dev/null phantomWorker.coffee http://localhost:3000/phantom.html

## NodeJS Part

Overview
-----
- the crawler has two parts: 1) the controller module and 2) the PhantomJS module
- the PhantomJS module does two things:
    a. load a page for a URL, search for anchor links, throw 'found' event for each link

Running Locally
-----

    $ heroku create --stack cedar
    $ heroku config:add AWS_ACCESS_KEY_ID=<your aws access key id>
    $ heroku config:add AWS_SECRET_ACCESS_KEY=<your aws secret access key>
    $ heroku config:add UPLOAD_BUCKET_NAME=<aws s3 bucket name to store screenshots>
    $ git push heroku master

## PhantomJS Part


Deploying to Heroku
-----

    $ heroku create --stack cedar --buildpack http://github.com/stomita/heroku-buildpack-phantomjs.git
    $ heroku config:add PUSH_SERVER_URL=http://<app name of nodejs screenshot server>.herokuapp.com/render.html
    $ git push heroku master
    $ heroku ps:scale renderer=<num of phantomjs screenshot renderer>



## How it works

- node runs an express server
- express server hosts index.html (this is the UI for JSCrawl)
- index.html uses socket.io to control app.coffee (/ui socket) 
- express server hosts phantom.html (this is the API for PhantomJS)
- phantom workers load phatom.html when they start up
- phantom workers trigger JS on phatom.html
- phantom.html uses socket.io to talk to app.coffee (/phantom socket) 


