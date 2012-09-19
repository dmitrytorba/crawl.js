var socket;
function init() {
  socket = io.connect("/request");
  $('form').submit(function(e) {
    e.preventDefault();
    e.stopPropagation();
    var url = $('#url').val();
    socket.emit("render", url);
    return false;
  });
  socket.on("image", function(url) {
    console.log('URL: ' + url);
    $('<a>').attr({
            'href': url,
            'target': '_blank'
        }).html(url).prependTo($('#images'));
    if ($('img').size() > 10) {
      $('img:last-child').remove();
    }
  });
}

$(init);

