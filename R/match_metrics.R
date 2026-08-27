library(DBI)
library(RPostgres)
library(dplyr)


get_connection <- function() {
  dbConnect(
    RPostgres::Postgres(),
    host = "127.0.0.1",
    port = 5433,
    dbname = "football",
    user = "airflow",
    password = "airflow"
  )
}


get_match_list <- function(con) {
  
  query <- "
    SELECT
      match_id,
      match_date,
      home_team_name,
      away_team_name,
      home_score,
      away_score
    FROM matches
    ORDER BY match_date;
  "
  
  dbGetQuery(con, query)
}


get_match_summary <- function(con, match_id) {
  
  query <- "
    SELECT
      team_name,

      COUNT(*) FILTER (
        WHERE event_type = 'Shot'
      ) AS shots,

      SUM(shot_xg) FILTER (
        WHERE event_type = 'Shot'
      ) AS total_xg,

      COUNT(*) FILTER (
        WHERE event_type = 'Pass'
      ) AS passes,

      COUNT(*) FILTER (
        WHERE event_type = 'Pass'
          AND outcome IS NULL
      ) AS completed_passes,

      COUNT(*) FILTER (
        WHERE event_type = 'Carry'
      ) AS carries,

      COUNT(*) FILTER (
        WHERE event_type = 'Pressure'
      ) AS pressures

    FROM events

    WHERE match_id = $1

    GROUP BY team_name

    ORDER BY team_name;
  "
  
  result <- dbGetQuery(
    con,
    query,
    params = list(match_id)
  )
  
  result %>%
    mutate(
      pass_completion = ifelse(
        passes > 0,
        round(
          completed_passes / passes * 100,
          1
        ),
        NA
      ),
      total_xg = round(total_xg, 2)
    )
}


get_player_shots <- function(con, match_id) {
  
  query <- "
    SELECT
      player_name,
      team_name,
      COUNT(*) AS shots,
      SUM(shot_xg) AS total_xg,
      AVG(shot_xg) AS avg_xg

    FROM events

    WHERE match_id = $1
      AND event_type = 'Shot'
      AND player_name IS NOT NULL

    GROUP BY
      player_name,
      team_name

    ORDER BY total_xg DESC;
  "
  
  dbGetQuery(
    con,
    query,
    params = list(match_id)
  )
}


get_shot_events <- function(con, match_id) {
  
  query <- "
    SELECT
      event_id,
      minute,
      second,
      team_name,
      player_name,
      x,
      y,
      end_x,
      end_y,
      shot_xg,
      outcome

    FROM events

    WHERE match_id = $1
      AND event_type = 'Shot'

    ORDER BY
      minute,
      second;
  "
  
  dbGetQuery(
    con,
    query,
    params = list(match_id)
  )
}


get_pass_events <- function(con, match_id) {
  
  query <- "
    SELECT
      event_id,
      minute,
      second,
      team_name,
      player_name,
      x,
      y,
      end_x,
      end_y,
      outcome

    FROM events

    WHERE match_id = $1
      AND event_type = 'Pass'

    ORDER BY
      minute,
      second;
  "
  
  dbGetQuery(
    con,
    query,
    params = list(match_id)
  )
}