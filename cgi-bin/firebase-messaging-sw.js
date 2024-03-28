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

self.addEventListener("notificationclick", (event) => {
  event.waitUntil(async function () {
    const allClients = await clients.matchAll({ includeUncontrolled: true });
    let chatClient;
    let url = event.notification.data ? event.notification.data.url : undefined;
    for (const client of allClients) {
      if (client['url'].indexOf(url) >= 0) {
        client.focus();
        chatClient = client;

        client.navigate(url);
        break;
      }
    }
    if (!chatClient && url) chatClient = await clients.openWindow(url);
  }());
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(async (payload) => {
  try {
    await self.registration.showNotification(payload.data.title, {
      body: payload.data.body,
      icon: payload.data.icon,
      data: { url: payload.data.url },
      tag: Date.now()
    });
  } catch (e) {
    console.log(e);
  }
});
