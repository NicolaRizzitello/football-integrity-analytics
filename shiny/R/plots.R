library(ggplot2)
library(dplyr)
library(grid)
library(tidyr)
library(scales)

HOME_COLOR <- "#E45756"
AWAY_COLOR <- "#1597A5"
NAVY <- "#0B2E4F"
BLUE <- "#1E5B8C"
TEAL <- "#0F8B8D"
PURPLE <- "#5B3E96"
ORANGE <- "#F26A2E"
GREEN <- "#4E8B3D"
TEXT <- "#1D2733"
MUTED <- "#6B7785"
GRID <- "#E6EAF0"
PITCH <- "#F3F6F3"

team_palette <- function(home_team, away_team) {
  setNames(c(HOME_COLOR, AWAY_COLOR), c(home_team, away_team))
}

theme_fia <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", colour = NAVY, size = 15),
      plot.subtitle = element_text(colour = MUTED, size = 9.5),
      axis.title = element_text(colour = MUTED),
      axis.text = element_text(colour = TEXT),
      panel.grid.major = element_line(colour = GRID, linewidth = 0.35),
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      legend.title = element_text(face = "bold", colour = TEXT),
      legend.text = element_text(colour = TEXT),
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA)
    )
}

draw_pitch_shiny <- function() {

  circle <- data.frame(
    x = 60 + 10 * cos(seq(0, 2 * pi, length.out = 200)),
    y = 40 + 10 * sin(seq(0, 2 * pi, length.out = 200))
  )

  ggplot() +
    annotate("rect", xmin = 0, xmax = 120, ymin = 0, ymax = 80,
             fill = PITCH, colour = "#6A737C", linewidth = 0.75) +
    annotate("segment", x = 60, xend = 60, y = 0, yend = 80, colour = "#7A858D") +
    geom_path(data = circle, aes(x, y), colour = "#7A858D", linewidth = 0.55) +
    annotate("point", x = 60, y = 40, size = 1.2, colour = "#68747C") +
    annotate("rect", xmin = 0, xmax = 18, ymin = 18, ymax = 62, fill = NA, colour = "#7A858D") +
    annotate("rect", xmin = 102, xmax = 120, ymin = 18, ymax = 62, fill = NA, colour = "#7A858D") +
    annotate("rect", xmin = 0, xmax = 6, ymin = 30, ymax = 50, fill = NA, colour = "#7A858D") +
    annotate("rect", xmin = 114, xmax = 120, ymin = 30, ymax = 50, fill = NA, colour = "#7A858D") +
    coord_fixed(xlim = c(0, 120), ylim = c(0, 80), expand = FALSE) +
    theme_void() +
    theme(plot.background = element_rect(fill = "white", colour = NA))
}

plot_shots_shiny <- function(shots, home_team, away_team) {

  d <- shots %>%
    filter(!is.na(x), !is.na(y), !is.na(shot_xg)) %>%
    mutate(
      is_goal = outcome == "Goal",
      on_target = outcome %in% c("Goal", "Saved")
    )

  palette <- team_palette(home_team, away_team)

  draw_pitch_shiny() +
    geom_point(
      data = d,
      aes(x = x, y = y, size = shot_xg, fill = team_name),
      shape = 21,
      colour = "white",
      stroke = 1,
      alpha = 0.92
    ) +
    geom_point(
      data = d %>% filter(on_target & !is_goal),
      aes(x = x, y = y),
      shape = 1,
      size = 4.2,
      stroke = 1.1,
      colour = NAVY
    ) +
    geom_point(
      data = d %>% filter(is_goal),
      aes(x = x, y = y),
      shape = 8,
      size = 4.6,
      colour = NAVY
    ) +
    scale_fill_manual(values = palette, drop = FALSE) +
    scale_size_continuous(range = c(3, 12), name = "xG") +
    labs(
      title = "Shot map",
      subtitle = "Marker size proportional to expected goals",
      fill = NULL
    ) +
    theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold", colour = NAVY, size = 15),
      plot.subtitle = element_text(colour = MUTED, size = 9.5)
    )
}

