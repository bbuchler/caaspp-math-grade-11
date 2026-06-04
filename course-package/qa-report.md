# QA Report

## Verdict

Status: Draft pilot package ready for teacher review and preview testing.

This is not yet a deployed app. It is a structured course package with Week 1 lessons, source-locking, media plan, rubrics, AI rules, and QA notes.

## Checks Completed

### Gate 0 - Source And Scope

Status: Pass for draft.

- Course sources are listed in `source-lock.md`.
- Official CAASPP/Smarter Balanced sources are separated from teacher-provided planning materials.
- Privacy boundaries are stated.
- Open questions are recorded.

### Gate 1 - Course Map

Status: Pass for draft.

- Five Week 1 lessons are mapped to objectives and gates.
- Each lesson has practice and an exit check.
- The week now progresses across skill, representation, difficulty, and independence.

### Gate 2 - Learner Quality

Status: Needs teacher spot-read.

- Lessons are student-facing and include worked examples.
- Contexts are concrete: rideshare, lunch, gym membership, fundraiser, school dance.
- Teacher should confirm tone and difficulty fit Altus students.

### Gate 3 - Assessment Quality

Status: Pass for draft.

- Objective items have answers and explanations.
- Open-response items point to rubrics.
- Retake pool is small; future build should expand item variety.

### Gate 4 - Gating And Remediation

Status: Pass for draft.

- Each lesson has mastery, remediation, and enrichment notes.
- Remediation targets missed concepts instead of sending students back vaguely.

### Gate 5 - Teacher Review

Status: Not complete.

- Teacher has not yet reviewed the lesson text, videos, or item difficulty.
- This should happen before classroom use.

### Gate 6 - Media Quality

Status: Partial.

- Video candidates are real links and each has contextual questions.
- Lesson 01 now uses a YouTube embed URL from the Khan video and transcript-verified questions.
- Infographic specs are written and first-pass SVG infographic assets exist.
- Preview includes embedded video frames plus fallback links.
- Khan Academy direct embeds may be blocked by the provider. Future lessons should use YouTube embed URLs or Reel-hosted embeds where possible.
- Current SVG graphics are marked `needs revision`, not approved for classroom release.
- Future real-world/generated graphics must pass visual QA before approval.
- Lesson 01 NotebookLM infographic was visually inspected and inserted into preview. It is approved for draft use with minor final-copy caveats.

### Gate 7 - AI Supports

Status: Pass for draft.

- Study Buddy is constrained to Week 1 course content.
- AI grading is limited to explanations, error analysis, and modeling rubrics.
- Teacher review triggers are listed.

## Automated Text Checks Run

- Placeholder/meta-instruction scan: passed after removing false positives from the report itself.
- Private student data marker scan: passed after removing false positives from the privacy warning itself.
- Lesson JSON parse check: passed.
- Quiz bank JSON parse check: passed.

## Known Risks

- Khan Academy pages may need a different embed method than the older course sites, which used YouTube IDs. Lesson 01 confirms the better pattern: use YouTube embed when available; Reel-hosted embeds may be the cleanest path for teacher-created overviews.
- The current lesson JSON is a package contract, not proof that the existing photography/drivers ed renderer can display every math item type.
- First-pass SVG infographic assets exist, but they need visual teacher review and can be replaced with polished graphics later.
- More question variety is needed before this becomes a full production retake-ready unit.

## Graphic Verification Rule

Do not approve graphics from filenames or thumbnails. Open each actual image and inspect it on desktop and phone-width previews. Reject or revise any graphic with cropped text, overflowing labels, misspelled text, wrong math, or imagery that distracts from the problem.

## Recommended Next Build Step

Create a small renderer prototype for one lesson, probably Lesson 01, then verify it on desktop and phone. Do not build all four weeks into the app until one math lesson renders, grades, and saves correctly.
