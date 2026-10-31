// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// SG Mail installable comme une app (PWA).
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker", { scope: "/" }).catch(() => {})
}

// Chrome, Edge et Brave annoncent qu'on peut installer l'app : on garde l'invitation pour le bouton « Installer ».
window.addEventListener("beforeinstallprompt", (event) => {
  event.preventDefault()
  window.sgInstallPrompt = event
  window.dispatchEvent(new Event("sg:installable"))
})
window.addEventListener("appinstalled", () => {
  window.sgInstallPrompt = null
  window.sgInstalled = true
})

// La pastille de l'icône (app installée) suit les non-lus de la réception à chaque page.
document.addEventListener("turbo:load", () => {
  const count = Number(document.body.dataset.badge)
  if (!navigator.setAppBadge || Number.isNaN(count) || document.body.dataset.badge === undefined) return
  ;(count > 0 ? navigator.setAppBadge(count) : navigator.clearAppBadge()).catch(() => {})
})

// Un menu déroulant (réglages, client) se referme d'un clic ailleurs : la page floutée derrière invite à toucher à côté.
document.addEventListener("click", (event) => {
  document.querySelectorAll("details.settings[open], details.account-switcher[open]").forEach((details) => {
    if (!details.contains(event.target)) details.open = false
  })
})
