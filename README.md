# Airbnb Revenue Integrity & Cancellation Analytics <img align="left" width="68" height="80" src="https://github.com/user-attachments/assets/dd0be3c7-0781-4502-9198-8e2527d50a48"/>


## Overview
This project models Airbnb‑style booking data using **dbt**, **Snowflake**, and **Tableau**, transforming raw transactional data into actionable insights on **revenue loss, recovery potential, and market risk**.  
It demonstrates full‑stack analytics engineering — from data modeling and testing to visualization and business storytelling.


## 🎯 Business Objective
To quantify and reduce **revenue loss from booking cancellations**, identify **high‑risk markets**, and simulate **recovery scenarios**.  
The dashboard, *Booking Integrity: Revenue Loss & Recovery Strategy*, highlights:

- $5.8M lost from 27% cancellations  
- 29% of losses concentrated in top 13 markets  
- Long lead‑time bookings drive highest cancellation risk  
- +$580K recoverable with a 10% reduction in cancellations  


## 🧩 Tech Stack

| Layer | Tools | Purpose |
|-------|--------|----------|
| **Data Warehouse** | Snowflake | Stores raw Airbnb data (bronze layer) |
| **Transformation** | dbt‑core, dbt‑snowflake | Cleans, tests, and models data across staging → silver → gold layers |
| **Visualization** | Tableau | Interactive dashboard for revenue integrity and recovery strategy |
| **Version Control** | GitHub | Project collaboration and reproducibility |


## 🏗️ Data Architecture

### Bronze → Silver → Gold
- **Bronze:** Raw source tables (`BRONZE_BOOKINGS`, `BRONZE_HOSTS`, `BRONZE_LISTINGS`)  
- **Staging:** Standardizes data types, trims strings, and enforces business sanity tests  
- **Silver:** Implements SCD1/SCD2 logic for hosts, listings, and bookings  
- **Gold:** Aggregates metrics for cancellation analysis and host performance  


## 🧮 Key dbt Models
- **stg_airbnb_bookings** → Cleans booking data, validates logical consistency  
- **silver_bookings** → SCD2 versioning, calculates booking revenue  
- **mart_cancellation_analysis** → Aggregates cancellation metrics for Tableau  
- **safe_divide macro** → Prevents division‑by‑zero errors  
- **calc_net_revenue_loss macro** → Computes net loss after cancellation fees  


## 📊 Dashboard Highlights
**Booking Integrity: Revenue Loss & Recovery Strategy**

- **Revenue Flow:** Potential → Actual → Lost → Recovered  
- **Top Revenue Loss by Market:** Singapore, US, Ireland, Japan, Australia  
- **Cancellation Rate by Property Type:** Condos & Houses show highest volatility  
- **Lead‑Time Risk:** 90+ day bookings have 2.6× higher cancellation probability  
- **Recovery Scenarios:** +$580K gain with 10% cancellation reduction  


## 🧠 Analytical Insights
- Long lead‑time bookings are the main driver of cancellations.  
- 29% of total losses are concentrated in 13 markets — ideal for targeted policy changes.  
- Cancellation fees recover only 9% of lost revenue, suggesting opportunity for dynamic pricing.  
- Condos and Houses show the highest volatility; stricter refund policies recommended.


## 📁 Repository Structure
```
airbnb_dbt/
│
├── macros/
│   ├── revenue/
│   │   ├── calc_actual_revenue.sql
│   │   ├── calc_booking_revenue.sql
│   │   ├── calc_net_revenue_loss.sql
│   └── utils/safe_divide.sql
│
├── models/
│   ├── staging/airbnb/
│   ├── silver/
│   └── gold/marts/
│
├── seeds/country_cities.csv
├── snapshots/bookings_snapshot.sql
└── dbt_project.yml

```

## 💡 Learning Outcomes
- Designed a **medallion architecture** in dbt with SCD1/SCD2 modeling.  
- Implemented **data quality tests** using `dbt_utils` and custom macros.  
- Built a **Tableau dashboard** powered by dbt marts for optimized performance.  
- Demonstrated **end‑to‑end analytics engineering workflow** from ingestion to insight.


## 🚀 How to Run
1. Clone the repository  
2. Configure your Snowflake profile in `profiles.yml`  
3. Run:
   ```bash
   dbt seed
   dbt run
   dbt test

  🙋‍♀️ Author: Created with 💜 by Michéle








