import json
import os
import psycopg2
import requests
from pathlib import Path
import yaml



BASE_URL = "https://raw.githubusercontent.com/statsbomb/open-data/master/data"

DB_CONFIG = {
    "host": os.getenv(
        "FOOTBALL_DB_HOST",
        "127.0.0.1",
    ),
    "port": int(
        os.getenv(
            "FOOTBALL_DB_PORT",
            "5433",
        )
    ),
    "database": os.getenv(
        "FOOTBALL_DB_NAME",
        "football",
    ),
    "user": os.getenv(
        "FOOTBALL_DB_USER",
        "airflow",
    ),
    "password": os.getenv(
        "FOOTBALL_DB_PASSWORD",
        "airflow",
    ),
}


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def get_competitions():
    url = f"{BASE_URL}/competitions.json"

    response = requests.get(url, timeout=30)
    response.raise_for_status()

    return response.json()

def load_config():
    project_root = Path(__file__).resolve().parents[1]
    config_path = project_root / "config" / "competition.yml"

    with open(config_path, "r", encoding="utf-8") as file:
        return yaml.safe_load(file)

def get_matches(competition_id, season_id):
    url = f"{BASE_URL}/matches/{competition_id}/{season_id}.json"

    response = requests.get(url, timeout=30)
    response.raise_for_status()

    return response.json()


def get_events(match_id):
    url = f"{BASE_URL}/events/{match_id}.json"

    response = requests.get(url, timeout=30)
    response.raise_for_status()

    return response.json()


def load_competitions(competitions):
    sql = """
    INSERT INTO competitions (
        competition_id,
        season_id,
        competition_name,
        season_name,
        country_name
    )
    VALUES (%s, %s, %s, %s, %s)
    ON CONFLICT (competition_id, season_id)
    DO UPDATE SET
        competition_name = EXCLUDED.competition_name,
        season_name = EXCLUDED.season_name,
        country_name = EXCLUDED.country_name;
    """

    with get_connection() as conn:
        with conn.cursor() as cur:
            for competition in competitions:
                cur.execute(
                    sql,
                    (
                        competition["competition_id"],
                        competition["season_id"],
                        competition["competition_name"],
                        competition["season_name"],
                        competition["country_name"],
                    ),
                )


def load_matches(matches, competition_id, season_id):
    sql = """
    INSERT INTO matches (
        match_id,
        competition_id,
        season_id,
        match_date,
        kick_off,
        home_team_id,
        home_team_name,
        away_team_id,
        away_team_name,
        home_score,
        away_score,
        stadium,
        referee
    )
    VALUES (
        %s, %s, %s, %s, %s,
        %s, %s, %s, %s,
        %s, %s, %s, %s
    )
    ON CONFLICT (match_id)
    DO UPDATE SET
        home_score = EXCLUDED.home_score,
        away_score = EXCLUDED.away_score;
    """

    with get_connection() as conn:
        with conn.cursor() as cur:
            for match in matches:

                stadium = None
                if match.get("stadium"):
                    stadium = match["stadium"].get("name")

                referee = None
                if match.get("referee"):
                    referee = match["referee"].get("name")

                cur.execute(
                    sql,
                    (
                        match["match_id"],
                        competition_id,
                        season_id,
                        match.get("match_date"),
                        match.get("kick_off"),
                        match["home_team"]["home_team_id"],
                        match["home_team"]["home_team_name"],
                        match["away_team"]["away_team_id"],
                        match["away_team"]["away_team_name"],
                        match.get("home_score"),
                        match.get("away_score"),
                        stadium,
                        referee,
                    ),
                )


def load_events(events, match_id):
    sql = """
    INSERT INTO events (
        event_id,
        match_id,
        event_index,
        period,
        minute,
        second,
        event_type,
        team_id,
        team_name,
        player_id,
        player_name,
        possession,
        possession_team_id,
        possession_team_name,
        x,
        y,
        end_x,
        end_y,
        shot_xg,
        outcome,
        raw_json
    )
    VALUES (
        %s, %s, %s, %s, %s,
        %s, %s, %s, %s, %s,
        %s, %s, %s, %s, %s,
        %s, %s, %s, %s, %s,
        %s
    )
    ON CONFLICT (event_id)
    DO NOTHING;
    """

    with get_connection() as conn:
        with conn.cursor() as cur:

            for event in events:

                location = event.get("location", [])

                x = location[0] if len(location) > 0 else None
                y = location[1] if len(location) > 1 else None

                end_x = None
                end_y = None
                shot_xg = None
                outcome = None

                event_type = event.get("type", {}).get("name")

                if event_type == "Pass":

                    pass_data = event.get("pass", {})
                    end_location = pass_data.get("end_location", [])

                    if len(end_location) > 0:
                        end_x = end_location[0]

                    if len(end_location) > 1:
                        end_y = end_location[1]

                    outcome = pass_data.get("outcome", {}).get("name")

                elif event_type == "Shot":

                    shot_data = event.get("shot", {})
                    end_location = shot_data.get("end_location", [])

                    if len(end_location) > 0:
                        end_x = end_location[0]

                    if len(end_location) > 1:
                        end_y = end_location[1]

                    shot_xg = shot_data.get("statsbomb_xg")
                    outcome = shot_data.get("outcome", {}).get("name")

                player = event.get("player", {})
                team = event.get("team", {})
                possession_team = event.get("possession_team", {})

                cur.execute(
                    sql,
                    (
                        event["id"],
                        match_id,
                        event.get("index"),
                        event.get("period"),
                        event.get("minute"),
                        event.get("second"),
                        event_type,
                        team.get("id"),
                        team.get("name"),
                        player.get("id"),
                        player.get("name"),
                        event.get("possession"),
                        possession_team.get("id"),
                        possession_team.get("name"),
                        x,
                        y,
                        end_x,
                        end_y,
                        shot_xg,
                        outcome,
                        json.dumps(event),
                    ),
                )


def main():
    competitions = get_competitions()

    print(f"Competitions found: {len(competitions)}")
    config = load_config()

    competition_id = config["competition_id"]
    season_id = config["season_id"]

    print(
        f'Competition: {config["competition_name"]}'
        f'({config["season_name"]})'
    )

    competitions = get_competitions()

    print(f"Competitions found: {len(competitions)}")

    load_competitions(competitions)

    print("Competitions loaded into PostgreSQL.")

    matches = get_matches(
        competition_id=competition_id,
        season_id=season_id,
    )

    print(f"Matches found: {len(matches)}")

    load_matches(
        matches=matches,
        competition_id=competition_id,
        season_id=season_id,
    )

    print("Matches loaded into PostgreSQL.")

    test_match_id = matches[0]["match_id"]

    print(f"Downloading events for match {test_match_id}...")

    events = get_events(test_match_id)

    print(f"Events found: {len(events)}")

    load_events(
        events=events,
        match_id=test_match_id,
    )

    print("Events loaded into PostgreSQL.")


if __name__ == "__main__":
    main()