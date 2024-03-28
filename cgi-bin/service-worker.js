'use strict';

// Used to persist messages_url
self.importScripts('/styles/default_adm/js/localforage.min.js');

self.addEventListener('push', function (event) {
  console.log('Received a push message', event);
  
  
  event.waitUntil(localforage.getItem('messages_url').then(function (url) {
        
        if (typeof url === 'undefined') {
          console.log('Empty messages URL');
          return;
        }
        
        
        fetch(url, {credentials: 'include'}).then(function (response) {
          
          var showNotification = function (data) {
            
            if (data.error) {
              return;
            }
            
            var title   = data.title || '';
            var message = data.message || '';
            var icon    = data.icon;
            var tag     = data.tag || '';
            
            return self.registration.showNotification(title, {
              body: message,
              icon: icon,
              tag : tag,
              data : {
                url : data.url || ''
              }
            })
          };
          
          response.text().then(function (raw_text) {
            console.log(raw_text);
            
            var messages = JSON.parse(raw_text);
            for (var i = 0; i < messages.length; i++){
              if (i === messages.length - 1) return showNotification(messages[i]);
              showNotification(messages[i]);
            }
            
          });
          
        })
        
      }).catch(function (err) {
        console.log("Can't retrieve message url : ", err);
      })
  );
});

self.addEventListener('notificationclick', function (event) {
  console.log('On notification click: ', event.notification);
  
  // Android doesn't close the notification when you click on it
  // See: http://crbug.com/463146
  event.notification.close();
  
  // This looks to see if the current is already open and
  // focuses if it is
  event.waitUntil(clients.matchAll({
    type: 'window'
  }).then(function (clientList) {
    for (var i = 0; i < clientList.length; i++) {
      var client = clientList[i];
      if (client.url === '/' && 'focus' in client) {
        return client.focus();
      }
    }
    if (clients.openWindow) {
      return clients.openWindow('/');
    }
  }));
});

self.addEventListener('message', function (event) {
  
  var message = null;
  try {
    message = JSON.parse(event.data);
  }
  catch (Error) {
    console.log(Error);
  }
  
  if (message.type === 'messages_fetch') {
    // construct and save url for getting messages
    
    var url = message.url
        + '?qindex=' + message.qindex
        + '&contact_id=' + message.contact_id;
    
    if (typeof message.sid !== 'undefined') {
      url += '&sid=' + message.sid;
    }
    
    localforage.setItem('messages_url', url, function (err, value) {
      console.log(value);
    });
    
  }
  
});