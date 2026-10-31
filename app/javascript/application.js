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

// « il y a 15 jours » au survol d'une date : recalculé à ce moment, pour rester juste sur une page restée ouverte.
// Même calcul que time_ago (ApplicationHelper).
const agoCount = (count, one, many) => `il y a ${count} ${count === 1 ? one : many}`
function timeAgo(time, now = new Date()) {
  const seconds = (now - time) / 1000
  const day = (date) => Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
  const days = Math.round((day(now) - day(time)) / 86400000)
  let months = (now.getFullYear() * 12 + now.getMonth()) - (time.getFullYear() * 12 + time.getMonth())
  if (now.getDate() < time.getDate()) months -= 1

  if (seconds < 60) return "à l'instant"
  if (seconds < 3600) return agoCount(Math.floor(seconds / 60), "minute", "minutes")
  if (days === 0) return agoCount(Math.floor(seconds / 3600), "heure", "heures")
  if (days === 1) return "hier"
  if (months < 1) return agoCount(days, "jour", "jours")
  if (months < 12) return `il y a ${months} mois`
  return agoCount(Math.floor(months / 12), "an", "ans")
}
document.addEventListener("pointerover", (event) => {
  const element = event.target.closest?.("time[data-ago][datetime]")
  if (!element) return
  const time = new Date(element.getAttribute("datetime"))
  if (Number.isNaN(time.getTime())) return
  const ago = timeAgo(time)
  const title = element.title
  element.title = element.dataset.ago === "long" && title.includes(" · ") ? `${ago} · ${title.split(" · ").slice(1).join(" · ")}` : ago
})
