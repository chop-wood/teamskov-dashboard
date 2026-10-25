-- Team Skov Morning Dashboard: initial schema
-- Collectors write with the secret (service role) key, which bypasses RLS.
-- The dashboard reads as a signed-in user, so every table allows SELECT to authenticated users only.

-- Reference data ------------------------------------------------------------

create table offices (
  code          text primary key,          -- MNB, NEO, CMC, ALB, TAR, BAL
  name          text not null,
  teams_team    text,                      -- e.g. MIDDLETOWN, SYRACUSE
  address_match text                       -- street used to map DASH employee addresses
);

insert into offices (code, name, teams_team, address_match) values
  ('MNB', 'Middletown/New Britain', 'MIDDLETOWN', '14 Industrial Park'),
  ('NEO', 'North & East Onondaga (Syracuse)', 'SYRACUSE', '112 Pickard'),
  ('CMC', 'Central Monroe County (Rochester)', 'ROCHESTER', '460 Buffalo'),
  ('ALB', 'Central Albany', 'ALBANY', '4 Airport Park'),
  ('TAR', 'Tarrytown/Elmsford', 'TARRYTOWN', '11 Clearbrook'),
  ('BAL', 'Baltimore North', 'BALTIMORE', '1123 Wilso');

-- Which DASH document slots count as "required", per division.
create table required_documents (
  division   text not null check (division in ('mitigation', 'construction')),
  slot_name  text not null,                -- exact DASH slot name
  label      text not null,                -- what Dan calls it
  condition  text,                         -- e.g. 'skip_if_no_mortgage'
  active     boolean not null default true,
  primary key (division, slot_name)
);

insert into required_documents (division, slot_name, label, condition, active) values
  ('mitigation',   'Work Authorization',           'Work Authorization',     null, true),
  ('mitigation',   'Certificate of Satisfaction',  'COS',                    null, true),
  ('construction', 'Letter of Intent',             'Letter of Intent',       null, true),
  ('construction', 'Work Authorization',           'Work Authorization',     null, true),
  ('construction', 'Mortgage Authorization',       'Mortgage Authorization', 'skip_if_no_mortgage', true),
  ('construction', 'Certificate of Satisfaction',  'Signed COS',             null, true),
  ('construction', 'Material Selection',           'Material Selection',     null, true),
  ('construction', 'Subcontractor Exhibits A & C', 'Subcontractor Exhibits A & C', null, true);

-- Division rule (Dan, 10/25): REC is Construction; every other suffix is Mitigation.
create or replace function division_for(job_number text) returns text
language sql immutable as $$
  select case when split_part(job_number, '-', 3) = 'REC' then 'construction' else 'mitigation' end
$$;

-- Internal jobs that should never raise flags (office SHOP jobs, PROGRAM JOB, ...).
create table excluded_jobs (
  job_number text primary key,
  reason     text not null
);

insert into excluded_jobs (job_number, reason) values
  ('26-0543-CST', 'ALB SHOP'),
  ('26-0544-CST', 'CMC SHOP'),
  ('26-0545-CST', 'NEO SHOP'),
  ('26-0546-CST', 'TAR SHOP'),
  ('26-0547-CST', 'MNB SHOP');

-- People ------------------------------------------------------------------

create table employees (
  id                 bigint generated always as identity primary key,
  full_name          text not null,         -- "First Last"
  dash_name          text unique,           -- "Last, First" as DASH shows it
  dash_user_id       text,
  job_title          text,                  -- from DASH (Project Manager, Field Technician, ...)
  phone_list_title   text,                  -- from the phone list (Project Manager II, Restoration Supervisor, ...)
  office_code        text references offices(code),
  email              text,
  work_phone         text,
  extension          text,
  in_dash            boolean not null default false,
  in_phone_list      boolean not null default false,
  is_system_account  boolean not null default false,
  dash_seen_at       timestamptz,
  phone_list_seen_at timestamptz,
  updated_at         timestamptz not null default now()
);

-- Runs --------------------------------------------------------------------

