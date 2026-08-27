library(DBI)
library(dplyr)

get_integrity_signals_shiny <- function(con, match_id) {

  baseline <- dbGetQuery(
    con,
    "
    WITH team_match AS (
      SELECT
        match_id,
        team_name,
        COUNT(*) FILTER (WHERE event_type = 'Shot')::numeric AS shots,
        COALESCE(SUM(shot_xg) FILTER (WHERE event_type = 'Shot'), 0)::numeric AS total_xg,
        COUNT(*) FILTER (WHERE event_type = 'Pass')::numeric AS passes,
        COUNT(*) FILTER (WHERE event_type = 'Pass' AND outcome IS NULL)::numeric AS completed_passes,
        COUNT(*) FILTER (WHERE event_type = 'Carry')::numeric AS carries,
        COUNT(*) FILTER (WHERE event_type = 'Pressure')::numeric AS pressures
      FROM events
      GROUP BY match_id, team_name
    )
    SELECT
      match_id,
      team_name,
      shots,
      total_xg,
      passes,
      CASE WHEN passes > 0 THEN completed_passes / passes * 100 ELSE NULL END AS pass_completion,
      carries,
      pressures
    FROM team_match;
    "
  ) %>%
    mutate(
      match_id = as.integer(as.numeric(match_id)),
      shots = as.numeric(shots),
      total_xg = as.numeric(total_xg),
      passes = as.numeric(passes),
      pass_completion = as.numeric(pass_completion),
      carries = as.numeric(carries),
      pressures = as.numeric(pressures)
    )

  current <- baseline %>% filter(match_id == !!match_id)

  metric_names <- c(
    "shots",
    "total_xg",
    "passes",
    "pass_completion",
    "carries",
    "pressures"
  )

  signals <- bind_rows(lapply(metric_names, function(metric) {

    mu <- mean(baseline[[metric]], na.rm = TRUE)
    sigma <- sd(baseline[[metric]], na.rm = TRUE)

    z <- if (is.na(sigma) || sigma == 0) {
      rep(0, nrow(current))
    } else {
      (current[[metric]] - mu) / sigma
    }

    data.frame(
      team_name = current$team_name,
      metric = metric,
      value = round(current[[metric]], 2),
      z_score = round(z, 2),
      abs_z = round(abs(z), 2)
    )
  })) %>%
    mutate(
      flag = case_when(
        abs_z >= 2.5 ~ "High deviation",
        abs_z >= 1.5 ~ "Moderate deviation",
        TRUE ~ "Within expected range"
      )
    ) %>%
    arrange(desc(abs_z))

  score <- round(mean(pmin(signals$abs_z, 3), na.rm = TRUE) / 3 * 100, 1)

  level <- case_when(
    score >= 60 ~ "High review priority",
    score >= 35 ~ "Moderate review priority",
    TRUE ~ "Low review priority"
  )

  list(score = score, level = level, signals = signals)
}