plot_xg_timeline <- function(shots, home_team, away_team) {

  d <- shots %>%
    filter(!is.na(shot_xg)) %>%
    arrange(team_name, minute, second) %>%
    group_by(team_name) %>%
    mutate(cumulative_xg = cumsum(shot_xg)) %>%
    ungroup()

  palette <- team_palette(home_team, away_team)

  ggplot(d, aes(minute, cumulative_xg, colour = team_name)) +
    geom_step(linewidth = 1.25) +
    geom_point(
      data = d %>% filter(outcome == "Goal"),
      size = 3.5,
      stroke = 1.1
    ) +
    scale_colour_manual(values = palette, drop = FALSE) +
    scale_x_continuous(breaks = seq(0, 90, 15)) +
    labs(
      x = "Minute",
      y = "Cumulative xG",
      colour = NULL
    ) +
    theme_fia()
}

plot_attacking_profile <- function(metrics, home_team, away_team) {

  long <- metrics %>%
    select(team_name, final_third_entries, progressive_passes, shots, shots_on_target) %>%
    pivot_longer(-team_name, names_to = "metric", values_to = "value") %>%
    mutate(
      metric = recode(
        metric,
        final_third_entries = "Final-third entries",
        progressive_passes = "Progressive passes",
        shots = "Shots",
        shots_on_target = "Shots on target"
      )
    )

  palette <- team_palette(home_team, away_team)

  ggplot(long, aes(metric, value, fill = team_name)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.62) +
    geom_text(
      aes(label = value),
      position = position_dodge(width = 0.75),
      vjust = -0.35,
      size = 3.4,
      colour = TEXT
    ) +
    scale_fill_manual(values = palette, drop = FALSE) +
    labs(x = NULL, y = "Count", fill = NULL) +
    expand_limits(y = max(long$value, na.rm = TRUE) * 1.15) +
    theme_fia() +
    theme(
      axis.text.x = element_text(angle = 22, hjust = 1)
    )
}

plot_player_events <- function(events, player_name) {
  d <- events %>% filter(player_name == !!player_name, !is.na(x), !is.na(y))

  draw_pitch_shiny() +
    geom_point(
      data = d,
      aes(x = x, y = y, shape = event_type),
      size = 3,
      alpha = 0.75,
      colour = BLUE
    ) +
    labs(title = paste("Event map —", player_name), shape = "Event type") +
    theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold", colour = NAVY, size = 15)
    )
}

plot_player_profile <- function(player_stats, player_name) {

  d <- player_stats %>% filter(player_name == !!player_name)

  if (nrow(d) == 0) {
    return(ggplot() + theme_void() + labs(title = "No player data"))
  }

  d2 <- data.frame(
    metric = c("Shots", "xG", "Passes", "Carries", "Pressures"),
    value = c(d$shots[1], d$total_xg[1], d$passes[1], d$carries[1], d$pressures[1])
  )

  ggplot(d2, aes(reorder(metric, value), value)) +
    geom_col(fill = BLUE, width = 0.66) +
    geom_text(aes(label = value), hjust = -0.15, size = 3.4, colour = TEXT) +
    coord_flip() +
    expand_limits(y = max(d2$value, na.rm = TRUE) * 1.18) +
    labs(x = NULL, y = NULL, title = player_name) +
    theme_fia()
}

plot_pass_map <- function(events, team_name) {

  d <- events %>%
    filter(
      team_name == !!team_name,
      event_type == "Pass",
      !is.na(x), !is.na(y), !is.na(end_x), !is.na(end_y)
    ) %>%
    mutate(completed = is.na(outcome))

  draw_pitch_shiny() +
    geom_segment(
      data = d,
      aes(x = x, y = y, xend = end_x, yend = end_y, alpha = completed),
      arrow = arrow(length = unit(0.08, "inches")),
      linewidth = 0.5,
      colour = BLUE
    ) +
    scale_alpha_manual(values = c(`FALSE` = 0.12, `TRUE` = 0.52), guide = "none") +
    labs(
      title = paste("Pass map —", team_name),
      subtitle = "Completed passes emphasised"
    ) +
    theme(
      plot.title = element_text(face = "bold", colour = NAVY, size = 15),
      plot.subtitle = element_text(colour = MUTED)
    )
}

