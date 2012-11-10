AJAX Crawler
=======================

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


