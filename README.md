# Dental Onboarding

A Rails 8 application that lets dental candidates onboard themselves in minutes instead of filling in a long form by hand. A candidate signs up, uploads their CV, and the app reads that CV in the background and pre-fills as much of the profile as it can. The candidate then reviews what was found — every extracted field is badged **"From CV"** — corrects anything that looks off, fills in the rest, and submits. Recruiters get a clean list of completed candidates and can download the original CV through an authenticated, private link.

The whole point is to move the boring data-entry work off the candidate and onto the machine, while still keeping the candidate in control of the final result.

---

## Table of contents

- [The onboarding flow](#the-onboarding-flow)
- [Why it is built this way](#why-it-is-built-this-way)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [How CV parsing works](#how-cv-parsing-works)
- [The domain model](#the-domain-model)
- [Conditional profile fields](#conditional-profile-fields)
- [What happens when a candidate submits](#what-happens-when-a-candidate-submits)
- [Roles and access control](#roles-and-access-control)
- [Configuration](#configuration)
- [Background jobs](#background-jobs)
- [Project layout](#project-layout)
- [Running the tests](#running-the-tests)
- [Code style](#code-style)

---

## The onboarding flow

Onboarding is deliberately just **two steps** for the candidate:

1. **Upload CV** (`/onboarding/cv_upload`)
   The candidate picks a PDF, DOC, or DOCX file and ticks a consent box confirming the CV may be processed to build their profile. The file is validated (type + size), stored privately, and a background job is kicked off to read it.

2. **Review & complete** (`/onboarding/profile`)
   The candidate lands on a form that is already partly filled in from their CV. Fields that came from the parser carry a **"From CV"** badge; work and education rows the parser is unsure about are flagged **"needs review"**. The candidate corrects anything wrong, fills in the required fields the CV didn't cover, and submits.

In between sits a short **status screen** (`/onboarding/status`) that shows a spinner while the CV is being parsed. It refreshes itself and, the moment parsing settles — whether it succeeded or failed — forwards the candidate straight to the review form. There is no dead-end "all done" page to click through.

If parsing fails for any reason, the candidate is still sent to the review form (with a friendly notice) and can fill everything in manually. **A candidate is never blocked by a parsing problem.**

---

## Why it is built this way

A few decisions shape the whole codebase:

- **Parsing is asynchronous.** CV extraction — especially LLM-backed extraction — is slow and can fail. Doing it inside the upload request would mean a spinner on a hung HTTP call. Instead the upload returns immediately and a background job does the work, so the request path is always fast.
- **The parser never gets the last word.** Everything the parser produces is presented back to the candidate for review and is fully editable. Extracted values are tracked (`extracted_fields`) so a re-upload can refresh what a *previous* CV filled in, but a value the candidate typed themselves is never overwritten.
- **Business logic lives in services, not controllers.** Controllers stay thin: they call a service object (`CandidateDocuments::UploadService`, `CandidateProfiles::CompletionService`, and so on) and branch on a small `Result` object. This keeps request handling readable and the logic unit-testable in isolation.
- **Reference data lives in `app/constants`.** Job functions, employment types, regions, skill groups, language levels, and the like are defined as frozen constants, so the enums, the seed data, and the form all draw from one source of truth.

---

## Requirements

- **Ruby 3.3.0** (see `.ruby-version`)
- **PostgreSQL**
- **Bundler**

No Node/JS build step is required — the front end uses import-mapped Stimulus controllers, not a bundler.

---

## Getting started

Install dependencies and set up the database:

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
```

`db:seed` loads the reference data the app needs to function: the master **skills** list (grouped per job function), and the supported **languages**. Without it the skill and language pickers on the profile form will be empty.

Start the app:

```bash
bin/dev
```

Then open <http://localhost:3000>. Create a candidate account from the landing page to walk through the flow.

---

## How CV parsing works

When a CV is uploaded, `ParseCandidateCvJob` runs in the background. It:

1. Marks the document as `processing`.
2. Extracts raw text from the file (`Cv::TextExtractor`).
3. Hands that text to a parser (`Cv::ParserFactory` chooses which one).
4. Writes the structured result onto the document (`parsed_data`, `parsing_status: completed`) and pre-fills the profile (`Cv::ProfilePrefiller`).

There are **two parsers**, chosen at runtime by `Cv::ParserFactory`:

| Parser | Backing | When it runs |
| --- | --- | --- |
| `Cv::HeuristicParser` | Pure Ruby (regex + keyword rules, tuned for dental CVs) | Default. Works entirely offline, no external service. |
| `Cv::LlmParser` | Anthropic API (`claude-opus-4-7`) | Opt-in. Produces much richer, more accurate extraction. |

The LLM parser only runs when it is **switched on and an API key is present**. If it is disabled, or the API key is missing, or the Anthropic call fails for any reason, the app quietly falls back to the heuristic parser — so an outage or a missing key can never block a candidate.

Turn on LLM parsing with:

```bash
LLM_CV_PARSING_ENABLED=true
ANTHROPIC_API_KEY=your_key_here
```

Whatever the parser finds, the result is stored and every extracted field is tracked so the review form can badge it and so re-uploads behave predictably.

---

## The domain model

At the centre is a **`CandidateProfile`**, which belongs to a **`User`** and owns everything gathered during onboarding:

```
User ──has one── CandidateProfile
                     ├── has_many CandidateDocuments   (the uploaded CVs + parse status)
                     ├── has_many Educations           (repeatable)
                     ├── has_many WorkExperiences       (repeatable)
                     ├── has_many CandidateSkills ─── Skills        (from a curated list, grouped by function)
                     └── has_many CandidateLanguages ─ Languages    (each with a proficiency level)
```

- **`CandidateDocument`** holds the uploaded file (via Active Storage), its `parsing_status` (`pending → processing → completed / failed`), and the raw `parsed_data`. Uploads are validated for allowed content type/extension (PDF, DOC, DOCX) and a configurable maximum size.
- **`Education`, `WorkExperience`, `CandidateSkill`, `CandidateLanguage`** each carry a `source` (`cv` or `manual`) so the app can tell parser-created rows apart from ones the candidate added, and can safely rebuild CV rows on a re-upload without touching manual ones.
- **`Skill`** rows are grouped by job function; the profile form shows only the skill group relevant to the candidate's chosen function, plus general skills, plus a free-text box for skills that aren't on the list (a recruiter reviews those later).

Reference vocabularies (job functions, employment types, preferred regions, working days, transport types, language levels, BIG registration statuses, etc.) live under `app/constants/` and back the model enums.

---

## Conditional profile fields

The review form adapts to the candidate. `CandidateProfiles::FieldVisibilityService` (mirrored on the client by the `onboarding_form` Stimulus controller) decides what to show:

- **BIG registration** — shown only for job functions that require Dutch BIG registration. When a candidate marks themselves as BIG-registered, the BIG number becomes required.
- **Average daily revenue** — shown only for the job functions where it is relevant.
- **Desired gross salary** — shown when the candidate is open to *employed* positions.
- **Desired percentage** — shown for percentage-based employment types.
- **Skill group** — the skills checklist swaps to match the selected job function.

Because this logic is enforced both server-side (visibility service + validations) and client-side (Stimulus), a field that isn't relevant is neither shown nor able to block submission.

---

## What happens when a candidate submits

`CandidateProfiles::CompletionService` runs the submission:

1. It validates the profile against the `:complete` context — the full set of "ready to send to a recruiter" rules (required contact details, a valid phone number, job function, at least one preferred region / employment type / working day / language, an availability date, a desired percentage within 0–100, and so on). Field-level rules that always apply (email format, non-negative numbers) run at every save.
2. If valid, it stamps `onboarding_completed_at` and enqueues `NotifyRecruitersOfCompletedOnboardingJob`.
3. That job emails the recruiters (`AdminNotifierMailer`) and, **if an onboarding webhook URL is configured**, enqueues `CandidateOnboardingWebhookJob`, which POSTs a `candidate_onboarding_completed` event (id, name, function, city, completion time) to that URL. Webhook delivery failures are logged, not fatal.

If validation fails, `onboarding_completed_at` is left unset and the form re-renders with the errors, so an incomplete profile is never marked complete.

---

## Roles and access control

There are two kinds of users:

- **Candidates** go through the onboarding flow. Every onboarding controller inherits from `Onboarding::BaseController`, which requires a candidate session and always scopes work to *that* candidate's own profile.
- **Recruiters** browse completed candidates and download CVs. `CandidatesController` requires a recruiter session.

CVs are **never exposed by a public URL.** A recruiter downloads a CV through an authenticated controller action (`CandidatesController#cv`) that streams the file with `send_data` only after the recruiter check passes — so the file cannot be reached without a valid recruiter session.

---

## Configuration

All of these are optional environment variables:

| Variable | Purpose | Default |
| --- | --- | --- |
| `LLM_CV_PARSING_ENABLED` | Turns on Anthropic-backed CV parsing | off (heuristic parser only) |
| `ANTHROPIC_API_KEY` | API key used when LLM parsing is on | none |
| `LLM_MODEL` | Model used for LLM parsing | `claude-opus-4-7` |
| `MAX_CV_SIZE_MB` | Largest CV upload accepted, in MB | `25` |
| `ONBOARDING_WEBHOOK_URL` | If set, completed onboardings are POSTed here as a `candidate_onboarding_completed` event | none |

---

## Background jobs

Background work runs on **Solid Queue**, which is backed by the database — there is nothing extra to install or run. In production it runs inside the Puma process (`SOLID_QUEUE_IN_PUMA`). The jobs are:

- **`ParseCandidateCvJob`** — reads an uploaded CV and pre-fills the profile. Any failure is recorded on the document as `failed` (never left stuck at `processing`) so the candidate can be routed to manual entry.
- **`NotifyRecruitersOfCompletedOnboardingJob`** — emails recruiters when a candidate finishes, and fans out to the webhook job if one is configured.
- **`CandidateOnboardingWebhookJob`** — POSTs the completion event to an external webhook when `ONBOARDING_WEBHOOK_URL` is set.

---

## Project layout

A quick map of where things live:

```
app/
  controllers/onboarding/   # the two-step candidate flow (cv_upload → status → profile)
  controllers/              # sessions, registrations, passwords, candidates (recruiter side)
  models/                   # CandidateProfile and its associations
  services/
    candidate_documents/    # upload validation + storage
    candidate_profiles/     # completion, field visibility, skill suggestions
    cv/                     # text extraction, parsers, parser factory, profile prefiller
    candidates/             # recruiter list + authenticated CV download
    llm/                    # Anthropic client wrapper
  jobs/                     # the three background jobs above
  constants/                # frozen reference vocabularies (enums, skill groups, regions…)
  mailers/                  # recruiter notification + password reset
  javascript/controllers/   # Stimulus: onboarding_form (conditional fields), repeater (add/remove rows)
  views/onboarding/         # the candidate-facing screens
```

---

## Running the tests

```bash
bin/rails test
```

The suite covers the models, services, jobs, and controllers — including the parser's behaviour on realistic CV layouts, the conditional-field logic, upload validation, and the completion side-effects.

---

## Code style

The project follows the Omakase Ruby style. Check it with:

```bash
bin/rubocop
```
