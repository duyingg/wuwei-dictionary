{{flutter_js}}
{{flutter_build_config}}

// Local preview intentionally avoids PWA caching so every rebuild is visible.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then((registrations) => {
    for (const registration of registrations) {
      registration.unregister();
    }
  });
}
if ('caches' in window) {
  caches.keys().then((keys) => Promise.all(keys.map((key) => caches.delete(key))));
}

_flutter.loader.load();
