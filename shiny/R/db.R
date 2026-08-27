library(DBI)
library(RPostgres)

get_shiny_connection <- function() {
  dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("FOOTBALL_DB_HOST", "127.0.0.1"),
    port = as.integer(Sys.getenv("FOOTBALL_DB_PORT", "5433")),
    dbname = Sys.getenv("FOOTBALL_DB_NAME", "football"),
    user = Sys.getenv("FOOTBALL_DB_USER", "airflow"),
    password = Sys.getenv("FOOTBALL_DB_PASSWORD", "airflow")
  )
}
