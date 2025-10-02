importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyB9nik0iTDHuxpAPfiVqmm4hMqbtzqWGLc",
  authDomain: "pregmonitor.firebaseapp.com",
  projectId: "pregmonitor",
  storageBucket: "pregmonitor.firebasestorage.app",
  messagingSenderId: "962894089311",
  appId: "1:962894089311:web:01cce8039c9629dc85dfea",
  measurementId: "G-5NBVYPFCKR"
});

const messaging = firebase.messaging();

// Optional background message handler
messaging.onBackgroundMessage((payload) => {
  console.log('Background message received:', payload);
  
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/icon-192x192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});