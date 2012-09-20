var socket;
function init() {
  socket = io.connect("/render");
  socket.on("render", function(params) {
    console.log("render:"+JSON.stringify(params));
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
