# ⚽ Football Integrity Analytics

End-to-end football analytics and integrity monitoring project built with **Python, Apache Airflow, PostgreSQL, R, Shiny and Docker**, using **StatsBomb Open Data**.

The project implements a complete data pipeline from raw football event data to an interactive analytical dashboard, with a particular focus on performance analysis and exploratory integrity indicators.

---

## 📊 Project Overview

Football Integrity Analytics is designed as a portfolio project demonstrating an end-to-end sports data workflow:

```text
StatsBomb Open Data
        │
        ▼
Python Ingestion
        │
        ▼
Apache Airflow
        │
        ▼
PostgreSQL
        │
        ▼
R Analytics
        │
        ▼
Shiny Dashboard
```

The pipeline downloads match and event-level data from StatsBomb Open Data, validates the data through automated quality checks, stores it in PostgreSQL and exposes analytical metrics through an interactive Shiny dashboard.

---

## ✨ Features

### Data Engineering

- StatsBomb Open Data ingestion
- Configurable competition and season selection
- Match and event-level data processing
- PostgreSQL persistence
- Idempotent event loading
- Apache Airflow orchestration
- Docker-based infrastructure
- Automated data-quality checks
- Coordinate anomaly detection

### Football Analytics

- Expected Goals (xG)
- Shot analysis
- Pass completion
- Progressive passes
- Final-third entries
- Carries
- Pressure events
- Player-level metrics
- Team-level metrics
- Spatial event analysis

### Interactive Dashboard

The Shiny application provides several analytical views:

- Match Overview
- Shot Map
- Passing Analysis
- Player Analysis
- Integrity Signals
- Match Explorer

Competition, season and match filters allow multiple datasets to coexist in the same PostgreSQL database.

---

## 🏆 Available Data

The current configuration supports datasets available through StatsBomb Open Data, including:

- **Serie A — 2015/2016**
- **Bundesliga — 2023/2024**

The competition and season used by the ingestion pipeline can be changed through:

```text
config/competition.yml
```

Example:

```yaml
competition_name: "Serie A"
competition_id: 12

season_name: "2015/2016"
season_id: 27
```

---

## 🏗️ Architecture

### 1. Data Source

Football event data is retrieved from the public **StatsBomb Open Data** repository.

### 2. Python Ingestion

The ingestion layer retrieves:

- competitions
- matches
- events

and transforms nested StatsBomb JSON structures into relational records.

### 3. Apache Airflow

Airflow orchestrates the ETL workflow:

```text
load_competitions
        ↓
load_matches
        ↓
load_events
        ↓
data_quality_check
```

The DAG reads the selected competition and season from the YAML configuration file.

### 4. PostgreSQL

The analytical database stores structured football data including:

```text
competitions
matches
events
```

Event-level data includes information such as:

- event type
- team
- player
- possession
- pitch coordinates
- pass destination
- shot xG
- event outcome
- original JSON payload

### 5. R Analytics

R is used to calculate football metrics and transform event data into analytical datasets.

### 6. Shiny

The final analytical layer is an interactive Shiny dashboard using `ggplot2` for visualisation.

---

## 🛡️ Data Quality

The Airflow pipeline performs automated quality checks after ingestion.

Checks include:

- expected number of matches
- matches without events
- duplicate event IDs
- pitch-coordinate validation
- total event volume

Minor source-level coordinate deviations are reported as warnings, while materially invalid coordinates cause the pipeline to fail.

This allows the original source data to remain unchanged while still identifying potential data-quality issues.

---

## 🔎 Integrity Analytics

The project includes an exploratory **Integrity Signals** layer.

These indicators are designed to identify unusual statistical patterns that may deserve additional analyst review.

They are **not evidence of match manipulation or misconduct**.

Integrity indicators should be interpreted as analytical screening tools and combined with broader contextual, sporting and investigative information.

---

## 🗂️ Project Structure

```text
football-integrity-analytics/
│
├── airflow/
│   └── dags/
│       └── statsbomb_pipeline.py
│
├── config/
│   └── competition.yml
│
├── ingestion/
│   └── statsbomb.py
│
├── R/
│   ├── db_connection.R
│   ├── match_metrics.R
│   ├── test_metrics.R
│   └── visualisations.R
│
├── shiny/
│   ├── app.R
│   ├── R/
│   │   ├── db.R
│   │   ├── data.R
│   │   ├── metrics.R
│   │   └── plots.R
│   └── www/
│       └── custom.css
│
├── sql/
│   └── init/
│       └── schema.sql
│
├── docker-compose.yml
├── .gitignore
└── README.md
```

---

## 🧰 Technology Stack

| Layer | Technology |
|---|---|
| Data Source | StatsBomb Open Data |
| Ingestion | Python |
| Orchestration | Apache Airflow |
| Database | PostgreSQL |
| Infrastructure | Docker / Docker Compose |
| Analytics | R |
| Dashboard | Shiny |
| Visualisation | ggplot2 |
| Version Control | Git / GitHub |

---

## 🚀 Running the Project

### Requirements

The project requires:

- Docker Desktop
- Git
- R
- Positron or another R-compatible IDE

### 1. Clone the repository

```bash
git clone https://github.com/NicolaRizzitello/football-integrity-analytics.git
cd football-integrity-analytics
```

### 2. Start the infrastructure

```bash
docker compose up -d
```

Airflow is available at:

```text
http://localhost:8080
```

### 3. Configure the competition

Edit:

```text
config/competition.yml
```

and select a competition/season available through StatsBomb Open Data.

### 4. Run the Airflow pipeline

Trigger:

```text
statsbomb_competition_pipeline
```

The pipeline will load competitions, matches and events into PostgreSQL and execute the data-quality checks.

### 5. Start the Shiny dashboard

From R:

```r
shiny::runApp("shiny")
```

---

## 📸 Dashboard

> Dashboard screenshots will be added here.

---

## 🎯 Project Goals

This project demonstrates practical skills across:

- sports analytics
- football event-data analysis
- data engineering
- ETL pipeline development
- workflow orchestration
- SQL
- data-quality engineering
- R analytics
- interactive dashboard development
- reproducible infrastructure

The architecture is intentionally modular so that additional competitions, metrics and integrity-monitoring methods can be added over time.

---

## 📚 Data Attribution

This project uses **StatsBomb Open Data**.

StatsBomb data is made available for research and educational use through the StatsBomb Open Data repository.

Users of this project should comply with the applicable StatsBomb Open Data terms and attribution requirements.

---

## ⚠️ Disclaimer

This is an independent portfolio and educational project.

The integrity-related analytics presented by the application are exploratory statistical indicators. They do not establish or imply that a player, team, match or competition has been involved in manipulation, misconduct or other improper activity.

---

## 👤 Author

**Nicola Rizzitello**

Football Data Analytics & Integrity Analytics Portfolio Project
