## What is Crawl.js

A solution for making an AJAX application crawlable. 
CrawlJS is a PhantomJS site crawler that takes HTML
snapshots and stores them to S3.

## Running Locally
1. Install NodeJS, PhantomJS, and MongoDB

2. Add a user

    node createUser.js username password

3. Run MongoDB

    sudo mongod

4. Run the app

    node app.js

5. Login at http://localhost:3000/ to control the crawler


## Running Tests

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



