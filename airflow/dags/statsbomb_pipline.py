from datetime import datetime
import os
from pathlib import Path

import psycopg2
import yaml

from airflow import DAG
from airflow.operators.python import PythonOperator

from ingestion.statsbomb import (
    get_competitions,
    get_matches,
    get_events,
    load_competitions,
    load_matches,
    load_events,
)


# ============================================================
# CONFIGURATION
# ============================================================

PROJECT_ROOT = Path("/opt/airflow")

CONFIG_PATH = PROJECT_ROOT / "config" / "competition.yml"

with open(CONFIG_PATH, "r", encoding="utf-8") as file:
    CONFIG = yaml.safe_load(file)


COMPETITION_ID = CONFIG["competition_id"]
SEASON_ID = CONFIG["season_id"]

COMPETITION_NAME = CONFIG["competition_name"]
SEASON_NAME = CONFIG["season_name"]


# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_db_connection():

    return psycopg2.connect(
        host=os.getenv("FOOTBALL_DB_HOST", "postgres"),
        port=int(
            os.getenv(
                "FOOTBALL_DB_PORT",
                "5432",
            )
        ),
        database=os.getenv(
            "FOOTBALL_DB_NAME",
            "football",
        ),
        user=os.getenv(
            "FOOTBALL_DB_USER",
            "airflow",
        ),
        password=os.getenv(
            "FOOTBALL_DB_PASSWORD",
            "airflow",
        ),
    )


# ============================================================
# TASK 1
# LOAD COMPETITIONS
# ============================================================

def extract_and_load_competitions():

    print(
        f"Configured competition: "
        f"{COMPETITION_NAME} {SEASON_NAME}"
    )

    competitions = get_competitions()

    print(
        f"Competitions found: "
        f"{len(competitions)}"
    )

    load_competitions(
        competitions
    )

    print(
        "Competitions loaded successfully."
    )


# ============================================================
# TASK 2
# LOAD MATCHES
# ============================================================

def extract_and_load_matches():

    print(
        f"Downloading matches for "
        f"{COMPETITION_NAME} "
        f"{SEASON_NAME}"
    )

    matches = get_matches(
        competition_id=COMPETITION_ID,
        season_id=SEASON_ID,
    )

    print(
        f"Matches found: {len(matches)}"
    )

    load_matches(
        matches=matches,
        competition_id=COMPETITION_ID,
        season_id=SEASON_ID,
    )

    print(
        "Matches loaded successfully."
    )


# ============================================================
# TASK 3
# LOAD EVENTS
# ============================================================

def extract_and_load_events():

    matches = get_matches(
        competition_id=COMPETITION_ID,
        season_id=SEASON_ID,
    )

    total_matches = len(matches)

    print(
        f"Starting event ingestion for "
        f"{total_matches} matches."
    )

    total_events = 0

    for i, match in enumerate(
        matches,
        start=1,
    ):

        match_id = match["match_id"]

        home_team = (
            match["home_team"]
            ["home_team_name"]
        )

        away_team = (
            match["away_team"]
            ["away_team_name"]
        )

        print(
            f"[{i}/{total_matches}] "
            f"{home_team} vs {away_team} "
            f"(match_id={match_id})"
        )

        events = get_events(
            match_id
        )

        event_count = len(events)

        print(
            f"Events found: "
            f"{event_count}"
        )

        load_events(
            events=events,
            match_id=match_id,
        )

        total_events += event_count

    print(
        "----------------------------------"
    )

    print(
        f"EVENT INGESTION COMPLETED"
    )

    print(
        f"Matches processed: "
        f"{total_matches}"
    )

    print(
        f"Events processed: "
        f"{total_events}"
    )

    print(
        "----------------------------------"
    )


# ============================================================
# TASK 4
# DATA QUALITY
# ============================================================

