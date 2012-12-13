## What is Crawl.js

A solution for making an AJAX application crawlable. 
CrawlJS is a PhantomJS site crawler that takes HTML
snapshots and stores them to S3.

## Running Locally
1. Start node 

        cd nodejs
        node app.js

Mare sure you see "Express server listening on port 3000 in development mode"

2. Start phantomjs, pointing it to node server

        cd phantomjs
        phantomjs --cookies-file=/dev/null phantomWorker.coffee http://localhost:3000/phantom.html

## Running on Heroku 

1. NodeJS


        $ heroku create --stack cedar
        $ heroku config:add AWS_ACCESS_KEY_ID=<your aws access key id>
        $ heroku config:add AWS_SECRET_ACCESS_KEY=<your aws secret access key>
        $ heroku config:add UPLOAD_BUCKET_NAME=<aws s3 bucket name to store screenshots>
        $ git push heroku master

2. PhantomJS


        $ heroku create --stack cedar --buildpack http://github.com/stomita/heroku-buildpack-phantomjs.git
        $ heroku config:add PUSH_SERVER_URL=http://<app name of nodejs screenshot server>.herokuapp.com/phantom.html
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




