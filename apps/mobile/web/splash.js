// File terpisah karena CSP release melarang inline script.
window.addEventListener('flutter-first-frame', function () {
  var loading = document.getElementById('loading');
  if (loading) loading.remove();
});
