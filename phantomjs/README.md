
Run from terminal
-----

    phantomjs --cookies-file=/dev/null htmlshot.coffee http://localhost:3000/render.html

Deploying to Heroku
-----

    $ heroku create --stack cedar --buildpack http://github.com/stomita/heroku-buildpack-phantomjs.git
    $ heroku config:add PUSH_SERVER_URL=http://<app name of nodejs screenshot server>.herokuapp.com/render.html
    $ git push heroku master
    $ heroku ps:scale renderer=<num of phantomjs screenshot renderer>


