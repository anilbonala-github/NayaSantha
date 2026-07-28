// Firebase Cloud Messaging service worker (web background push).
// Must live at the web root so the browser can register it at /firebase-messaging-sw.js.
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDhL-S6zHiSGSTGErJaH-kIJQ3WsnX0zOo',
  appId: '1:518912994769:web:b03d6ed86a2cae9540c4f0',
  messagingSenderId: '518912994769',
  projectId: 'nayasantha-c4c90',
  authDomain: 'nayasantha-c4c90.firebaseapp.com',
  storageBucket: 'nayasantha-c4c90.firebasestorage.app',
  measurementId: 'G-RMDPDRG5RZ',
});

const messaging = firebase.messaging();

// Show background notifications (data-only or when the page isn't focused).
messaging.onBackgroundMessage((payload) => {
  const n = payload.notification || {};
  self.registration.showNotification(n.title || 'NayaSantha', {
    body: n.body || '',
    icon: '/icons/Icon-192.png',
  });
});
