import { Controller } from "@hotwired/stimulus"

// Generic add/remove repeater for nested-attributes fields (educations,
// work experiences, languages). New rows are cloned from a <template> with
// a NEW_RECORD index placeholder; persisted rows are soft-removed via their
// _destroy field so accepts_nested_attributes_for can process the deletion.
export default class extends Controller {
  static targets = ["list", "template", "item"]

  add(event) {
    event.preventDefault()
    const index = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, index)
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-repeater-target='item']")
    if (!item) return

    const destroyField = item.querySelector("input[name*='_destroy']")
    if (destroyField) {
      destroyField.value = "1"
      item.hidden = true
    } else {
      item.remove()
    }
  }
}
