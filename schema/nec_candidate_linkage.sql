-- Optional internal linkage schema for attaching NEC candidate identifiers to
-- krpoltext campaign_booklet rows without mutating the source corpus.
--
-- Assumptions:
-- - PostgreSQL is used only if an internal operational store is needed.
-- - krpoltext source rows are immutable once loaded into krpoltext_raw.
-- - NEC candidate rows are loaded from a fixed snapshot into nec_candidate_snapshot.
-- - The public package/API contract is the enriched CSV/Parquet artifact, not this SQL schema.
-- - krpoltext_enriched starts here as a reference view that can be exported.

create schema if not exists linkage;

create or replace function linkage.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create table if not exists linkage.linkage_snapshot (
  snapshot_id text primary key,
  snapshot_kind text not null
    check (snapshot_kind in ('krpoltext_source', 'nec_source')),
  source_name text not null,
  source_version text,
  source_uri text,
  snapshot_date date,
  checksum_sha256 text,
  note text,
  created_at timestamptz not null default now()
);

comment on table linkage.linkage_snapshot is
  'Registry of immutable source snapshots used by the linkage pipeline.';

create table if not exists linkage.matcher_run (
  matcher_run_id bigint generated always as identity primary key,
  matcher_version text not null,
  source_snapshot_id text not null
    references linkage.linkage_snapshot(snapshot_id),
  nec_snapshot_id text not null
    references linkage.linkage_snapshot(snapshot_id),
  run_status text not null default 'running'
    check (run_status in ('running', 'succeeded', 'failed')),
  config_json jsonb not null default '{}'::jsonb,
  note text,
  run_started_at timestamptz not null default now(),
  run_finished_at timestamptz
);

comment on table linkage.matcher_run is
  'One batch execution of the matcher against a fixed krpoltext and NEC snapshot pair.';

create table if not exists linkage.krpoltext_raw (
  krpoltext_code text primary key,
  candidate_name_raw text not null,
  election_date_raw date,
  election_year integer,
  office_id integer,
  office_name_raw text,
  region_raw text,
  district_raw text,
  party_name_raw text,
  giho_raw text,
  birthday_raw text,
  age_raw integer,
  job_raw text,
  edu_raw text,
  career1_raw text,
  career2_raw text,
  source_snapshot_id text not null
    references linkage.linkage_snapshot(snapshot_id),
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (election_year is null or election_year between 1900 and 2100)
);

comment on table linkage.krpoltext_raw is
  'Immutable staging copy of campaign_booklet rows keyed by krpoltext code.';

create index if not exists idx_krpoltext_raw_scope
  on linkage.krpoltext_raw (election_year, office_id, region_raw);

create index if not exists idx_krpoltext_raw_name
  on linkage.krpoltext_raw (candidate_name_raw);

drop trigger if exists trg_krpoltext_raw_set_updated_at on linkage.krpoltext_raw;

create trigger trg_krpoltext_raw_set_updated_at
before update on linkage.krpoltext_raw
for each row
execute function linkage.set_updated_at();

create table if not exists linkage.nec_candidate_snapshot (
  nec_snapshot_id text not null
    references linkage.linkage_snapshot(snapshot_id),
  sg_id text not null,
  sg_typecode text not null,
  huboid text not null,
  election_year integer,
  election_date date,
  office_id integer,
  office_name text,
  sd_name text,
  sgg_name text,
  wiw_name text,
  district_label text,
  district_uid text,
  candidate_name text not null,
  party_name text,
  giho text,
  birthday date,
  job_name text,
  edu_name text,
  career1 text,
  career2 text,
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (nec_snapshot_id, sg_id, sg_typecode, huboid)
);

comment on table linkage.nec_candidate_snapshot is
  'Canonical NEC candidate snapshot keyed by (nec_snapshot_id, sg_id, sg_typecode, huboid).';

create index if not exists idx_nec_candidate_scope
  on linkage.nec_candidate_snapshot (nec_snapshot_id, sg_id, sg_typecode, district_label);

create index if not exists idx_nec_candidate_name
  on linkage.nec_candidate_snapshot (nec_snapshot_id, sg_id, sg_typecode, candidate_name);

create index if not exists idx_nec_candidate_birthday
  on linkage.nec_candidate_snapshot (nec_snapshot_id, birthday);