create table runs (
  id           bigint generated always as identity primary key,
  source       text not null,               -- dash | mica | teams | phone_list | analysis
  machine      text,                        -- which computer ran it
  started_at   timestamptz not null default now(),
  finished_at  timestamptz,
  status       text not null default 'running' check (status in ('running', 'ok', 'partial', 'failed')),
  counts       jsonb not null default '{}',
  notes        text,
  sign_in_url  text                         -- set when status = 'failed' because a login expired
);

-- DASH --------------------------------------------------------------------

create table jobs (
  job_number          text primary key,      -- 26-1982-WTR
  dash_job_id         bigint not null,       -- for the clickable link
  suffix              text not null,         -- WTR, REC, ...
  division            text check (division in ('mitigation', 'construction')),
  office_code         text references offices(code),
  customer            text,
  job_name            text,
  address             text,
  status              text,                  -- DASH status (Work in Progress, ...)
  claim_number        text,
  claim_number_norm   text,                  -- digits/letters only, trailing -1 dropped
  pm_name             text,                  -- DASH "Supervisor" participant
  estimator_name      text,
  coordinator_name    text,
  date_received       timestamptz,           -- Mitigation 5/1 cutoff (proposed)
  date_of_loss        date,
  date_inspected      timestamptz,
  date_started        timestamptz,
  date_closed         timestamptz,
  -- Revenue (from the DASH custom report)
  total_estimates     numeric(12,2),
  supplement_estimate numeric(12,2),
  work_order_budget   numeric(12,2),
  total_job_cost      numeric(12,2),
  total_invoiced      numeric(12,2),
  total_collected     numeric(12,2),
  working_gp_pct      numeric(6,2),
  actual_gp_pct       numeric(6,2),
  mica_assignment_id  text,                  -- from the Job Information "Mitigate" row
  mica_link_status    text,
  in_scope            boolean not null default true,  -- Mit: start >= 2026-05-01; Recon: always
  last_seen_run       bigint references runs(id),
  updated_at          timestamptz not null default now()
);
create index jobs_claim_norm_idx on jobs (claim_number_norm);
create index jobs_division_idx on jobs (division, in_scope);

create table job_documents (
  job_number    text not null references jobs(job_number) on delete cascade,
  slot_name     text not null,
  uploaded      boolean not null,
  uploaded_at   timestamptz,
  last_seen_run bigint references runs(id),
  primary key (job_number, slot_name)
);

create table job_notes (
  dash_note_id  text primary key,
  job_number    text not null references jobs(job_number) on delete cascade,
  created_at    timestamptz,
  author        text,
  body          text
);

-- MICA --------------------------------------------------------------------

create table mica_losses (
  loss_number        text primary key,       -- 26-1982-WTR, Fleischman, 071WW16, ...
  franchise          text,
  owner_name         text,
  claim_number       text,
  claim_number_norm  text,
  insurance_co       text,
  created_at         timestamptz,
  status             text,
  status_at          timestamptz,
  created_by         text,                   -- MICA user who created/uploaded it
  source             text,                   -- MICA iPad, Xactimate, iPad
  loss_address       text,
  date_of_loss       date,
  start_date         timestamptz,
  matched_job_number text references jobs(job_number),
  match_method       text check (match_method in ('job_number', 'claim_number', 'name_address', 'manual')),
  match_confirmed    boolean not null default false,  -- name/address matches stay "possible" until Dan confirms
  is_test            boolean not null default false,
  last_seen_run      bigint references runs(id),
  updated_at         timestamptz not null default now()
);

create table mica_forms (
  loss_number   text not null references mica_losses(loss_number) on delete cascade,
  form_name     text not null,                -- e.g. "28531 - Certificate of Satisfaction - Job Completion"
  state         text not null check (state in ('signed', 'partial', 'unsigned')),
  signed_at     timestamptz,
  last_seen_run bigint references runs(id),
  primary key (loss_number, form_name)
);

-- Teams -------------------------------------------------------------------

