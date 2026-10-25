# Team Skov Morning Dashboard

A daily snapshot of where SERVPRO Team Skov stands, built from DASH, MICA, Microsoft Teams and the Master Company Phone List. It has three tabs: Summary, Mitigation and Construction.

- **What it does and why:** [docs/PROJECT_SPEC.md](docs/PROJECT_SPEC.md)
- **Database:** Supabase (`supabase/migrations/`)
- **Collectors:** `collectors/` (one per source, run every morning)
- **Dashboard:** `dashboard/`

## Setting up on a new computer

1. Install [Git](https://git-scm.com) and [Node.js](https://nodejs.org) (LTS).
2. Clone the repo. Keep it **outside OneDrive** if you can, because `node_modules` doesn't sync well:
   ```bash
   git clone https://github.com/chop-wood/teamskov-dashboard
   ```
3. Copy `.env.example` to `.env` and fill in the secret values.
4. Before working, pull the latest:
   ```bash
   git pull
   ```

Only one computer should run the daily collection. The `runs` table records which machine ran each job.
