import { Controller } from "@hotwired/stimulus"

// Shows/hides conditional sections of the profile form based on the PRD's
// business rules: BIG registration + average daily revenue depend on job
// function, desired salary/percentage depend on employment type, and the
// visible skill checklist depends on job function.
export default class extends Controller {
  static targets = [
    "jobFunction", "bigSection", "revenueSection",
    "salarySection", "percentageSection", "employmentType", "skillGroup"
  ]

  static values = {
    bigEligible: Array,
    revenueEligible: Array,
    percentageEmploymentTypes: Array,
    salaryEmploymentTypes: Array,
    skillGroups: Object
  }

  connect() {
    this.updateJobFunction()
    this.updateEmploymentTypes()
  }

  updateJobFunction() {
    const value = this.jobFunctionTarget.value

    this.toggle(this.bigSectionTarget, this.bigEligibleValue.includes(value))
    this.toggle(this.revenueSectionTarget, this.revenueEligibleValue.includes(value))

    const group = this.skillGroupsValue[value]
    this.skillGroupTargets.forEach((el) => {
      this.toggle(el, el.dataset.skillGroup === group)
    })
  }

  updateEmploymentTypes() {
    const checked = this.employmentTypeTargets.filter((el) => el.checked).map((el) => el.value)

    this.toggle(this.salarySectionTarget, checked.some((v) => this.salaryEmploymentTypesValue.includes(v)))
    this.toggle(this.percentageSectionTarget, checked.some((v) => this.percentageEmploymentTypesValue.includes(v)))
  }

  toggle(element, visible) {
    if (!element) return
    element.hidden = !visible
  }
}
