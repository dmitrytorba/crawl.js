## What is Crawl.js

A solution for making an AJAX application crawlable. 
CrawlJS is a PhantomJS site crawler that takes HTML
snapshots and stores them to S3.

## Running Locally
1. Install NodeJS, PhantomJS and Heroku Toolbelt

2. Run everything via foreman

        foreman start

3. Navigate browser to http://localhost:5000/ to control the crawler

## Running on Heroku 


        $ heroku create
        $ heroku create --stack cedar --buildpack https://github.com/ddollar/heroku-buildpack-multi.git
        $ heroku apps:rename crawljs
        $ heroku config:add PHANTOMJS_URL=http://crawljs.herokuapp.com/phantom.html
        $ heroku config:add PATH="/usr/local/bin:/usr/bin:/bin:/app/vendor/phantomjs/bin"
        $ heroku config:add LD_LIBRARY_PATH="/usr/local/lib:/usr/lib:/lib:/app/vendor/phantomjs/lib"
        $ git push heroku master
        $ heroku ps:scale web=1
        $ heroku ps:scale renderer=1


## Running Tests

        cd nodejs
        mocha


## How it works

- node runs an express server
- express server hosts index.html (this is the UI for JSCrawl)
- index.html uses socket.io to control app.coffee (/ui socket) 
- express server hosts phantom.html (this is the API for PhantomJS)
- phantom workers load phatom.html when they start up
- phantom workers trigger JS on phatom.html
- phantom.html uses socket.io to talk to app.coffee (/phantom socket) 


## IntelliJ

- File > New Project ... 
- Create Project From Scratch
- Next
- Project Name: crawl.js
- Project File Location: [crawl.js root path]
- Make sure "Create Module" is checked and select "Web Module"
- Content root: [crawl.js root path]
- Module File Location: [crawl.js root path]



