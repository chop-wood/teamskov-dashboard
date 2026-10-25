# Team Skov Morning Dashboard: Project Spec

Owner: Dan Stryker · Started: 2026-10-25 · Status: Draft (sources explored 10/25; decisions mostly made)

## Goal
A daily snapshot, refreshed every morning, of where the business stands, built from DASH, MICA, Teams and the Master Company Phone List. **DASH is the source of truth** for anything about a job. It runs on its own with Claude running and supervising the collectors. Viewer: Dan only for now (shared by screen share).

## Dashboard layout
Three tabs: **Summary (company-wide)**, **Mitigation**, **Construction**. Each tab shows:
- Counts by office, by PM, and trends over time
- "Chase today" list (the open flags most worth following up)
- **Revenue:** estimates, invoiced, collected, job cost, GP%, by office/PM/division and over time

Every job number links straight to the job in DASH:
`https://servpro.ngsapps.net/Enterprise/Module/Job/jJobSlideBoard.aspx?JobID={dash_job_id}&JobNumber={job_number}`

Delivered as an installable web app (PWA) that reads from Supabase and requires login.

## Mitigation vs. Construction (by job-number suffix)
**REC = Construction. Every other suffix = Mitigation** (WTR, CLN, MLD, FIRE, CON, ASB, BIO, CST, TMP, ...).

The 5 internal office "SHOP" jobs (26-0543 to 0547-CST) are excluded from all flags.

Open jobs on 10/25: 780 (WTR 398, MLD 108, REC 107, CLN 69, BIO 31, FIRE 28, CON 18, ASB 6, CST 6, TMP 8, plus 1 typo "WTR33").

## Scope rules
- **Mitigation:** jobs with DASH **Date Received** on/after **2026-05-01** (confirmed).
- **Construction:** all jobs, no date limit.

## Metric 1: Missing paperwork
DASH tracks required documents on every job (Documents tab). A missing slot shows `missing_document.svg` + red "None"; a present one shows `uploaded_document.svg` + "Date Uploaded".

**Mitigation:** Work Authorization, Certificate of Satisfaction.

**Construction** (DASH slot names, per Dan "whatever is in DASH"): Letter of Intent, Work Authorization, Mortgage Authorization, Material Selection, Subcontractor Exhibits A & C, Certificate of Satisfaction.

**Mortgage rule:** a Construction job is OK when either the Mortgage Authorization slot is filled **or** one of the job's DASH notes contains "no mortgage" (any capitalization/spacing). Otherwise it's flagged **Missing Mortgage form** on the dashboard and in the morning summary, and Dan follows up with the PM. (PMs will be told to add a "No Mortgage" note.)

MICA keeps its own record per loss (Work Authorization tab): **Signed**, **Partially Filled**, **Unsigned**. Combining both:
| MICA | DASH slot | Meaning |
|---|---|---|
| Signed | Missing | **Signed but not uploaded to DASH** (upload gap) |
| Unsigned / none | Missing | Never signed |
| Any | Uploaded | OK |

