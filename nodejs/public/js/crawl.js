var socket;
function init() {
    socket = io.connect("/ui");

    var stopButton = $('#stopButton');
    var startButton = $('#startButton');

    stopButton.click(function () {
        socket.emit("kill");

        stopButton.hide();
        startButton.css('display', 'block');

    });

    $('form').submit(function (e) {
        e.preventDefault();
        e.stopPropagation();
        var url = $('#url').val();
        var s3bucket = $('#s3bucket').val();
        var s3id = $('#s3id').val();
        var s3passwd = $('#s3passwd').val();
        var s3path = $('#path').val();
        socket.emit("crawl", {
            url:url,
            bucket:s3bucket,
            path:s3path,
            id:s3id,
            passwd:s3passwd
        });

        startButton.hide();
        stopButton.css('display', 'block');

        return false;
    });


    //TODO
    socket.on("image", function (url) {
        console.log('URL: ' + url);
        $('<br/>').prependTo($('#images'));
        $('<a>').attr({
            'href':url,
            'target':'_blank'
        }).html(url).prependTo($('#images'));
        if ($('img').size() > 10) {
            $('img:last-child').remove();
        }
    });

    //new URL is found during the crawl
    socket.on("foundURL", function (url) {
        //TODO
        console.log('URL: ' + url);
        $('<br/>').prependTo($('#images'));
        var link = $('<a>');
        link.attr({
            'href':url,
            'target':'_blank'
        }).html(url);
        link.prependTo($('#images'));
    });

    socket.on("jobs", function (count) {
        var jobsCount = $('#jobsCount');
        jobsCount.html(count);
    });

}

$(init);

