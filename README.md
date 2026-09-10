# Airbnb Revenue Integrity & Cancellation Analytics <img align="left" width="68" height="80" src="https://github.com/user-attachments/assets/dd0be3c7-0781-4502-9198-8e2527d50a48"/>
<br clear="left"/>

## Overview
This project models Airbnb-style booking data using **dbt**, **Snowflake**, and **Tableau**, transforming raw transactional data into a governed, tested warehouse — and surfacing actionable insight on revenue loss, recovery potential, and market risk.
It demonstrates a full analytics engineering workflow: medallion architecture, layered testing, SCD1/SCD2 modeling, and a dashboard powered directly by dbt marts.

**Data pipeline:** `Airbnb (raw data)` → `Snowflake (S3 stage)` → `dbt (bronze → staging → snapshots → silver → gold)` → `Tableau`

## Business Objective
Quantify and reduce revenue loss from booking cancellations, identify high-risk markets, and simulate recovery scenarios.
The dashboard, *Booking Integrity: Revenue Loss & Recovery Strategy*, highlights:

- **$5.8M** revenue lost (24% of the $21.7M potential revenue) — of which **$0.5M (9%)** was recovered through cancellation fees
- A **27%** overall cancellation rate, driving **$5.30M** of that loss
- **29%** of total revenue loss concentrated in the top 13 markets
- Bookings made 90+ days out cancel at **2.6x** the rate of 0–6 day bookings
- A modeled 10% reduction in cancellations recovers an estimated **$580K**

## Tech Stack

| Layer | Tools | Purpose |
|-------|--------|----------|
| Data Warehouse | Snowflake | Stores raw Airbnb data (bronze layer), staged from S3 via storage integration |
| Transformation | dbt-core, dbt-snowflake, dbt_utils | Cleans, tests, and models data across staging → snapshots → silver → gold |
| Visualization | Tableau (Public) | Interactive dashboard for revenue integrity and recovery strategy |
| Version Control | GitHub | Project collaboration and reproducibility |

## Data Architecture

```
Bronze  (raw, untouched — physical-contract tests only)
   ↓
Staging (standardized: casing, trimming, type casts, enum validation)
   ↓
Snapshots (SCD2 — tracks every version of a booking over time)
   ↓
Silver  (business logic enrichments, still versioned)
   ↓
Gold — Core (star schema: fact_bookings + dim_hosts, dim_listings, dim_location, dim_date)
   ↓
Gold — Marts (pre-aggregated, dashboard-ready tables)
```

- **Bronze:** Raw source tables (`BRONZE_BOOKINGS`, `BRONZE_HOSTS`, `BRONZE_LISTINGS`) in `AIRBNB.DEV_BRONZE`. Untouched — tested only for physical contract (PKs, FKs, not-null, uniqueness). Bronze is a gatekeeper, not a janitor: it flags bad data rather than silently fixing it.
- **Staging:** `stg_airbnb__bookings`, `stg_airbnb__hosts`, `stg_airbnb__listings` — standardizes types/casing and is where enum validation (`accepted_values` on `booking_status`) correctly belongs, since raw casing inconsistencies would break that test at bronze.
- **Snapshots:** `bookings_snapshot` uses dbt's timestamp strategy on `source_updated_at` to implement SCD2 — booking history is fully preserved (`dbt_valid_from`/`dbt_valid_to`), since cohort and trend analysis needs every version, not just the latest.
- **Silver:** `silver_bookings` (incremental, `merge` strategy, versioned) enriches each booking version with `lead_time_days`, `stay_end_date`, and `booking_revenue`. `silver_hosts` / `silver_listings` use SCD1 instead — only current state matters for a host or listing dimension, so old values are overwritten rather than versioned.
- **Gold Core:** `fact_bookings` (grain: one row per booking version) joins to `dim_hosts`, `dim_listings`, `dim_location`, `dim_date`, with surrogate keys via `dbt_utils.generate_surrogate_key`.
- **Gold Marts:** `mart_cancellation_analysis` (dashboard source), `mart_host_performance`, `mart_listing_performance` — pre-aggregated so Tableau never computes aggregations live.

## Macro Library

