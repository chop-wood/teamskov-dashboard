# Team Skov Morning Dashboard: instructions for Claude

Read `docs/STATUS.md` first (where things stand and what's next), then `docs/PROJECT_SPEC.md` (all decisions).

## Rules Dan has set
- **DASH is the source of truth** for anything about a job. Don't use Breesy's data for the dashboard. Teams lead posts are read for follow-up only; confirm job facts in DASH.
- **Read-only by default.** The only approved automatic write is the DASH note `From Teams (MM/DD/YYYY | h:mm AM/PM): {reply text}`. Check the job's notes first and never duplicate. Log every write in `actions_log`.
- Anything else that changes DASH, MICA, Teams, email, GitHub or Supabase settings: ask Dan first, every time. Don't push to GitHub without his OK.
- Never type passwords into sites. Dan signs in himself; when a session expires, show a sign-in button linking to that site.
- Don't store or display personal cell numbers from the phone list.
- Writes don't go on the dashboard, but be able to look any of them up from `actions_log` when Dan asks.

## Conventions
- REC = Construction; every other job suffix = Mitigation.
- Mitigation scope: DASH Date Received on/after 2026-05-01. Construction: all jobs.
- PM = the DASH "Supervisor" participant.
- Job links: `https://servpro.ngsapps.net/Enterprise/Module/Job/jJobSlideBoard.aspx?JobID={id}&JobNumber={number}`
- Secrets live in `.env` (never committed). `.env.example` is the blank template.
- Collectors: Node.js + Playwright. Dashboard: PWA on static hosting + Supabase Auth.
