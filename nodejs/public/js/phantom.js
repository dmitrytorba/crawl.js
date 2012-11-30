var socket;
function init() {
  socket = io.connect("/phantom");
  socket.on("dispatch", function(params) {
    console.log("dispatch:"+JSON.stringify(params));
  });
}

function notifyFound(url) {
  socket.emit("found", {
    url: url 
  });
}

function notifyComplete(pageUrl, snapshotUrl) {
  socket.emit("complete", {
    url: pageUrl,
    snapshotUrl: snapshotUrl
  });
}

function notifyFailure(pageUrl) {
  socket.emit("failure", {
    url: pageUrl
  });
}


$(init);
