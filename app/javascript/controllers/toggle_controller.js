import { Controller } from "@hotwired/stimulus"

// Un bouton qui déplie ou replie un bloc : sur téléphone, les filtres d'une liste restent rangés derrière « Filtrer »,
// et les espaces derrière le bouton de menu (qui se referme d'un clic ailleurs ou avec Échap).
export default class extends Controller {
  static targets = [ "button" ]

  toggle() {
    this.#set(!this.element.classList.contains("open"))
  }

  close() {
    if (this.element.classList.contains("open")) this.#set(false)
  }

  outside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  #set(open) {
    this.element.classList.toggle("open", open)
    this.buttonTarget.setAttribute("aria-expanded", open)
  }
}
