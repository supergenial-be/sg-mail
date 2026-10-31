import { Controller } from "@hotwired/stimulus"

// L'agent à la Intercom : la bulle ouvre le tiroir, « Masquer » ou Échap le referme. L'état est porté par <html>
// (classe agent-open) et gardé dans sessionStorage : les rafraîchissements de la page (Turbo morph, à chaque
// réponse de l'agent) ne touchent que <body>, et le tiroir reste ouvert d'un fil à l'autre.
const KEY = "agent-drawer"

export default class extends Controller {
  static targets = [ "drawer", "body" ]

  connect() {
    this.refresh = this.refresh.bind(this)
    document.addEventListener("turbo:morph", this.refresh)
    let open = false
    try { open = sessionStorage.getItem(KEY) === "open" } catch {}
    this.#apply(open)
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.refresh)
    document.documentElement.classList.remove("agent-open")
  }

  // « . » ouvre (la bulle est fixe : le contrôleur de raccourcis ne la voit pas), Échap referme.
  key(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (event.key === "Escape") return this.close()
    if (event.key !== "." || event.target.closest("input, textarea, select, [contenteditable]")) return
    event.preventDefault()
    this.open()
  }

  open() {
    this.#apply(true)
    requestAnimationFrame(() => this.drawerTarget.querySelector("textarea:not(:disabled)")?.focus())
  }

  close() {
    if (!document.documentElement.classList.contains("agent-open")) return
    this.#apply(false)
    this.element.querySelector(".agent-launcher")?.focus()
  }

  refresh() {
    this.#apply(document.documentElement.classList.contains("agent-open"))
  }

  #apply(open) {
    document.documentElement.classList.toggle("agent-open", open)
    this.element.querySelector(".agent-launcher")?.setAttribute("aria-expanded", open)
    try { sessionStorage.setItem(KEY, open ? "open" : "closed") } catch {}
    if (open) requestAnimationFrame(() => { this.bodyTarget.scrollTop = this.bodyTarget.scrollHeight })
  }
}
