var socket;
function init() {
    socket = io.connect("/ui");

    var stopButton = $('#stopButton');
    var startButton = $('#startButton');

    var addWorker = $('#addWorker');
    var removeWorker = $('#removeWorker');

    addWorker.click(function () {
        socket.emit("addWorker");
    });
    removeWorker.click(function () {
        socket.emit("removeWorker");
    });

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
        $('<br/>').prependTo($('#output'));
        $('<span class="orig-url">' + config.originalUrl + '</span> ').prependTo($('#output'));
        $('<a>').attr({
            'href':url,
            'target':'_blank'
        }).html(url).prependTo($('#output'));
        if ($('img').size() > 10) {
            $('img:last-child').remove();
        }
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

