# RFC: Candidate Onboarding with CV Upload

- Status: Implemented
- Owners: Dental Onboarding team
- Related code: `app/models/candidate_profile.rb`, `app/services/cv/`, `app/jobs/`, `app/controllers/onboarding/`, `app/controllers/candidates_controller.rb`

## Summary

Candidates sign up, upload a CV, and get a profile that's pre-filled from that CV wherever we can extract data confidently. They review and complete anything we couldn't extract, then submit. Recruiters are notified and can browse completed profiles and download the original CV. Extraction is pluggable: a dependency-free heuristic/regex parser is the default and fallback; an LLM-backed parser (Claude, via the Anthropic Ruby SDK) can be enabled per-environment for higher-quality extraction.

## Goals

- Let a candidate go from "I have a CV" to "a recruiter can see my complete profile" in two steps: upload, then review/complete.
- Never invent data. Anything the parser can't find is left blank for the candidate to fill in — no hallucinated fields.
- Keep the parsing backend swappable without touching controllers, jobs, or views.
- Keep CVs private: never expose a signed Active Storage URL; downloads only happen through an authenticated, authorized controller action.
- Apply the dental-recruitment domain's conditional form logic (BIG registration, salary vs. percentage, average daily revenue) correctly based on job function and employment type.

## Non-goals

- Candidate-facing search/matching against recruiter requirements.
- Multi-CV support (a candidate can upload more than one document over time, but the profile is prefilled only once, from whichever the parsing job most recently completed).
- Editing a profile after `onboarding_completed_at` is set is still possible (same form), but there's no separate "locked" state or recruiter-side edit history.

## Data model

```
User (role: candidate | recruiter)
 └── CandidateProfile (1:1, created automatically on user creation)
      ├── CandidateDocument (has_many; has_one_attached :file via Active Storage)
      ├── Education (has_many)
      ├── WorkExperience (has_many)
      ├── CandidateLanguage (has_many, through: Language)
      └── CandidateSkill (has_many, through: Skill; skill_id nullable for free-text suggestions)
Skill (name, function_group)
Language (name)
```

Key columns on `candidate_profiles`: `job_function`, `employment_types` (array), `preferred_regions` (array), `transport_types` (array), `available_working_days` (array), `search_status`, `desired_gross_salary`, `desired_percentage`, `average_daily_revenue`, `big_registration_status`, `big_number`, `extracted_fields` (array — tracks which fields came from the CV, drives the "From CV" badge), `consent_given_at`, `onboarding_completed_at`.

`CandidateDocument` tracks `parsing_status` (`pending → processing → completed | failed`), `parsed_data` (raw extraction result, jsonb), `error_message`, and the file metadata (`original_filename`, `content_type`, `byte_size`) captured at upload time rather than trusted from the attached blob later.

`Education` / `WorkExperience` / `CandidateSkill` carry a `source` (`manual` vs `cv`) and, for the first two, `needs_review` — set when the CV parser produced an entry the candidate hasn't confirmed.

## Flow

### Step 1 — Registration and CV upload

1. `POST /registration` creates a `User` (role: `candidate`), which auto-creates a blank `CandidateProfile` via an `after_create_commit` callback, and starts a session.
2. Candidate lands on `GET /onboarding/cv_upload/new`. If a document already exists, they're redirected straight to the status page (no double upload).
3. `POST /onboarding/cv_upload` requires an explicit consent checkbox (`consent_given_at` is stamped on the profile) and a PDF/DOC/DOCX file under the configured size limit. On success it enqueues `ParseCandidateCvJob` and redirects to `GET /onboarding/status`, which auto-refreshes (meta-refresh, 2s) while `parsing_status` is `pending`/`processing`.

### Background parsing

`ParseCandidateCvJob`:

1. Marks the document `processing`.
2. `Cv::TextExtractor.call(document)` pulls raw text (pdf-reader for PDF, the `docx` gem for `.docx`, macOS `textutil` shell-out for legacy `.doc`).
3. `Cv::ParserFactory.build.call(text)` runs the selected parser (see below), returning a `Cv::ExtractionResult`.
4. On success: stores `parsed_data`, marks `completed`, and calls `Cv::ProfilePrefiller.call(profile, result)`.
5. On `Cv::TextExtractor::ExtractionError` or any other `StandardError`: marks the document `failed` with an error message, and never leaves it stuck in `processing`. The candidate is routed to manual entry — parsing failure is not a dead end.

