source("R/match_metrics.R")

con <- get_connection()

matches <- get_match_list(con)

print(head(matches))

test_match_id <- matches$match_id[1]

cat(
  "\nTesting match:",
  test_match_id,
  "\n\n"
)

summary <- get_match_summary(
  con,
  test_match_id
)

print(summary)

cat("\nPlayer shot analysis:\n")

player_shots <- get_player_shots(
  con,
  test_match_id
)

print(player_shots)

cat("\nShot events:\n")

shots <- get_shot_events(
  con,
  test_match_id
)

print(
  head(shots, 10)
)

source("R/visualisations.R")

shot_map <- plot_shot_map(shots)

print(shot_map)

dbDisconnect(con)
