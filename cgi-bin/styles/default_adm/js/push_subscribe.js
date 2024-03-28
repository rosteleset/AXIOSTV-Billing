var API_KEY = window['GOOGLE_API_KEY'];

var ENABLE_PUSH  = window['ENABLE_PUSH'];
var DISABLE_PUSH = window['DISABLE_PUSH'];

var PUSH_IS_NOT_SUPPORTED = window['PUSH_IS_NOT_SUPPORTED'];
var PUSH_IS_DISABLED      = window['PUSH_IS_DISABLED'];

window['isPushEnabled']    = false;
window['adminPushEnabled'] = false;

$(function () {
  
  $('button.js-push-button').on('click', function () {
    
    if (!window['isPushEnabled']) {
      subscribe();
    }
    else {
      unsubscribe();
    }
  });
  
  // Check that service workers are supported, if so, progressively
  // enhance and add push messaging support, otherwise continue without it.
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/service-worker.js')
        .then(function () {
          initialiseState();
        });
  } else {
    console.log('Service workers aren\'t supported in this browser.');
    updateButton(false, PUSH_IS_NOT_SUPPORTED, false)
  }
  
});

function updateButton(state, newMessage, pushEnabled) {
  var pushButton  = $('button.js-push-button');
  var pushBtnText = pushButton.find('strong.js-push-text');
  var pushBtnIcon = pushButton.find('span.js-push-icon');
  
  var disabled = !state;
  pushButton.prop('disabled', disabled);
  
  if (newMessage) {
    pushBtnText.text(newMessage)
  }
  
  if (typeof pushEnabled !== 'undefined') {
    window['isPushEnabled'] = pushEnabled;
    if (window['IS_ADMIN_INTERFACE'] && (window['IS_PUSH_ENABLED'] !== window['isPushEnabled'])) {
    
    }
  }
  
  if (window['isPushEnabled'] && !pushBtnIcon.hasClass('fa-bell-slash')) {
    pushBtnIcon.addClass('fa-bell-slash');
    pushBtnIcon.removeClass('fa-bell');
    
    pushButton.removeClass('btn-info');
    pushButton.addClass('btn-secondary');
  }
  else if (!window['isPushEnabled'] && !pushBtnIcon.hasClass('fa-bell')) {
    pushBtnIcon.removeClass('fa-bell-slash');
    pushBtnIcon.addClass('fa-bell');
    
    pushButton.removeClass('btn-secondary');
    pushButton.addClass('btn-info');
  }
}

// This method handles the removal of subscriptionId
// in Chrome 44 by concatenating the subscription Id
// to the subscription endpoint
function endpointWorkaround(pushSubscription) {
  
  // Make sure we only mess with GCM
  if (pushSubscription.endpoint.indexOf('https://android.googleapis.com/gcm/send') !== 0) {
    return pushSubscription.endpoint;
  }
  
  var mergedEndpoint = pushSubscription.endpoint;
  // Chrome 42 + 43 will not have the subscriptionId attached
  // to the endpoint.
  if (pushSubscription.subscriptionId &&
      pushSubscription.endpoint.indexOf(pushSubscription.subscriptionId) === -1) {
    // Handle version 42 where you have separate subId and Endpoint
    mergedEndpoint = pushSubscription.endpoint + '/' +
        pushSubscription.subscriptionId;
  }
  return mergedEndpoint;
}

function sendSubscriptionToServer(subscription) {
  
  // For compatibly of Chrome 43, get the endpoint via
  // endpointWorkaround(subscription)
  var mergedEndpoint = endpointWorkaround(subscription);
  
  var params = {
    qindex  : '100001',
    ENDPOINT: mergedEndpoint
    //KEY     : btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey('p256dh')))),
    //AUTH    : btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey('auth'))))
  };
  if (isDefined(window['SID'])) params['sid'] = window['SID'];
  
  $.post('index.cgi', params)
      .done(function (subscribe_responce) {
        
        // Tell service worker where to fetch the data
        var serviceWorkerParams = {
          type  : 'messages_fetch',
          url   : window['SELF_URL'],
          qindex: 100003
        };
        if (isDefined(window['SID']))
          serviceWorkerParams['sid'] = window['SID'];
        
        if (isDefined(subscribe_responce.contact_id)) {
          serviceWorkerParams.contact_id = subscribe_responce.contact_id;
        }
        
        navigator.serviceWorker.ready.then(function (serviceWorkerRegistration) {
          serviceWorkerRegistration.active.postMessage(JSON.stringify(serviceWorkerParams));
        });
        
        updateButton(true, DISABLE_PUSH, true);
        
        //Save admin settings
        if (window['IS_ADMIN_INTERFACE'] && ( !window['IS_PUSH_ENABLED'] )) {
          $.post('?index=9&AWEB_OPTIONS=1&QUICK=1&PUSH_ENABLED=1&header=2');
          window['IS_PUSH_ENABLED'] = window['isPushEnabled'];
        }
        
        
      })
      .fail(function (error) {
        console.log('failed to register ', error);
      });
  
}