## Metric 2: MICA ↔ DASH linking
- Job created in DASH → MICA Loss # = DASH job number, and the DASH job shows a "Mitigate" link row with an Assignment ID.
- Matching order: (1) exact job number, (2) normalized claim number, (3) customer name + address.
- **Name matches are "possible" until confirmed.** Example: MICA "Fleischman" is 2240 Essex St (loss 10/22); DASH 26-1652-WTR is 2204 Essex St (received 9/15). It may be a separate loss, so the dashboard shows it as "possible match: confirm".
- 10/25 test (31 MICA losses, last 15 days): 9 linked by job number; 10 iPad losses named after the customer that have a DASH job; 5 Xactimate assignments, all with a DASH job; 7 likely tests (numeric IDs, techs' own names, 10/21 2:51–2:56 PM batch).
- Flags: MICA loss not linked to its DASH job; in-scope Mitigation job with no MICA link or a link error; MICA loss with no DASH job (unless marked test).

## Metric 3: Teams leads
**How leads arrive:** Breesy AI (phone system) posts every call in the **Leads Dispatch** team (Mitigation) and **Construction Leads** team, each with one channel per office (Middletown, Syracuse, Rochester, Albany, Tarrytown, Baltimore).

**Post types (title line):** `FNOL — EMERGENCY — Name`, `FNOL — Not Urgent — Name`, `Follow Ups | …`, `General Inquiries | …`, `Missed Call Notification`. **Only FNOL posts are leads.** Each FNOL has caller, phone, address, loss type, urgency, insurance status, referral.

**Thread replies:**
- Breesy dispatch log: "Attempting live transfer…", "Calling Henry Quiroz Pinos..", "Nobody answered! Triggering on-call failover", "No response from any on-call members."
- Breesy job creation: `Job created in Dash. Job number: 26-2060-WTR / Job ID: 10780904 / Supervisor / Estimator / Coordinator`. **This ties the lead to the DASH job automatically.**
- Human replies, e.g. "Eric Helwig" (who it was assigned to).

**Flags:**
- FNOL with no "Job created in Dash" reply and no human reply → **lead not followed up**
- EMERGENCY with "No response from any on-call members" and no human reply after → **emergency not answered** (e.g. 26-2089-WTR, Tamarine Joadri, 10/24)
- Lead with a DASH job but no customer-contact note/date in DASH

**DASH notes from Teams (approved by Dan 10/25):**
- Format: `From Teams (MM/DD/YYYY | h:mm AM/PM): {reply text from the Teams thread}`, with the date and time of the Teams reply.
- **Never duplicate.** Before writing, read the job's notes and skip if any note already contains that Teams text, or already starts with "From Teams" for the same date and time.
- Only human status replies are copied. Breesy's own call-log lines are not.
- Every write is recorded in `actions_log` (planned → done/skipped/failed) with the exact text.

## Metric 4: Shop capacity
DASH Calendar (`/EnterpriseApp/Calendar`) supports Job Tasks, Marketing Tasks, Calendar Events and Work Orders, filterable by Groups, Offices, Divisions, with a Timeline view. It's barely used today. Capacity model to be designed with Dan. Starting inputs available now: open jobs and WIP by office/PM, and crew counts from the phone list.

**Keep it visible:** the Summary tab has a "Shop capacity" card from day one. Until the model exists it shows open/WIP jobs per office and per PM, labeled "Capacity model not set up yet", so it isn't forgotten.

## Follow-up owner on every flag
PM = the DASH **Supervisor** participant (same as Breesy's "Supervisor" line). Also stored: Estimator, Coordinator, and the MICA creator where relevant.

## Acknowledged exceptions
Flags Dan marks as known ("never signed", "test loss", "not the same job") stop showing, until un-acknowledged or expired.

## Employee roster (weekly)
- Source: Master Company Phone List (Tim's OneDrive / ON CALL), sheet **Current**, "Last Updated" in the header.
- Layout: office sections (Leadership, Extended Leadership, Middletown, North & East Onondaga, Tarrytown/Elmsford, Central Monroe County, Central Albany, Baltimore North, Sales); columns Name, Title, Servpro Phone, Personal Cell (**not stored**), Ext., plus an unlabeled number column.
- Titles are more specific than DASH (Project Manager I/II/III, Construction Project Manager, Restoration Supervisor/Technician).
- Weekly: refresh `employees`, compare to DASH active employees, flag differences (e.g. Raymond Axol-Acosta is "Project Manager" in DASH but "Restoration Technician" on the list; two PM slots are vacant: NEO PM I, TAR PM III).

## Data access (found 10/25)
| Source | How the collector gets it |
|---|---|
| DASH open jobs | JSON API `servprosvc.ngsapps.net/svc/ent/EnterpriseJobs/api/v01/enterprisejobs/` (bearer token from a signed-in session). Returns JobId, JobNumber, JobName (office prefix), Customer, Estimator, Carrier, Claim #, Address, Status, DateReceived, DateClosed. |
| DASH PM, dates, revenue | Custom reports (Report Creator), e.g. "Construction - WIP": Job Id, Supervisor, Status, Date Received/Inspected/Started, Total Estimates, Supplement, WO Budget, Job Cost, GP%, Total Invoiced, Total Collected. Plan: one "Dashboard" custom report covering all divisions (**approved by Dan 10/25**; to be created when building the DASH collector). |
| DASH documents | Job page Documents tab (per job) |
| DASH notes | Job page Notes tab: Added By, Date, Note, Visibility |
| MICA losses | Home "Recent Uploads" (date ranges up to 15 days / month to date) |
| MICA loss detail | `LossInfoMitigation.event?lossid=…`: opens in a normal tab when loaded directly; Work Authorization tab has Signed/Partially/Unsigned |
| Teams | Microsoft Graph (channel messages + replies) |
| Phone list | Microsoft Graph (Excel file) |

## Weekly owner update
A weekly draft for Tim (the owner) of what was accomplished: dashboard trends (flags opened vs. resolved, revenue), Dan's Outlook calendar and email highlights, and project progress. Drafted **Saturday mornings** for Dan to review. **Nothing is sent without Dan's approval.** Format still to decide.

## Guardrails (what runs unattended)
- **Read-only by default.** Collectors only read DASH, MICA, Teams and the phone list.
- **The only automatic write** is the approved "From Teams" DASH note, and only after checking it isn't already there. Anything else that changes DASH, MICA, Teams or email needs Dan's explicit OK first, each time, until he approves it as a standing rule here.
- Every write is logged in `actions_log` (not shown on the dashboard; Dan asks Claude to look one up when needed).
- All code is in GitHub, so what runs can always be reviewed.

## Signing in to DASH and MICA
- Claude doesn't type passwords. Dan signs in once in a dedicated browser profile the collectors use; they reuse that session until it expires.
- When a session expires, that source pauses and the dashboard shows a **"Sign in to DASH" / "Sign in to MICA" button** linking straight to that site's login page. The next run picks up after Dan signs in.
- Alternative later: a dedicated DASH/MICA user for the dashboard, with Dan entering its password himself into `.env` on the machine that runs the job.

## Multiple computers
- GitHub (`chop-wood/teamskov-dashboard`) holds code and docs; Supabase holds data.
- Secrets live in `.env` on each machine (never committed); cloud runs use GitHub/Supabase secrets.
- Only one machine runs the daily job; the run log records which.
- Keep clones outside OneDrive where possible.

## Infrastructure
- Supabase project: `https://xnegqafkydsxayghlujt.supabase.co` (RLS on; signed-in read only)
- Dashboard: PWA, static hosting (e.g. GitHub Pages) + Supabase Auth
- Collectors: Node.js + Playwright

## Breesy (explored 10/25)
Breesy (breesy.app; backend on Supabase at auth.breesy.app) already does a lot of what this project needs:
- **Calls & leads:** every call, its type, urgency, dispatch attempts, and outcome. This is the source of the Teams posts.
- **DASH sync:** jobs with division, status, closure reason, amount paid, last activity, links to DASH, and whether a **Work Authorization is on file in DASH**.
- **Business dashboard:** lead conversion, declined reasons, "leads slipped through" (no booking, no dispatch, no WA, no follow-up), revenue, production, velocity, previous-year compare, custom reports, AI insights.
- **Other:** Call Analysis, Jobs + Service Map, Documents (e-signature), Check-Ins (technician time tracking), Team & Resources, Integrations (Teams, Dash, Truck GPS like Samsara/Motive, payroll).

**Decision (Dan, 10/25): the dashboard does NOT use Breesy data.** DASH is the source of truth; we don't want Breesy's interpretation driving decisions. Job, PM, document, note and revenue data come straight from DASH. Teams lead posts (written by Breesy) are still read for lead follow-up, but any job facts are confirmed in DASH.

## Open questions
1. Capacity model (later; placeholder on Summary).
2. Weekly update format.
