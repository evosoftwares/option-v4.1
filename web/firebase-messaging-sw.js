// Firebase Cloud Messaging Service Worker
// Este arquivo deve estar na raiz do diretório web para funcionar corretamente

importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Configuração do Firebase (substitua pelos seus valores)
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "your-sender-id",
  appId: "your-app-id"
};

// Inicializar Firebase
firebase.initializeApp(firebaseConfig);

// Obter instância do messaging
const messaging = firebase.messaging();

// Manipular mensagens em background
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // Personalizar a notificação
  const notificationTitle = payload.notification?.title || 'Nova Notificação';
  const notificationOptions = {
    body: payload.notification?.body || 'Você tem uma nova mensagem',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    tag: payload.data?.tag || 'default',
    data: payload.data,
    actions: getNotificationActions(payload.data?.type),
    requireInteraction: payload.data?.requireInteraction === 'true',
    silent: payload.data?.silent === 'true',
    vibrate: payload.data?.vibrate ? JSON.parse(payload.data.vibrate) : [200, 100, 200]
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Definir ações baseadas no tipo de notificação
function getNotificationActions(type) {
  switch (type) {
    case 'ride_request':
      return [
        {
          action: 'accept',
          title: 'Aceitar',
          icon: '/icons/accept.png'
        },
        {
          action: 'decline',
          title: 'Recusar',
          icon: '/icons/decline.png'
        }
      ];
    case 'chat_message':
      return [
        {
          action: 'reply',
          title: 'Responder',
          icon: '/icons/reply.png'
        },
        {
          action: 'view',
          title: 'Ver Conversa',
          icon: '/icons/view.png'
        }
      ];
    case 'ride_update':
      return [
        {
          action: 'view',
          title: 'Ver Detalhes',
          icon: '/icons/view.png'
        }
      ];
    default:
      return [];
  }
}

// Manipular cliques nas notificações
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();
  
  const action = event.action;
  const data = event.notification.data;
  
  // Determinar URL baseada na ação e dados
  let url = '/';
  
  if (action === 'accept' && data?.rideId) {
    url = `/ride/${data.rideId}/accept`;
  } else if (action === 'decline' && data?.rideId) {
    url = `/ride/${data.rideId}/decline`;
  } else if (action === 'reply' && data?.chatId) {
    url = `/chat/${data.chatId}`;
  } else if (action === 'view') {
    if (data?.rideId) {
      url = `/ride/${data.rideId}`;
    } else if (data?.chatId) {
      url = `/chat/${data.chatId}`;
    }
  } else if (data?.deepLink) {
    url = data.deepLink;
  }
  
  // Abrir ou focar na janela
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Verificar se já existe uma janela aberta
        for (const client of clientList) {
          if (client.url.includes(url) && 'focus' in client) {
            return client.focus();
          }
        }
        
        // Abrir nova janela se não encontrar uma existente
        if (clients.openWindow) {
          return clients.openWindow(url);
        }
      })
  );
});

// Manipular fechamento de notificações
self.addEventListener('notificationclose', (event) => {
  console.log('[firebase-messaging-sw.js] Notification closed.');
  
  // Opcional: registrar analytics de notificação fechada
  const data = event.notification.data;
  if (data?.notificationId) {
    // Enviar evento de fechamento para analytics
    fetch('/api/notifications/analytics', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        notificationId: data.notificationId,
        action: 'closed',
        timestamp: new Date().toISOString()
      })
    }).catch(console.error);
  }
});

// Manipular instalação do service worker
// Firebase Messaging Service Worker DESATIVADO
// Este arquivo foi mantido apenas como placeholder para evitar 404.
// As notificações Web são gerenciadas pelo OneSignal (OneSignalSDKWorker.js).

self.addEventListener('install', (event) => {
  console.log('[firebase-messaging-sw.js] desativado: usando OneSignal para Web Push');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log('[firebase-messaging-sw.js] ativado (placeholder).');
  // Opcional: remover caches antigos criados por FCM
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys
      .filter((key) => key.startsWith('firebase-messaging'))
      .map((key) => caches.delete(key))
    );
  })());
});

// Não registrar listeners de push/click para evitar duplicidade