def run_data_quality_checks():

    # Get expected number of matches
    # directly from the source.
    source_matches = get_matches(
        competition_id=COMPETITION_ID,
        season_id=SEASON_ID,
    )

    expected_match_count = len(
        source_matches
    )

    print(
        f"Expected matches: "
        f"{expected_match_count}"
    )

    connection = get_db_connection()

    try:

        with connection.cursor() as cur:

            # =================================================
            # CHECK 1
            # Expected matches loaded
            # =================================================

            cur.execute(
                """
                SELECT COUNT(*)
                FROM matches
                WHERE competition_id = %s
                  AND season_id = %s;
                """,
                (
                    COMPETITION_ID,
                    SEASON_ID,
                ),
            )

            match_count = (
                cur.fetchone()[0]
            )

            print(
                f"Matches in database: "
                f"{match_count}"
            )

            if (
                match_count
                != expected_match_count
            ):

                raise ValueError(
                    "Data quality failed: "
                    f"expected "
                    f"{expected_match_count} "
                    f"matches, found "
                    f"{match_count}."
                )


            # =================================================
            # CHECK 2
            # Every match has events
            # =================================================

            cur.execute(
                """
                SELECT
                    m.match_id,
                    m.home_team_name,
                    m.away_team_name
                FROM matches m

                LEFT JOIN events e
                    ON m.match_id =
                       e.match_id

                WHERE
                    m.competition_id = %s
                    AND m.season_id = %s

                GROUP BY
                    m.match_id,
                    m.home_team_name,
                    m.away_team_name

                HAVING
                    COUNT(e.event_id) = 0;
                """,
                (
                    COMPETITION_ID,
                    SEASON_ID,
                ),
            )

            matches_without_events = (
                cur.fetchall()
            )

            if matches_without_events:

                print(
                    "Matches without events:"
                )

                for row in (
                    matches_without_events
                ):
                    print(row)

                raise ValueError(
                    "Data quality failed: "
                    f"{len(matches_without_events)} "
                    f"matches have no events."
                )

            print(
                "All matches contain events."
            )


            # =================================================
            # CHECK 3
            # Duplicate event IDs
            # =================================================

            cur.execute(
                """
                SELECT
                    e.event_id

                FROM events e

                JOIN matches m
                    ON e.match_id =
                       m.match_id

                WHERE
                    m.competition_id = %s
                    AND m.season_id = %s

                GROUP BY
                    e.event_id

                HAVING
                    COUNT(*) > 1

                LIMIT 1;
                """,
                (
                    COMPETITION_ID,
                    SEASON_ID,
                ),
            )

            duplicate = (
                cur.fetchone()
            )

            if duplicate:

                raise ValueError(
                    "Data quality failed: "
                    "duplicate event_id "
                    "detected."
                )

            print(
                "No duplicate event IDs."
            )


            # =================================================
            # CHECK 4
            # Pitch coordinates
            # StatsBomb reference pitch = 120 x 80
            # Minor source deviations are warnings.
            # Material deviations fail the pipeline.
            # =================================================

            cur.execute(
                """
                SELECT
                    e.event_id,
                    e.match_id,
                    e.x,
                    e.y
                FROM events e
                JOIN matches m
                    ON e.match_id = m.match_id
                WHERE
                    m.competition_id = %s
                    AND m.season_id = %s
                    AND (
                        (
                            e.x IS NOT NULL
                            AND (e.x < 0 OR e.x > 120)
                        )
                        OR
                        (
                            e.y IS NOT NULL
                            AND (e.y < 0 OR e.y > 80)
                        )
                    );
                """,
                (
                    COMPETITION_ID,
                    SEASON_ID,
                ),
            )

            coordinate_anomalies = cur.fetchall()

            if coordinate_anomalies:

                print(
                    f"WARNING: "
                    f"{len(coordinate_anomalies)} "
                    f"coordinate anomalies detected."
                )

                for row in coordinate_anomalies:
                    print(
                        "Coordinate anomaly:",
                        row,
                    )

            # Fail only for materially invalid coordinates.
            # A small tolerance is allowed for source-level
            # deviations such as x = 120.3.
            cur.execute(
                """
                SELECT COUNT(*)
                FROM events e
                JOIN matches m
                    ON e.match_id = m.match_id
                WHERE
                    m.competition_id = %s
                    AND m.season_id = %s
                    AND (
                        (
                            e.x IS NOT NULL
                            AND (e.x < -0.5 OR e.x > 120.5)
                        )
                        OR
                        (
                            e.y IS NOT NULL
                            AND (e.y < -0.5 OR e.y > 80.5)
                        )
                    );
                """,
                (
                    COMPETITION_ID,
                    SEASON_ID,
                ),
            )

            severe_invalid_coordinates = cur.fetchone()[0]

            if severe_invalid_coordinates > 0:

                raise ValueError(
                    "Data quality failed: "
                    f"{severe_invalid_coordinates} "
                    "materially invalid coordinates."
                )

            print(
                "Coordinate quality check passed."
            )


            # =================================================
            # CHECK 5
            # Event volume
            # =================================================

            cur.execute(
                """
                SELECT COUNT(*)

                FROM events e

                JOIN matches m
                    ON e.match_id =
                       m.match_id

                WHERE
                    m.competition_id = %s
                    AND m.season_id = %s;
                """,
                (
                    COMPETITION_ID,
                    SEASON_ID,
                ),
            )

            event_count = (
                cur.fetchone()[0]
            )

            print(
                f"Total events: "
                f"{event_count}"
            )

            if event_count == 0:

                raise ValueError(
                    "Data quality failed: "
                    "no events found."
                )


            # =================================================
            # SUCCESS
            # =================================================

            print(
                "=================================="
            )

            print(
                "ALL DATA QUALITY CHECKS PASSED"
            )

            print(
                f"{COMPETITION_NAME} "
                f"{SEASON_NAME}"
            )

            print(
                f"Matches: {match_count}"
            )

            print(
                f"Events: {event_count}"
            )

            print(
                "=================================="
            )

    finally:

        connection.close()


# ============================================================
# DAG
# ============================================================

with DAG(

    dag_id="statsbomb_competition_pipeline",

    description=(
        "Configurable StatsBomb "
        "football data ingestion pipeline"
    ),

    start_date=datetime(
        2026,
        1,
        1,
    ),

    schedule=None,

    catchup=False,

    tags=[
        "football",
        "statsbomb",
        "integrity",
        "analytics",
    ],

) as dag:

    load_competitions_task = (
        PythonOperator(
            task_id="load_competitions",
            python_callable=(
                extract_and_load_competitions
            ),
        )
    )

    load_matches_task = (
        PythonOperator(
            task_id="load_matches",
            python_callable=(
                extract_and_load_matches
            ),
        )
    )

    load_events_task = (
        PythonOperator(
            task_id="load_events",
            python_callable=(
                extract_and_load_events
            ),
        )
    )

    data_quality_task = (
        PythonOperator(
            task_id="data_quality_check",
            python_callable=(
                run_data_quality_checks
            ),
        )
    )

    (
        load_competitions_task
        >> load_matches_task
        >> load_events_task
        >> data_quality_task
    )