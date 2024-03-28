/**
 * Created by Anykey on 18.04.2017.
 *
 *   Push Notifications
 *
 *   Migrate from GCM to FCM 02.08.2022 by Yusk
 */

'use strict';

var ENABLE_PUSH = window['ENABLE_PUSH'];
var DISABLE_PUSH = window['DISABLE_PUSH'];
var PUSH_IS_NOT_SUPPORTED = window['PUSH_IS_NOT_SUPPORTED'];
var PUSH_IS_DISABLED = window['PUSH_IS_DISABLED'];

let pushEnabled = false;

$(async function () {
  await checkToken();

  if (!('serviceWorker' in navigator)) {
    updateButton(false, PUSH_IS_NOT_SUPPORTED);
  } else if (Notification.permission === 'denied') {
    updateButton(false, PUSH_IS_DISABLED);
  } else if (pushEnabled) {
    updateButton(true, DISABLE_PUSH);
  }

  firebase.initializeApp(JSON.parse(window['FIREBASE_CONFIG']));
  const messaging = firebase.messaging();

  messaging.onMessage(async (payload) => {
    await showNotification(payload);
  });


  $('button.js-push-button').on('click', function () {
    if (pushEnabled) {
      unsubscribe();
    } else {
      subscribe(messaging);
    }
  });
});

const subscribe = (messaging) => {
  updateButton(false);

  messaging.getToken({vapidKey: window['FIREBASE_VAPID_KEY']}).then((currentToken) => {
    if (currentToken) {
      if (window['IS_ADMIN_INTERFACE'] && !window['IS_PUSH_ENABLED']) {
        fetch(`?index=9&AWEB_OPTIONS=1&QUICK=1&PUSH_ENABLED=1&header=2&TOKEN=${currentToken}`, {method: 'GET'}).then().catch();
        pushEnabled = true;
        window['IS_PUSH_ENABLED'] = pushEnabled;
        updateButton(true, DISABLE_PUSH);
      } else {
        fetch(`${window['BASE_URL']}/api.cgi/user/${window['UID']}/contacts/push/subscribe/1/`, {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'USERSID': window['SID'],
          },
          body: JSON.stringify({token: currentToken})
        }).then(res => {
          pushEnabled = true;
          updateButton(true, DISABLE_PUSH);
        }).catch(e => console.log(e));
      }
    }
  }).catch(() => {
    updateButton(false, PUSH_IS_NOT_SUPPORTED);
  });

  if (Notification.permission === 'denied') {
    updateButton(false, PUSH_IS_DISABLED);
  }
}

const unsubscribe = () => {
  updateButton(false);

  if (window['IS_ADMIN_INTERFACE'] && window['IS_PUSH_ENABLED']) {
    fetch('?index=9&AWEB_OPTIONS=1&QUICK=1&PUSH_ENABLED=0', {method: 'GET'}).then().catch();
    pushEnabled = false;
    window['IS_PUSH_ENABLED'] = pushEnabled;
    updateButton(true, ENABLE_PUSH);
  } else {
    fetch(`${window['BASE_URL']}/api.cgi/user/${window['UID']}/contacts/push/subscribe/1/`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'USERSID': window['SID'],
      },
    }).then(res => {
      pushEnabled = false;
      updateButton(true, ENABLE_PUSH);
    }).catch(e => console.log(e));
  }
}

const showNotification = async (payload) => {
  try {
    await Notification.requestPermission(result => {
      if (result === 'granted' && 'serviceWorker' in navigator) {
        navigator.serviceWorker
          .register(`${window['BASE_URL']}/firebase-messaging-sw.js`)
          .then(function (registration) {
            registration.showNotification(payload.data.title, {
              body: payload.data.body,
              icon: payload.data.icon,
              data: { url: payload.data.url },
              tag: Date.now()
            });
            registration.update();
          }).catch(e => {
          console.log(e);
        });
      }
    });
  } catch (e) {
    console.log(e);
  }
}

const checkToken = async () => {
  try {
    if (window['IS_ADMIN_INTERFACE']) {
      pushEnabled = window['IS_PUSH_ENABLED'];
    } else {
      const res = await (await fetch(`${window['BASE_URL']}/api.cgi/user/${window['UID']}/contacts/push/subscribe/1/`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'USERSID': window['SID'],
        },
      })).json();

      pushEnabled = !!res?.value;
    }
  } catch (e) {
    updateButton(false, PUSH_IS_NOT_SUPPORTED);
    console.log(e);
  }
}

const updateButton = (state, newMessage) => {
  let pushButton = $('button.js-push-button');
  let pushBtnText = pushButton.find('strong.js-push-text');
  let pushBtnIcon = pushButton.find('span.js-push-icon');

  let disabled = !state;
  pushButton.prop('disabled', disabled);

  if (newMessage) {
    pushBtnText.text(newMessage)
  }

  if (pushEnabled && !pushBtnIcon.hasClass('fa-bell-slash')) {
    pushBtnIcon.addClass('fa-bell-slash');
    pushBtnIcon.removeClass('fa-bell');

    pushButton.removeClass('btn-info');
    pushButton.addClass('btn-success');
  } else if (!pushEnabled && !pushBtnIcon.hasClass('fa-bell')) {
    pushBtnIcon.removeClass('fa-bell-slash');
    pushBtnIcon.addClass('fa-bell');

    pushButton.removeClass('btn-success');
    pushButton.addClass('btn-info');
  }
}
