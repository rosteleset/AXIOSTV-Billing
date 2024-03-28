'use strict';

var SOCKET_STATE = {
  CONNECTING: 0,
  OPEN      : 1,
  CLOSING   : 2,
  CLOSED    : 3
};

var ws = null;
$(function () {
  ws = new WSClient(document['WEBSOCKET_URL']);
});

var WSClient = function (socket_link) {
  this.link = socket_link;
  
  this.is_in_connection_retrieval    = true;
  this.unsuccessful_connection_tries = 0;
  
  if (socket_link !== '') {
    this.link                 = 'wss://' + socket_link;
    document['WEBSOCKET_URL'] = this.link;
    this.ws                   = this.try_to_connect_again_in_(0);
  }
  else {
    console.log('[ WebSocket ] Will not connect to socket without $conf{WEBSOCKET_URL}. It\'s normal if you haven\'t configured WebSockets');
  }
};

WSClient.prototype = {
  on_message              : function (event) {
    var message = null;
    try {
      message = JSON.parse(event.data);
    }
    catch (Error) {
      console.log("[ WebSocket ] Fail to parse JSON: " + event.data);
      return;
    }
    
    var self = this;
    switch (message.TYPE) {
      case 'close':
        self.ws.close(1000); // Normal
        if (message.REASON) {
          console.log("[ WebSocket ] Connection closed by server : " + message.REASON);
        }
        break;
      case 'PING':
        self.ws.send('{"TYPE":"PONG"}');
        break;
      case 'PONG':
        Events.emit("WebSocket.ping_success");
        break;
      default:
        AMessageChecker.processData(message);
        self.ws.send('{"TYPE":"RESPONCE","RESPONCE":"RECEIVED"}');
        break;
    }
    
  },
  established             : function () {
    this.is_in_connection_retrieval    = false;
    this.unsuccessful_connection_tries = 0;
    Events.emit('WebSocket.connected');
  },
  ping                    : function () {
    this.ws.send('{"TYPE":"PING"}');
  },
  request_close_socket    : function () {
    this.ws.send('{"TYPE":"CLOSE_REQUEST"}');
    this.try_to_connect_again = false;
  },
  try_to_connect_again_in_: function (seconds) {
    seconds = Math.min(seconds, 10);
    
    var self = this;
    this.ws  = null;
    
    self.unsuccessful_connection_tries++;
    if (self.unsuccessful_connection_tries >= 10) {
      console.log('[ WebSocket ] Giving up after %i tries', self.unsuccessful_connection_tries);
      return;
    }
    
    this.ws = new WebSocket(this.link);

    //console.log("[ WebSocket ] try connecte: " + this.link);

    this.ws.onopen = function () {
      Events.emit('WebSocket.opened');
      console.log("[ WebSocket ] connected ");
      self.setup_socket();
    };
    
    this.ws.onclose = function (code, reason, was_clean) {
      console.log('[ WebSocket ] Close : %s %s %s', code, reason, was_clean)
    };
    
    this.ws.onerror = function () {
      Events.emit('WebSocket.error');
      console.log('Will try again in %.2f seconds', seconds);
      seconds = parseInt(seconds || 1);
      setTimeout(function () {
        self.try_to_connect_again_in_(seconds * 2)
      }, seconds * 1000);
    };
    
    return this.ws;
    
  },
  setup_socket            : function () {
    var self = this;
    
    this.ws.onclose = function () {
      if (!self.is_in_connection_retrieval) {
        self.is_in_connection_retrieval = true;
        self.try_to_connect_again_in_(2 + Math.random());
      }
    };
    
    this.ws.onerror = function () {
      Events.emit('WebSocket.error');
      if (!self.is_in_connection_retrieval) {
        self.is_in_connection_retrieval = true;
        self.try_to_connect_again_in_(2 + Math.random());
      }
    };
    
    this.ws.onmessage = self.on_message.bind(self);
    
    Events.once("WebSocket.ping_success", function () {
      self.established();
    });
    
    this.ping();
  },
};


document.onunload = function () {
  ws.unsuccessful_connection_tries = 1000;
};