function unsubscribe() {
  updateButton(false);
  
  navigator.serviceWorker.ready.then(function (serviceWorkerRegistration) {
    // To unsubscribe from push messaging, you need get the
    // subcription object, which you can call unsubscribe() on.
    serviceWorkerRegistration.pushManager.getSubscription().then(
        function (pushSubscription) {
          // Check we have a subscription to unsubscribe
          if (!pushSubscription) {
            // No subscription object, so set the state
            // to allow the user to subscribe to push
            updateButton(true, ENABLE_PUSH, false);
            return;
          }
          
          var params = {
            qindex     : 100001,
            unsubscribe: 1
          };
          if (isDefined(window['SID'])) params['sid'] = window['SID'];
          
          
          // We have a subscription, so call unsubscribe on it
          pushSubscription.unsubscribe().then(function () {
            $.post(SELF_URL, params, function () {
              updateButton(true, ENABLE_PUSH, false);
              
              if (window['IS_ADMIN_INTERFACE'] && window['IS_PUSH_ENABLED'] ) {
                $.post('?index=9&AWEB_OPTIONS=1&QUICK=1&PUSH_ENABLED=0');
                window['IS_PUSH_ENABLED'] = window['isPushEnabled'];
              }
            });
            
            
            //Save admin settings
            
          }).catch(function (e) {
            // We failed to unsubscribe, this can lead to
            // an unusual state, so may be best to remove
            // the subscription id from your data store and
            // inform the user that you disabled push
            
            console.log('Unsubscription error: ', e);
            updateButton(true, DISABLE_PUSH, true);
          });
        }).catch(function (e) {
      console.log('Error thrown while unsubscribing from ' +
          'push messaging.', e);
    });
  });
}

function subscribe() {
  // Disable the button so it can't be changed while
  // we process the permission request
  updateButton(false, false, false);
  
  navigator.serviceWorker.ready.then(function (serviceWorkerRegistration) {
    
    serviceWorkerRegistration.pushManager.subscribe({userVisibleOnly: true})
        .then(function (subscription) {
          // The subscription was successful
          updateButton(true, DISABLE_PUSH, true);
          return sendSubscriptionToServer(subscription, serviceWorkerRegistration);
        })
        .catch(function (e) {
          if (Notification.permission === 'denied') {
            updateButton(false, PUSH_IS_DISABLED, false);
            console.log('Permission for Notifications was denied');
          }
          else {
            console.log('Unable to subscribe to push.', e);
            updateButton(false, PUSH_IS_NOT_SUPPORTED, false);
          }
        });
  });
  
  
}

// Once the service worker is registered set the initial state
function initialiseState() {
  
  // Are Notifications supported in the service worker?
  if (!('showNotification' in ServiceWorkerRegistration.prototype)) {
    console.log('Notifications aren\'t supported.');
    updateButton(false, PUSH_IS_NOT_SUPPORTED, false);
    return;
  }
  
  // Check the current Notification permission.
  // If its denied, it's a permanent block until the
  // user changes the permission
  if (Notification.permission === 'denied') {
    console.log('The user has blocked notifications.');
    updateButton(false, PUSH_IS_DISABLED, false);
    return;
  }
  
  // Check if push messaging is supported
  if (!('PushManager' in window)) {
    console.log('Push messaging isn\'t supported.');
    updateButton(false, PUSH_IS_NOT_SUPPORTED, false);
    return;
  }
  
  // We need the service worker registration to check for a subscription
  navigator.serviceWorker.ready.then(function (serviceWorkerRegistration) {
    
    // Do we already have a push message subscription?
    serviceWorkerRegistration.pushManager.getSubscription()
        .then(function (subscription) {
          updateButton(false);
          
          if (!subscription) {
            // We aren’t subscribed to push, so set UI
            // to allow the user to enable push
            console.log('no subscription');
            
            // Force subscribe for client portal
            //if (typeof(EVENT_PARAMS) !== 'undefined' && EVENT_PARAMS.portal === 'client') {
            //  subscribe();
            //}
            updateButton(true, ENABLE_PUSH, false);
            return;
          }
          
          // Keep your server in sync with the latest subscription
          sendSubscriptionToServer(subscription);
          
          // Set your UI to show they have subscribed for
          // push messages
          window['isPushEnabled'] = true;
        })
        .catch(function (err) {
          console.log('Error during getSubscription()', err);
        });
  });
}