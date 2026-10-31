import { Controller } from "@hotwired/stimulus"

// Le bandeau de confirmation (« Fil archivé », avec « Annuler ») s'efface tout seul après quelques secondes,
// sauf si la souris ou le focus s'y attardent : le temps restant reprend là où il s'était arrêté, comme le fil
// qui se consume en bas du bandeau. Un clic sur le bandeau (hors bouton) le ferme tout de suite.
export default class extends Controller {
  static values = { delay: { type: Number, default: 6000 } }

  connect() {
    this.remaining = this.delayValue
    this.element.style.setProperty("--toast-delay", `${this.delayValue}ms`)
    this.pause = this.pause.bind(this)
    this.resume = this.resume.bind(this)
    this.element.addEventListener("mouseenter", this.pause)
    this.element.addEventListener("mouseleave", this.resume)
    this.element.addEventListener("focusin", this.pause)
    this.element.addEventListener("focusout", this.resume)
    this.resume()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  pause() {
    if (!this.timer) return
    clearTimeout(this.timer)
    this.timer = null
    this.remaining -= Date.now() - this.startedAt
    this.element.classList.add("paused")
  }

  resume() {
    if (this.timer || this.element.contains(document.activeElement)) return
    this.startedAt = Date.now()
    this.element.classList.remove("paused")
    this.timer = setTimeout(() => this.dismiss(), Math.max(this.remaining, 0))
  }

  dismiss(event) {
    if (event?.target.closest("button, a, form")) return
    clearTimeout(this.timer)
    this.element.classList.add("gone")
  }
}