| Macro | Parameters | Logic |
|---|---|---|
| `calc_booking_revenue` | `booking_amount, cleaning_fee, service_fee` | `COALESCE` sum of all three — potential revenue if the booking isn't cancelled |
| `calc_actual_revenue` | `booking_status, booking_total, cancellation_fee` | If cancelled → `cancellation_fee` (what's actually kept). Else → `booking_total` |
| `calc_gross_revenue_loss` | `booking_status, booking_revenue` | If cancelled → full `booking_revenue` lost. Else → `0`. The headline loss number, no fee offset |
| `calc_net_revenue_loss` | `booking_status, booking_revenue, cancellation_fee` | If cancelled → `booking_revenue - cancellation_fee`. Else → `0`. Loss after fee recovery |
| `safe_divide` | `numerator, denominator, decimals=2, default_value='NULL'` | Guards divide-by-zero/NULL for rate calculations |

Gross and net loss are deliberately separate macros — one answers "how much did we lose, full stop," the other "how much after fees recovered something." Keeping them apart avoids conflating the two in any single model.

## Testing Strategy: a non-redundant pyramid

Each layer tests only what's new to it — nothing is re-tested where it's already guaranteed upstream:

| Layer | Tests | Why here, not elsewhere |
|---|---|---|
| Bronze | PKs, FKs, not-null, uniqueness | Physical contract only — no business logic yet |
| Staging | `accepted_values`, `accepted_range`, cross-column date/fee logic | First point where data is standardized enough for enum/range checks to be meaningful |
| Snapshots | SCD2 mechanics (one current record per key, valid date ranges) | Confirms the versioning itself is correct |
| Silver | Business-logic enrichments | Confirms derived fields (lead time, revenue calcs) are correct |

Two custom generic tests support this: `not_in_future(model, column_name)` and `not_negative(model, column_name)`.

Guiding principle: a data engineer's job is to detect, document, and alert — not silently patch bad data.

## Dashboard Highlights
**Booking Integrity: Revenue Loss & Recovery Strategy** — built on `mart_cancellation_analysis`, published to Tableau Public.

- Revenue Flow: Potential → Actual → Lost → Recovered
- Top Revenue Loss by Market: Singapore, US, Ireland, Japan, Australia
- Cancellation Rate by Property Type: condos, houses, and apartments show the highest volatility (~28%)
- Lead-Time Risk: 90+ day bookings cancel at 2.6x the rate of 0–6 day bookings
- Recovery Scenarios: 5% / 10% / 15% cancellation-reduction modeling (+$290K / +$580K / +$870K)

## Repository Structure
```
airbnb_dbt/
│
├── macros/
│   ├── revenue/
│   │   ├── calc_actual_revenue.sql
│   │   ├── calc_booking_revenue.sql
│   │   ├── calc_gross_revenue_loss.sql
│   │   └── calc_net_revenue_loss.sql
│   └── utils/
│       └── safe_divide.sql
│
├── models/
│   ├── staging/airbnb/
│   │   ├── sources.yml
│   │   ├── stg_airbnb__bookings.sql
│   │   ├── stg_airbnb__hosts.sql
│   │   └── stg_airbnb__listings.sql
│   ├── silver/
│   │   ├── silver_bookings.sql
│   │   ├── silver_hosts.sql
│   │   └── silver_listings.sql
│   └── gold/
│       ├── core/
│       │   ├── dim_date.sql
│       │   ├── dim_hosts.sql
│       │   ├── dim_listings.sql
│       │   ├── dim_location.sql
│       │   ├── fact_bookings.sql
│       │   └── core_schema.yml
│       └── marts/
│           ├── mart_cancellation_analysis.sql
│           ├── mart_host_performance.sql
│           ├── mart_listing_performance.sql
│           └── mart_schema.yml
│
├── seeds/
│   └── country_cities.csv
│
├── snapshots/
│   ├── bookings_snapshot.sql
│   └── bookings_snapshots.yml
│
├── tests/generic/
│   ├── not_in_future.sql
│   └── not_negative.sql
│
├── pyproject.toml
└── dbt_project.yml
```

## Analytical Insights
- Long lead-time bookings are the main driver of cancellations.
- 29% of total losses are concentrated in 13 markets — ideal for targeted policy changes.
- Cancellation fees recover only 9% of lost revenue, suggesting room for dynamic fee pricing.
- Condos and houses show the highest volatility; stricter refund policies are recommended for those property types.

## Known Issues / Next Steps
- Finalize `gold/core/core_schema.yml` and `gold/marts/mart_schema.yml` test/doc coverage.
- Export gold tables to DuckDB/Parquet for a lightweight local demo.
- Build a minimal Streamlit app for interactive validation.
- Add the Tableau Public dashboard link once finalized.

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/<your-username>/airbnb_dbt.git
cd airbnb_dbt
```

### 2. Install Dependencies
This project uses Python 3.12+ and manages dependencies via `pyproject.toml`.

With [uv](https://docs.astral.sh/uv/) (recommended):
```bash
uv sync
```

Or with plain pip:
```bash
python -m venv .venv
source .venv/bin/activate   # macOS/Linux
.\.venv\Scripts\activate    # Windows

pip install "dbt-core>=1.11.5" "dbt-snowflake>=1.11.2"
```

### 3. Configure Your Snowflake Profile
Edit `~/.dbt/profiles.yml`:
```yaml
airbnb_dbt:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your_account>
      user: <your_user>
      password: <your_password>
      role: <your_role>
      database: AIRBNB
      warehouse: <your_warehouse>
      schema: DEV_BRONZE
      threads: 4
```

### 4. Install dbt Packages
```bash
dbt deps
```

### 5. Build the Project
```bash
dbt seed
dbt run
dbt test
```

---

**Author:** Michéle Adriaans
