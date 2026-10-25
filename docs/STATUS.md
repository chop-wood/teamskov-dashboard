# Status

_Last updated: 2026-10-25 (Sunday), end of first session._

## Done
- Explored every source (DASH, MICA, Teams lead channels, the phone list, Breesy). Findings are in `PROJECT_SPEC.md`.
- Made the key decisions: divisions, scope dates, required documents, mortgage rule, Teams-note format, sign-in approach, guardrails, Saturday weekly update, and DASH as the source of truth.
- Database schema written: `supabase/migrations/20261025000000_initial_schema.sql` (parses as valid Postgres).
- Repo set up: README, `.gitignore`, `.env.example`, `CLAUDE.md`.

- **Supabase tables created** 10/25 (run in the SQL Editor). Verified: all 15 tables + `open_flags` view exist; offices (6), required_documents (8), excluded_jobs (5) seeded; anonymous access sees nothing.

## Not done yet
- No collectors or dashboard code yet.
- Pushing to GitHub from Claude is blocked by the app's safety check in auto mode, even with `.claude/settings.local.json`. Dan pushes (`git push`) or approves it in a mode that asks.

## Next steps (in order)
1. Create the "Dashboard" custom report in DASH (approved): Job Id, Job Number, Supervisor, Estimator, Coordinator, Status, Date Received/Inspected/Started/Closed, Total Estimates, Supplement, WO Budget, Job Cost, Invoiced, Collected, GP%.
2. DASH collector: open jobs (JSON API), the custom report, documents and notes per job → Supabase.
3. A dashboard mock-up with real data for Dan to react to.
4. MICA collector (Recent Uploads + Work Authorization tab per loss) and matching.
5. Teams lead collector + "From Teams" DASH notes (dry run first, showing exactly what would be written).
6. Phone list weekly sync.
7. Scheduling of the morning run; Saturday weekly update draft.

## Open questions
- Capacity model (later; placeholder card on Summary).
- Weekly update format.

## Things spotted along the way (worth a look)
- 26-2089-WTR (Tamarine Joadri, 73 Silver St, Middletown): EMERGENCY lead 10/24; Breesy logged "No response from any on-call members" repeatedly and no person replied in the Teams thread.
- 26-1970-WTR (Winters, ALB): one job across three records (iPad loss "Winters,Mary and John", Xactimate 071WW16, DASH job). DASH status "Completed without Paperwork".
- MICA "Fleischman" (2240 Essex St, loss 10/22) may be a different loss from DASH 26-1652-WTR (2204 Essex St, received 9/15).
- 7 likely test losses in MICA created 10/21, 2:51–2:56 PM.
- DASH employee list: "Test Employee" is active as a Project Manager; Raymond Axol-Acosta is a PM in DASH but a Restoration Technician on the phone list.
