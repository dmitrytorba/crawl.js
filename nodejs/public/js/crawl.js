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
        var fileFormat = $('#fileFormat').val();
        var bucketStrategy = $('#bucketStrategy').val();
        socket.emit("crawl", {
            url:url,
            bucket:s3bucket,
            path:s3path,
            id:s3id,
            passwd:s3passwd,
            fileNameFormat: fileFormat,
            bucketStrategy: bucketStrategy
        });

        startButton.hide();
        stopButton.css('display', 'block');

        return false;
    });

    socket.on('connect', function() {
        var status = $('#status');
        status.html('Connected');
    });

    socket.on('disconnect', function() {
        var status = $('#status');
        status.html('Disconnected');
    });

    //TODO
    socket.on("snapshot", function (config) {
        var url = config.snapshotUrl;
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

    socket.on('phantomCount', function (count) {
        var phantomCount = $('#phantomCount');
        phantomCount.html(count);
    })

    socket.on('jobsCompleted', function (count) {
        var jobsCompleted = $('#jobsCompleted');
        jobsCompleted.html(count);
    })

}

$(init);