create table if not exists linkage.candidacy_master (
  candidate_master_id text primary key,
  canonical_source text not null,
  sg_id text,
  sg_typecode text,
  huboid text,
  election_year integer,
  office_id integer,
  office_name text,
  district_uid text,
  district_label text,
  candidate_name_canonical text,
  party_name_canonical text,
  giho text,
  birthday date,
  identity_status text not null default 'provisional'
    check (identity_status in ('provisional', 'verified', 'merged', 'retired')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table linkage.candidacy_master is
  'Optional cross-source candidacy identifier layer. Safe to leave empty in Phase 1.';

create unique index if not exists uq_candidacy_master_nec
  on linkage.candidacy_master (sg_id, sg_typecode, huboid)
  where huboid is not null;

drop trigger if exists trg_candidacy_master_set_updated_at on linkage.candidacy_master;

create trigger trg_candidacy_master_set_updated_at
before update on linkage.candidacy_master
for each row
execute function linkage.set_updated_at();

create table if not exists linkage.krpoltext_nec_link (
  krpoltext_code text primary key
    references linkage.krpoltext_raw(krpoltext_code)
    on delete cascade,
  link_status text not null
    check (link_status in ('resolved', 'ambiguous', 'not_found', 'rejected')),
  scope_sg_id text,
  scope_sg_typecode text,
  scope_district_label text,
  sg_id text,
  sg_typecode text,
  huboid text,
  candidate_master_id text
    references linkage.candidacy_master(candidate_master_id),
  resolved_candidate_name text,
  resolved_district_label text,
  resolved_party_name text,
  resolved_giho text,
  resolved_birthday date,
  match_method text,
  match_confidence numeric(5, 4)
    check (match_confidence is null or (match_confidence >= 0 and match_confidence <= 1)),
  strong_signal_count integer not null default 0
    check (strong_signal_count >= 0),
  review_status text not null
    check (review_status in ('auto_accepted', 'needs_review', 'human_accepted', 'human_rejected')),
  reviewer text,
  reviewed_at timestamptz,
  decision_note text,
  matcher_run_id bigint
    references linkage.matcher_run(matcher_run_id),
  matcher_version text not null,
  nec_snapshot_id text not null,
  source_snapshot_id text not null
    references linkage.linkage_snapshot(snapshot_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (nec_snapshot_id, sg_id, sg_typecode, huboid)
    references linkage.nec_candidate_snapshot(nec_snapshot_id, sg_id, sg_typecode, huboid),
  foreign key (nec_snapshot_id)
    references linkage.linkage_snapshot(snapshot_id),
  check (
    (link_status = 'resolved' and sg_id is not null and sg_typecode is not null and huboid is not null)
    or
    (link_status in ('ambiguous', 'not_found', 'rejected') and huboid is null)
  ),
  check (
    review_status not in ('human_accepted', 'human_rejected')
    or (reviewer is not null and reviewed_at is not null and decision_note is not null)
  ),
  check (
    review_status <> 'auto_accepted' or link_status = 'resolved'
  ),
  check (
    review_status <> 'needs_review' or link_status in ('ambiguous', 'not_found')
  )
);

comment on table linkage.krpoltext_nec_link is
  'Current linkage decision for each krpoltext row. scope_* stores election scope recovery before final resolution.';

create unique index if not exists uq_krpoltext_nec_link_resolved_target
  on linkage.krpoltext_nec_link (source_snapshot_id, sg_id, sg_typecode, huboid)
  where link_status = 'resolved';

create index if not exists idx_krpoltext_nec_link_status
  on linkage.krpoltext_nec_link (link_status, review_status);

create index if not exists idx_krpoltext_nec_link_scope
  on linkage.krpoltext_nec_link (scope_sg_id, scope_sg_typecode, scope_district_label);

drop trigger if exists trg_krpoltext_nec_link_set_updated_at on linkage.krpoltext_nec_link;

create trigger trg_krpoltext_nec_link_set_updated_at
before update on linkage.krpoltext_nec_link
for each row
execute function linkage.set_updated_at();

create table if not exists linkage.krpoltext_nec_link_candidate (
  krpoltext_code text not null
    references linkage.krpoltext_nec_link(krpoltext_code)
    on delete cascade,
  candidate_rank integer not null
    check (candidate_rank >= 1),
  matcher_run_id bigint
    references linkage.matcher_run(matcher_run_id),
  nec_snapshot_id text not null
    references linkage.linkage_snapshot(snapshot_id),
  sg_id text not null,
  sg_typecode text not null,
  huboid text not null,
  candidate_name text,
  district_label text,
  party_name text,
  giho text,
  birthday date,
  score_total numeric(10, 4),
  score_name numeric(10, 4),
  score_office numeric(10, 4),
  score_district numeric(10, 4),
  score_party numeric(10, 4),
  score_giho numeric(10, 4),
  score_birthday numeric(10, 4),
  score_education numeric(10, 4),
  score_career numeric(10, 4),
  is_top_candidate boolean not null default false,
  warning_summary text,
  score_detail_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (krpoltext_code, candidate_rank),
  unique (krpoltext_code, nec_snapshot_id, sg_id, sg_typecode, huboid),
  foreign key (nec_snapshot_id, sg_id, sg_typecode, huboid)
    references linkage.nec_candidate_snapshot(nec_snapshot_id, sg_id, sg_typecode, huboid)
);

comment on table linkage.krpoltext_nec_link_candidate is
  'Ranked NEC candidate alternatives retained for ambiguous or reviewable linkage cases.';

create index if not exists idx_krpoltext_nec_link_candidate_score
  on linkage.krpoltext_nec_link_candidate (krpoltext_code, score_total desc, candidate_rank);

create or replace view linkage.krpoltext_enriched_v as
select
  r.krpoltext_code as code,
  r.candidate_name_raw as name,
  r.election_date_raw as date,
  r.election_year,
  r.office_id,
  r.office_name_raw as office,
  r.region_raw as region,
  r.district_raw as district,
  r.party_name_raw as party,
  r.giho_raw as giho,
  r.birthday_raw as birthday,
  r.age_raw as age,
  r.job_raw as job,
  r.edu_raw as edu,
  r.career1_raw as career1,
  r.career2_raw as career2,
  l.link_status,
  l.review_status,
  l.scope_sg_id,
  l.scope_sg_typecode,
  l.scope_district_label,
  l.sg_id,
  l.sg_typecode,
  l.huboid,
  l.candidate_master_id,
  l.resolved_candidate_name,
  l.resolved_district_label,
  l.resolved_party_name,
  l.resolved_giho,
  l.resolved_birthday,
  l.match_method,
  l.match_confidence,
  l.strong_signal_count,
  l.matcher_version,
  l.nec_snapshot_id,
  l.source_snapshot_id,
  l.reviewer,
  l.reviewed_at,
  l.decision_note
from linkage.krpoltext_raw r
left join linkage.krpoltext_nec_link l
  on l.krpoltext_code = r.krpoltext_code;

comment on view linkage.krpoltext_enriched_v is
  'Analysis-facing projection that keeps raw krpoltext fields intact and appends audited linkage results.';
