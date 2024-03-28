/**
 * Created by Anykey on 18.04.2017.
 *
 *   GCM Push Notifications
 *
 *   Migrate to FCM 02.08.2022 by Yusk
 */

importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");
importScripts("./firebase-config.js");

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage(async (payload) => {
  try {
    await self.registration.showNotification(payload.data.title, {
      body: payload.data.body,
    });
  } catch (e) {
    console.log(e);
  }
});