create table teams_leads (
  message_id         text primary key,
  team_name          text not null,           -- Leads Dispatch | Construction Leads
  channel_name       text,                    -- office channel (Middletown, Syracuse, ...)
  office_code        text references offices(code),
  division           text check (division in ('mitigation', 'construction')),
  post_type          text,                    -- fnol | follow_up | general_inquiry | missed_call | other
  urgency            text,                    -- EMERGENCY | Not Urgent
  caller_name        text,
  service_address    text,
  loss_type          text,
  posted_at          timestamptz not null,
  posted_by          text,
  body               text,
  on_call_unanswered boolean not null default false,  -- "No response from any on-call members"
  human_reply_at     timestamptz,             -- first reply from a person (not Breesy)
  human_reply_by     text,
  human_reply_text   text,
  dash_job_created_at timestamptz,            -- Breesy "Job created in Dash" reply
  job_number         text references jobs(job_number),
  dash_note_exists   boolean,
  dash_note_added_at timestamptz,
  last_seen_run      bigint references runs(id)
);

-- Flags & exceptions ------------------------------------------------------

-- One row per open problem; resolved_at is set when it no longer shows up.
create table flags (
  id            bigint generated always as identity primary key,
  metric        text not null,               -- missing_doc | mica_unlinked | mica_no_dash_job | lead_no_reply | ...
  entity_key    text not null,               -- job_number, loss_number or message_id (+ ':' + slot for docs)
  division      text,
  office_code   text references offices(code),
  job_number    text,
  follow_up_with text,                       -- PM, or MICA creator
  detail        jsonb not null default '{}',
  first_seen    timestamptz not null default now(),
  last_seen     timestamptz not null default now(),
  resolved_at   timestamptz,
  unique (metric, entity_key)
);

-- Things Dan has marked as "known, stop showing me".
create table acknowledged_exceptions (
  id              bigint generated always as identity primary key,
  metric          text not null,
  entity_key      text not null,
  reason          text not null,             -- "never signed", "pre-system job", ...
  acknowledged_by text not null,
  acknowledged_at timestamptz not null default now(),
  expires_at      timestamptz,
  unique (metric, entity_key)
);

-- Every change the system makes outside itself (DASH notes, DASH reports, ...).
-- Written before and after each action so nothing happens without a record.
create table actions_log (
  id           bigint generated always as identity primary key,
  run_id       bigint references runs(id),
  action       text not null,              -- add_dash_note | create_dash_report | ...
  target       text not null,              -- job_number or other target
  payload      text,                       -- exact text written
  verified_absent boolean,                 -- checked beforehand that it wasn't already there
  status       text not null default 'planned' check (status in ('planned', 'done', 'skipped', 'failed')),
  detail       text,
  created_at   timestamptz not null default now()
);

-- Weekly owner update -----------------------------------------------------

create table weekly_updates (
  week_start  date primary key,
  draft_md    text,
  status      text not null default 'draft' check (status in ('draft', 'approved', 'sent')),
  approved_at timestamptz,
  updated_at  timestamptz not null default now()
);

-- Open flags minus acknowledged ones: what the dashboard shows by default.
create view open_flags with (security_invoker = true) as
select f.*
from flags f
left join acknowledged_exceptions a
  on a.metric = f.metric and a.entity_key = f.entity_key
 and (a.expires_at is null or a.expires_at > now())
where f.resolved_at is null and a.id is null;

-- Row-level security ------------------------------------------------------

do $$
declare t text;
begin
  foreach t in array array['offices','required_documents','excluded_jobs','actions_log','employees','runs','jobs','job_documents',
                           'job_notes','mica_losses','mica_forms','teams_leads','flags',
                           'acknowledged_exceptions','weekly_updates']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "signed-in users can read" on %I for select to authenticated using (true)', t);
  end loop;
end $$;

-- Dan acknowledges flags from the dashboard.
create policy "signed-in users can acknowledge" on acknowledged_exceptions
  for insert to authenticated with check (true);
create policy "signed-in users can un-acknowledge" on acknowledged_exceptions
  for delete to authenticated using (true);
