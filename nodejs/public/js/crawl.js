var socket;
function init() {
  socket = io.connect("/ui");
  $('form').submit(function(e) {
    e.preventDefault();
    e.stopPropagation();
    var url = $('#url').val();
    socket.emit("crawl", url);
    return false;
  });

  //TODO
  socket.on("image", function(url) {
    console.log('URL: ' + url);
    $('<br/>').prependTo($('#images'));
    $('<a>').attr({
            'href': url,
            'target': '_blank'
        }).html(url).prependTo($('#images'));
    if ($('img').size() > 10) {
      $('img:last-child').remove();
    }
  });
 
  //new URL is found during the crawl
  socket.on("foundURL", function(url) {
    //TODO
    console.log('URL: ' + url);
    $('<br/>').prependTo($('#images'));
    var link = $('<a>');
    link.attr({
      'href': url,
      'target': '_blank'
     }).html(url);
     link.prependTo($('#images'));
    });

  socket.on("jobs", function(count) {
    var jobsCount = $('#jobsCount');
    jobsCount.html(count);
  });

}

$(init);

