importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// ✅ Initialized with project-specific values from lib/firebase_options.dart
firebase.initializeApp({
  apiKey: "AIzaSyBZh78YSljhGD8nZqmpdEF_Xbt6B4uc9Aw",
  authDomain: "pizza-hub-vehari.firebaseapp.com",
  projectId: "pizza-hub-vehari",
  storageBucket: "pizza-hub-vehari.firebasestorage.app",
  messagingSenderId: "817904341442",
  appId: "1:817904341442:web:a7c3dcbec8eba5adee065b",
});

const messaging = firebase.messaging();

// Handle background push notifications
messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Background message received:', payload);
  const title = payload.notification?.title ?? 'New Notification';
  const body = payload.notification?.body ?? '';
  self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  });
});