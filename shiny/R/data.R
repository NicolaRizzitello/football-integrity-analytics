library(DBI)
library(dplyr)

to_num <- function(x) as.numeric(x)
to_int <- function(x) as.integer(as.numeric(x))

get_competitions_shiny <- function(con) {
  dbGetQuery(
    con,
    "
    SELECT DISTINCT
      c.competition_id,
      c.competition_name,
      c.season_id,
      c.season_name
    FROM competitions c
    JOIN matches m
      ON c.competition_id = m.competition_id
     AND c.season_id = m.season_id
    ORDER BY
      c.competition_name,
      c.season_name;
    "
  )
}

get_matches_by_competition_shiny <- function(
  con,
  competition_id,
  season_id
) {
  dbGetQuery(
    con,
    "
    SELECT
      match_id,
      match_date,
      home_team_name,
      away_team_name,
      home_score,
      away_score
    FROM matches
    WHERE competition_id = $1
      AND season_id = $2
    ORDER BY match_date;
    ",
    params = list(
      competition_id,
      season_id
    )
  )
}

get_matches_shiny <- function(con) {
  dbGetQuery(
    con,
    "SELECT match_id, match_date, home_team_name, away_team_name, home_score, away_score
     FROM matches
     ORDER BY match_date;"
  )
}

get_match_info_shiny <- function(con, match_id) {
  dbGetQuery(
    con,
    "SELECT match_id, match_date, home_team_name, away_team_name, home_score, away_score
     FROM matches
     WHERE match_id = $1;",
    params = list(match_id)
  )
}

get_match_summary_shiny <- function(con, match_id) {
  x <- dbGetQuery(
    con,
    "
    SELECT
      team_name,
      COUNT(*) FILTER (WHERE event_type = 'Shot') AS shots,
      COALESCE(SUM(shot_xg) FILTER (WHERE event_type = 'Shot'), 0) AS total_xg,
      COUNT(*) FILTER (WHERE event_type = 'Pass') AS passes,
      COUNT(*) FILTER (WHERE event_type = 'Pass' AND outcome IS NULL) AS completed_passes,
      COUNT(*) FILTER (WHERE event_type = 'Carry') AS carries,
      COUNT(*) FILTER (WHERE event_type = 'Pressure') AS pressures
    FROM events
    WHERE match_id = $1
    GROUP BY team_name
    ORDER BY team_name;
    ",
    params = list(match_id)
  )

  x %>%
    mutate(
      shots = to_int(shots),
      passes = to_int(passes),
      completed_passes = to_int(completed_passes),
      carries = to_int(carries),
      pressures = to_int(pressures),
      total_xg = round(to_num(total_xg), 2),
      pass_completion = ifelse(
        passes > 0,
        round(completed_passes / passes * 100, 1),
        NA_real_
      )
    )
}

get_shots_shiny <- function(con, match_id) {
  dbGetQuery(
    con,
    "
    SELECT
      event_id, minute, second, team_name, player_name,
      x, y, shot_xg, outcome
    FROM events
    WHERE match_id = $1
      AND event_type = 'Shot'
    ORDER BY minute, second;
    ",
    params = list(match_id)
  ) %>%
    mutate(
      minute = to_int(minute),
      second = to_num(second),
      x = to_num(x),
      y = to_num(y),
      shot_xg = to_num(shot_xg)
    )
}

get_match_events_shiny <- function(con, match_id) {
  dbGetQuery(
    con,
    "
    SELECT
      event_id, event_index, minute, second, event_type,
      team_name, player_name, x, y, end_x, end_y,
      shot_xg, outcome
    FROM events
    WHERE match_id = $1
    ORDER BY event_index;
    ",
    params = list(match_id)
  ) %>%
    mutate(
      event_index = to_int(event_index),
      minute = to_int(minute),
      second = to_num(second),
      x = to_num(x),
      y = to_num(y),
      end_x = to_num(end_x),
      end_y = to_num(end_y),
      shot_xg = to_num(shot_xg)
    )
}

get_player_performance_shiny <- function(con, match_id) {
  x <- dbGetQuery(
    con,
    "
    SELECT
      player_name,
      team_name,
      COUNT(*) FILTER (WHERE event_type = 'Shot') AS shots,
      COALESCE(SUM(shot_xg) FILTER (WHERE event_type = 'Shot'), 0) AS total_xg,
      COUNT(*) FILTER (WHERE event_type = 'Pass') AS passes,
      COUNT(*) FILTER (WHERE event_type = 'Pass' AND outcome IS NULL) AS completed_passes,
      COUNT(*) FILTER (WHERE event_type = 'Carry') AS carries,
      COUNT(*) FILTER (WHERE event_type = 'Pressure') AS pressures
    FROM events
    WHERE match_id = $1
      AND player_name IS NOT NULL
    GROUP BY player_name, team_name
    ORDER BY total_xg DESC, shots DESC, passes DESC;
    ",
    params = list(match_id)
  )

  x %>%
    mutate(
      shots = to_int(shots),
      passes = to_int(passes),
      completed_passes = to_int(completed_passes),
      carries = to_int(carries),
      pressures = to_int(pressures),
      total_xg = round(to_num(total_xg), 2),
      pass_completion = ifelse(
        passes > 0,
        round(completed_passes / passes * 100, 1),
        NA_real_
      )
    )
}

get_advanced_match_metrics_shiny <- function(con, match_id) {
  x <- dbGetQuery(
    con,
    "
    SELECT
      team_name,

      COUNT(*) FILTER (
        WHERE event_type = 'Shot'
      ) AS shots,

      COUNT(*) FILTER (
        WHERE event_type = 'Shot'
          AND outcome IN ('Goal', 'Saved')
      ) AS shots_on_target,

      COALESCE(SUM(shot_xg) FILTER (
        WHERE event_type = 'Shot'
      ), 0) AS total_xg,

      COUNT(*) FILTER (
        WHERE event_type = 'Pass'
          AND outcome IS NULL
          AND x IS NOT NULL
          AND y IS NOT NULL
          AND end_x IS NOT NULL
          AND end_y IS NOT NULL
          AND (
            sqrt(power(120 - end_x, 2) + power(40 - end_y, 2))
            <= 0.75 * sqrt(power(120 - x, 2) + power(40 - y, 2))
          )
      ) AS progressive_passes,

      COUNT(*) FILTER (
        WHERE event_type = 'Pass'
          AND outcome IS NULL
          AND x < 80
          AND end_x >= 80
      ) AS final_third_entries

    FROM events
    WHERE match_id = $1
    GROUP BY team_name
    ORDER BY team_name;
    ",
    params = list(match_id)
  )

  x %>%
    mutate(
      shots = to_int(shots),
      shots_on_target = to_int(shots_on_target),
      progressive_passes = to_int(progressive_passes),
      final_third_entries = to_int(final_third_entries),
      total_xg = to_num(total_xg),
      xg_per_shot = ifelse(shots > 0, round(total_xg / shots, 3), 0),
      shot_accuracy = ifelse(
        shots > 0,
        round(shots_on_target / shots * 100, 1),
        0
      )
    )
}
