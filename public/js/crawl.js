var socket;

var initStorageForm = function() {
    var storagePanel = $('.storagePanel');
    var addStorageForm = $('#storageForm');
    var cancelButton = $('button.cancel', addStorageForm);

    cancelButton.on('click', function() {
        cleanStorageCombo();
        addStorageForm[0].reset();
        storagePanel.slideUp();
    });

    addStorageForm.submit(function (e) {
        e.preventDefault();
        e.stopPropagation();

        var storageName = $('#storageName').val();
        var s3bucket = $('#s3bucket').val();
        var s3id = $('#s3id').val();
        var s3passwd = $('#s3passwd').val();

        var s3path = $('#path').val();
        var fileFormat = $('#fileFormat').val();

        socket.emit("addStorage", {
            name: storageName,
            bucket:s3bucket,
            path:s3path,
            id:s3id,
            passwd:s3passwd,
            fileNameFormat: fileFormat
        });

        cleanStorageCombo();
        addStorageForm[0].reset();
        storagePanel.slideUp();

        return false;
    });
};

var showAddStorage = function() {
    var storagePanel = $('.storagePanel');
    storagePanel.slideDown();
}

var cleanStorageCombo = function () {
    var storageCombo = $('#storage');
    if(storageCombo.val() === 'ADD') {
        storageCombo.prop('selectedIndex', -1);
    }
};

var initFeedback = function() {
    var addWorker = $('#addWorker');
    var removeWorker = $('#removeWorker');

    addWorker.click(function () {
        socket.emit("addWorker");
    });
    removeWorker.click(function () {
        socket.emit("removeWorker");
    });

    socket.on('connect', function() {
        var status = $('#status');
        status.html('Connected');
    });

    socket.on('disconnect', function() {
        var status = $('#status');
        status.html('Disconnected');
    });

    socket.on("jobs", function (count) {
        var jobsCount = $('#jobsCount');
        jobsCount.html(count);
    });

    socket.on('phantomCount', function (count) {
        var phantomCount = $('#phantomCount');
        phantomCount.html(count);
    });

    socket.on('jobsCompleted', function (count) {
        var jobsCompleted = $('#jobsCompleted');
        jobsCompleted.html(count);
    });

};

var initView = function() {
    var stopButton = $('#stopButton');
    var startButton = $('#startButton');

    stopButton.click(function () {
        socket.emit("kill");
        stopButton.hide();
        startButton.css('display', 'block');
    });

    var storageCombo = $('#storage');

    cleanStorageCombo();

    storageCombo.on('change', function() {
        var selectedVal = storageCombo.val();
        if(selectedVal === 'ADD') {
            showAddStorage();
        }
    });

    var currentStorages = [];
    socket.on('storages', function (storages) {
        for(var i=0; i < storages.length; i++) {
            var storage = storages[i];
            if(currentStorages.indexOf(storage.name) < 0) {
                currentStorages.push(storage.name);
                var option = $('<option></option>');
                option.attr('value', storage.name)
                option.text(storage.name);
                storageCombo.prepend(option);
            }
        }
    });

    $('form#mainForm').submit(function (e) {
        e.preventDefault();
        e.stopPropagation();
        var url = $('#url').val();

        var bucketStrategy = $('#bucketStrategy').val();
        socket.emit("crawl", {
            url:url,
            storage: storageCombo.val(),
            bucketStrategy: bucketStrategy
        });

        startButton.hide();
        stopButton.css('display', 'block');

        return false;
    });

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


};

var init = function() {
    socket = io.connect("/ui");

    initStorageForm();
    initFeedback();
    initView();
}

$(init);