plot_event_density <- function(events, team_name) {

  d <- events %>%
    filter(team_name == !!team_name, !is.na(x), !is.na(y))

  draw_pitch_shiny() +
    stat_bin_2d(
      data = d,
      aes(x = x, y = y, fill = after_stat(count)),
      bins = 18,
      alpha = 0.84
    ) +
    scale_fill_viridis_c(option = "C", begin = 0.15, end = 0.9, name = "Events") +
    labs(title = paste("Event density —", team_name)) +
    theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold", colour = NAVY, size = 15)
    )
}

plot_progressive_passes <- function(events, team_name) {

  d <- events %>%
    filter(
      team_name == !!team_name,
      event_type == "Pass",
      is.na(outcome),
      !is.na(x), !is.na(y), !is.na(end_x), !is.na(end_y)
    ) %>%
    mutate(
      start_dist = sqrt((120 - x)^2 + (40 - y)^2),
      end_dist = sqrt((120 - end_x)^2 + (40 - end_y)^2),
      progressive = end_dist <= 0.75 * start_dist
    ) %>%
    filter(progressive)

  draw_pitch_shiny() +
    geom_segment(
      data = d,
      aes(x = x, y = y, xend = end_x, yend = end_y),
      arrow = arrow(length = unit(0.08, "inches")),
      linewidth = 0.7,
      alpha = 0.72,
      colour = TEAL
    ) +
    labs(
      title = paste("Progressive passes —", team_name),
      subtitle = "Completed passes reducing distance to goal by at least 25%"
    ) +
    theme(
      plot.title = element_text(face = "bold", colour = NAVY, size = 15),
      plot.subtitle = element_text(colour = MUTED)
    )
}

plot_final_third_entries <- function(events, team_name) {

  d <- events %>%
    filter(
      team_name == !!team_name,
      event_type == "Pass",
      is.na(outcome),
      !is.na(x), !is.na(y), !is.na(end_x), !is.na(end_y),
      x < 80,
      end_x >= 80
    )

  draw_pitch_shiny() +
    annotate(
      "rect",
      xmin = 80, xmax = 120, ymin = 0, ymax = 80,
      fill = "#DCE8F2", alpha = 0.34
    ) +
    geom_segment(
      data = d,
      aes(x = x, y = y, xend = end_x, yend = end_y),
      arrow = arrow(length = unit(0.08, "inches")),
      linewidth = 0.7,
      alpha = 0.78,
      colour = NAVY
    ) +
    labs(
      title = paste("Final-third entries —", team_name),
      subtitle = "Completed passes entering x ≥ 80"
    ) +
    theme(
      plot.title = element_text(face = "bold", colour = NAVY, size = 15),
      plot.subtitle = element_text(colour = MUTED)
    )
}

plot_integrity_profile <- function(signals) {

  ggplot(
    signals,
    aes(
      x = reorder(paste(team_name, metric, sep = " — "), abs_z),
      y = abs_z,
      fill = flag
    )
  ) +
    geom_col(width = 0.68) +
    coord_flip() +
    geom_hline(yintercept = 1.5, linetype = "dashed", colour = "#9AA5B1") +
    geom_hline(yintercept = 2.5, linetype = "dashed", colour = "#6B7785") +
    scale_fill_manual(
      values = c(
        "Within expected range" = "#5B8C85",
        "Moderate deviation" = "#D8A23A",
        "High deviation" = "#B74E58"
      )
    ) +
    labs(
      x = NULL,
      y = "Absolute z-score",
      fill = "Signal",
      subtitle = "Reference lines at |z| = 1.5 and |z| = 2.5"
    ) +
    theme_fia()
}