`Cv::ProfilePrefiller` only ever fills a field that's currently blank; it never overwrites something the candidate already entered. It tracks which scalar fields it touched in `extracted_fields` (for the "From CV" badge), skips education/work-experience entries missing their key identifying field (study/institution, job title/company), and matches languages/skills case-insensitively against existing `Language`/`Skill` records — unmatched skill names become free-text `CandidateSkill` suggestions (`skill_id: nil`) for recruiter review rather than being silently dropped or invented as new canonical skills.

### Parser selection

```
Cv::ParserFactory.build
  → Cv::LlmParser.method(:call)        if LLM_CV_PARSING_ENABLED=true and ANTHROPIC_API_KEY is set
  → Cv::HeuristicParser.method(:call)  otherwise
```

`Cv::LlmParser` calls Claude (via `Llm::AnthropicClient`, using a forced tool call so the response is guaranteed-shape JSON, not free text) and itself falls back to `Cv::HeuristicParser` if the client raises `Llm::Client::Error`. So there are two independent fallback layers: env-gating at the factory level, and runtime-failure fallback inside the LLM parser. Either path returns the same `Cv::ExtractionResult` shape, so nothing downstream needs to know which parser ran.

The `Llm::Client` interface (`extract_structured(text:, schema:, instructions:)`) is deliberately generic — swapping providers means writing a new class with that one method, not touching the job, the prefiller, or the factory.

### Step 2 — Review and complete

`GET /onboarding/profile/edit` renders every field, with a "From CV" badge (`field_extracted_from_cv?`) on scalars that were prefilled, and a "From CV — needs review" badge on education/work-experience rows sourced from the CV. Repeated sub-resources (education, work experience, languages) use a Stimulus "repeater" controller: a hidden `<template>` clones a blank `fields_for` block with a `NEW_RECORD` placeholder swapped for a timestamp index; removing a persisted row toggles `_destroy` instead of deleting the DOM node, removing an unsaved row just removes the DOM node.

Conditional UI, driven by a second Stimulus controller reading data attributes seeded from Ruby constants:

| Condition | Effect |
|---|---|
| `job_function` in `general_dentist, dental_hygienist, specialist` | Show BIG registration status + BIG number |
| `job_function` in `general_dentist, dental_hygienist, specialist, prevention_assistant` | Show average daily revenue |
| `employment_types` includes `employed` | Show desired gross salary |
| `employment_types` intersects `self_employed, freelance, percentage_based` | Show desired percentage |
| `job_function` selected | Show only the skill checkboxes for that function's `Skill.function_group` (plus an always-visible "general" section) |

`PATCH /onboarding/profile` validates in a `:complete` context (first/last name, city, phone, job function, max travel time, available-from, at-least-one-region/employment-type/working-day/language are only enforced here, not on every save) and stamps `onboarding_completed_at`. `big_number_present_if_registered` (BIG number required when `big_registration_status: big_registered`) is validated unconditionally, in any context, since a candidate should never be able to persist a BIG-registered status without a number even mid-edit.

On successful completion:
- `AdminNotifierMailer.onboarding_completed(profile).deliver_later` — emails every recruiter (`User.recruiter.pluck(:email_address)`); if there are no recruiters, the mailer action returns before calling `mail(...)` and nothing is sent.
- `CandidateOnboardingWebhookJob.perform_later(profile.id)` — only enqueued if `ONBOARDING_WEBHOOK_URL` is set; POSTs a JSON payload (`event`, `full_name`, and profile summary fields) to that URL. Missing/blank env var is a silent no-op, not an error.

### Recruiter side

`CandidatesController` (`before_action :require_recruiter!`) exposes:
- `GET /candidates` — completed profiles only (`where.not(onboarding_completed_at: nil)`), most recent first.
- `GET /candidates/:id` — full profile detail, respecting the same `show_*?` conditional-visibility rules as the candidate form.
- `GET /candidates/:id/cv` — streams the most recent `CandidateDocument`'s file via `send_data document.file.download`, not a redirect to a signed Active Storage URL. This is the only way to retrieve CV bytes; there is no other route that exposes them.

