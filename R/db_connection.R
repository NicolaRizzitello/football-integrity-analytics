library(DBI)
library(RPostgres)
library(dplyr)

con <- dbConnect(
  RPostgres::Postgres(),
  host = "127.0.0.1",
  port = 5433,
  dbname = "football",
  user = "airflow",
  password = "airflow"
)

print("Connected to PostgreSQL")

print(
  dbGetQuery(
    con,
    "SELECT COUNT(*) AS events FROM events;"
  )
)
player_shots <- dbGetQuery(
  con,
  "
  SELECT
      player_name,
      team_name,
      COUNT(*) AS shots,
      SUM(shot_xg) AS total_xg,
      AVG(shot_xg) AS avg_xg
  FROM events
  WHERE event_type = 'Shot'
    AND player_name IS NOT NULL
  GROUP BY
      player_name,
      team_name
  ORDER BY total_xg DESC;
  "
)

print(head(player_shots, 20))

dbDisconnect(con)