-- ============================================================
-- Football Integrity Analytics
-- PostgreSQL database schema
-- ============================================================

CREATE TABLE IF NOT EXISTS competitions (
    competition_id INTEGER,
    season_id INTEGER,
    competition_name VARCHAR(255) NOT NULL,
    season_name VARCHAR(100),
    country_name VARCHAR(100),

    PRIMARY KEY (competition_id, season_id)
);


CREATE TABLE IF NOT EXISTS matches (
    match_id INTEGER PRIMARY KEY,

    competition_id INTEGER NOT NULL,
    season_id INTEGER NOT NULL,

    match_date DATE,
    kick_off TIME,

    home_team_id INTEGER,
    home_team_name VARCHAR(255),

    away_team_id INTEGER,
    away_team_name VARCHAR(255),

    home_score INTEGER,
    away_score INTEGER,

    stadium VARCHAR(255),
    referee VARCHAR(255),

    FOREIGN KEY (competition_id, season_id)
        REFERENCES competitions(competition_id, season_id)
);


CREATE TABLE IF NOT EXISTS players (
    player_id INTEGER PRIMARY KEY,
    player_name VARCHAR(255) NOT NULL
);


CREATE TABLE IF NOT EXISTS events (
    event_id UUID PRIMARY KEY,

    match_id INTEGER NOT NULL,

    event_index INTEGER,
    period INTEGER,
    minute INTEGER,
    second NUMERIC,

    event_type VARCHAR(100),

    team_id INTEGER,
    team_name VARCHAR(255),

    player_id INTEGER,
    player_name VARCHAR(255),

    possession INTEGER,
    possession_team_id INTEGER,
    possession_team_name VARCHAR(255),

    x NUMERIC,
    y NUMERIC,

    end_x NUMERIC,
    end_y NUMERIC,

    shot_xg NUMERIC,
    outcome VARCHAR(100),

    raw_json JSONB,

    FOREIGN KEY (match_id)
        REFERENCES matches(match_id)
);