## Security & privacy

- CVs are never reachable via a bypassable signed URL — `send_data` streams the blob through an authenticated, `require_recruiter!`-gated controller action.
- Consent is mandatory and timestamped before any parsing happens.
- CSRF protection is on in every environment except `test` (where it's disabled purely to simplify integration tests, per Rails convention).
- Recruiter vs. candidate authorization is enforced per-controller (`require_candidate!` / `require_recruiter!`), redirecting to `root_path` on violation — verified in both directions by the test suite and by a live smoke test.
- The parser never invents values: every field the heuristic/LLM parser can't find is left blank, `job_function` values that don't match the enum are rejected rather than coerced, and the LLM path constrains the model to a single structured tool call instead of freeform generation.

## Testing

51 tests, no mocking gems beyond stock Minitest facilities (`Object#stub`, `Minitest::Mock` — reintroduced via the `minitest-mock` gem since Minitest 6 split them out of core):

- **Models**: `User`, `CandidateProfile` (conditional-visibility predicates, `:complete`-context validation, skill/language assignment idempotency), `Education`, `WorkExperience`, `CandidateLanguage`.
- **Services**: `Cv::HeuristicParser` (against a traced, deterministic CV sample), `Cv::ParserFactory` (env-gating matrix), `Cv::LlmParser` (fake `Llm::Client` double, enum-rejection, fallback-on-error), `Cv::ProfilePrefiller` (non-overwrite guarantee, skip-guards, case-insensitive matching).
- **Jobs**: `ParseCandidateCvJob` (all three outcome branches), `CandidateOnboardingWebhookJob` (no-URL no-op, and a `Net::HTTP`-mocked POST assertion).
- **Mailer**: recruiter addressing, and the no-recruiters early-return path.
- **Controllers/integration**: registration, CV upload (consent gate, duplicate-upload redirect, role gate), profile completion (happy path with mailer assertion, validation-failure path), candidate list/detail/CV-download (including cross-role authorization checks).

A live end-to-end smoke test (real Puma dev server, a hand-built valid PDF, actual HTTP requests with CSRF tokens) additionally exercised: registration → upload → heuristic-parser extraction → prefilled review form with correct "From CV" badges and skill checkboxes → completion → recruiter email delivery → recruiter list/detail/CV download producing byte-identical file content → cross-role redirect enforcement. This caught one bug the unit tests didn't: the status view called enum predicates with a `parsing_status_` prefix that doesn't exist (the enum has no `prefix:` option), which 500'd on real requests despite every job/model test passing in isolation.

## Alternatives considered

- **Hard-coding the Anthropic SDK into the job**: rejected in favor of the `Llm::Client` interface + `Cv::ParserFactory` env-gating, so parsing works with zero external dependencies out of the box and any team can swap providers without touching job/controller code.
- **Redirecting to a signed Active Storage URL for CV download**: rejected — a signed URL, once issued, can be shared or cached outside the app's authorization boundary. Streaming through `send_data` in an authorized action keeps every download subject to the current session's role check.
- **DB-backed lookup tables for regions/transport types/employment types**: rejected for `PREFERRED_REGIONS`, `TRANSPORT_TYPES`, `EMPLOYMENT_TYPES`, `WORKING_DAYS` (kept as Ruby array constants) — these are fixed, non-recruiter-editable option sets, unlike `Skill` and `Language` which recruiters may need to extend and which the PRD called out as needing DB-backed maintenance.

## Open questions / follow-ups

- No re-parsing/re-upload flow exists if a candidate wants to replace an already-parsed CV with a new one — currently `new_onboarding_cv_upload_path` redirects away once any document exists.
- `internal_notes` and `professional_summary` columns exist on `CandidateProfile` but aren't yet surfaced in either the candidate or recruiter views.
- No pagination on `GET /candidates` — fine at current expected volume, worth revisiting if the completed-candidate count grows significantly.
