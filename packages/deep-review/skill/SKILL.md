
# Deep Design Review

Use this skill to run an exploratory design review. It complements ordinary
code review; it does not replace checks for correctness, security, or style.

## When to Use

- A change is structurally large, cross-cutting, or difficult to reverse.
- The request is to assess the design or migration strategy, not merely the diff.
- A normal review found no defect but the proposed solution still feels costly,
  coupled, or poorly aligned with the system.

Do not use this skill for routine, localized changes unless the requester asks.

## Inputs

Supply the entry points; the reviewer expands from there. It can read, search,
run commands, and fetch, so it follows linked issues, pull requests, and
documents itself, in its own context rather than yours. Do not read a chain of
linked material into this conversation to pass it along.

Give it:

- The change or proposed change: diff, branch, PR, issue, or relevant files.
- The stated objective, constraints, and acceptance criteria.
- Anything relevant that is not reachable from those — local notes, a verbal
  constraint, an unlinked decision — since the reviewer can only follow links
  that exist.
- Whether this change is one step of a staged migration, and where the earlier
  steps are, if that is not evident from the PR itself.

Missing context is not a reason to invent it. State what was inspected and
frame uncertain conclusions as questions or conditional observations.

## Dispatch

Dispatch the `deep-design-reviewer` subagent. It is read-only by mandate
rather than by tool restriction: it investigates freely but changes nothing,
posts nothing, and leaves nothing behind. Pass the entry points and the diff,
and say plainly if the requester has ruled any material out of scope — for
example the current PR's own review comments, when the point is to see what an
independent reading finds.

## Using the Result

The subagent returns one JSON object. Check that it parses before using it.
Use `declaration_diff_alignment.verdict` as the first triage point, then
inspect every `lens_assessments` status to distinguish investigated concerns
from uninvestigated or evidence-limited lenses. Render the structured result
as concise Markdown for people, using the following order.

1. **Review summary** — `synthesis.apparent_goal`, relevant strengths, and
   the consequential concern or uncertainty.
2. **Whether this really belongs in one change** — always render
   `purpose_units` and `purpose_unit_cohesion` immediately after the summary,
   under a short, plain heading naming what the section actually covers (not
   a schema name like "purpose-unit cohesion"). When the verdict is
   `split-recommended`, make the heading name the mixed purposes themselves
   and make this the visual focus of the review. Show the independent
   purposes, their available acceptance/verification/rollback units, the
   absence or presence of required dependencies, and `required_next_step`.
3. **Whether the diff matches what it claims to do** — always render this
   after the purpose section, under a short, plain heading (not a schema name
   like "declaration-diff alignment"). When the verdict is `contradiction`,
   make the heading name the contradiction itself and make this the visual
   focus of the review. Include the relevant declared change type or
   invariant, observed changes, reasoning, and `required_next_step`. Do not
   bury a contradiction in questions or recommendations.
4. **Material findings** — render `findings` only. Keep evidence, consequence,
   and options together. Do not repeat the finding from step 3 verbatim; refer
   back to it by what it actually found, not by a schema name.
5. **Questions requiring a decision** — render `questions` and open questions
   from findings. State only questions whose answer can change a conclusion or
   select between options.
6. **Review coverage** — render each lens as one compact line, grouped by
   status, using a plain phrase for what was actually done rather than the
   schema label. State `no-material-concern` as "investigated, nothing
   material found" (not a guarantee or a test pass). Render
   `insufficient-evidence` and `not-applicable` explicitly, as plain
   statements of what limited the check, not as schema names.
7. **Review limits** — render `review_limits` verbatim and briefly.

If the JSON is invalid or misses required fields, do not silently improvise a
review. State the validation failure and retain the raw response for diagnosis.

Read `review_limits` before rendering. The reviewer can fetch and run things
itself, so a limit naming material it could have reached is a defect in the
review, not a fact about the change — send it back rather than passing it
through to the reader. Only limits that survive that check belong in the
rendered review.

## Plain-language rendering

The reviewer's JSON and its internal reasoning use precise analytical terms
(contract, cohesion, alignment, lens, purpose unit, gate) on purpose — those
terms keep the analysis rigorous, and the JSON schema itself must not change.
When you turn that JSON into Markdown for a person, do not carry the terms
over as labels. Say the concrete thing the term stands for instead, in
whatever language you are rendering in:

- Instead of naming a "contract", name the actual interface, config key, error
  behavior, or data shape that is at stake.
- Instead of asserting "alignment" or "contradiction", say plainly what the
  proposal claims and what the diff actually does.
- Instead of asserting "cohesion", say whether the purposes actually belong in
  one change or would ship, verify, or roll back better on their own.
- Instead of naming a "lens", state the actual question that was checked.

This is a wording change only: keep every substantive fact, severity, and
piece of evidence exactly as reported. The result should read like a
colleague explaining a concern out loud, not like a summary of the schema.

Treat findings as hypotheses for a design conversation, not merge blockers by
default. A finding is useful when it identifies a concrete system-level cost,
an unstated constraint, a missing alternative, or a safer change sequence.
Discard findings that depend on unsupported assumptions or only restate
general design advice.

When the review identifies a change strategy concern, prefer a follow-up that
defines a smaller, observable intermediate step over a request for a broad
rewrite.
