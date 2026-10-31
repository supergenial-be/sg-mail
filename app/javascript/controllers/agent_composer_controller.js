import { Controller } from "@hotwired/stimulus"

// Écrire à l'agent : Entrée envoie, Maj + Entrée va à la ligne. Le texte en cours est gardé (sessionStorage)
// tant qu'il n'est pas envoyé : la page se rafraîchit à chaque réponse de l'agent, sans le perdre.
export default class extends Controller {
  static targets = [ "text" ]
  static values = { key: String }

  connect() {
    this.restore = this.restore.bind(this)
    document.addEventListener("turbo:morph", this.restore)
    this.restore()
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.restore)
  }

  keydown(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return
    event.preventDefault()
    if (event.target.value.trim()) this.element.requestSubmit()
  }

  save() {
    try { sessionStorage.setItem(this.#storageKey, this.textTarget.value) } catch {}
  }

  // Une suggestion (« Résume ce fil ») n'envoie pas le texte en cours : il reste.
  clear(event) {
    if (event.submitter?.name === "prompt") return
    try { sessionStorage.removeItem(this.#storageKey) } catch {}
  }

  restore() {
    if (!this.hasTextTarget || this.textTarget.disabled || this.textTarget.value) return
    let draft = null
    try { draft = sessionStorage.getItem(this.#storageKey) } catch {}
    if (draft) this.textTarget.value = draft
  }

  get #storageKey() {
    return `agent-draft:${this.keyValue}`
  }
}
