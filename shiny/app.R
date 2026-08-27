library(shiny)
library(bslib)
library(bsicons)
library(DT)
library(DBI)
library(dplyr)

source("R/db.R")
source("R/data.R")
source("R/metrics.R")
source("R/plots.R")

startup_con <- get_shiny_connection()
competition_data <- get_competitions_shiny(startup_con)
DBI::dbDisconnect(startup_con)

ui <- page_sidebar(
  fillable = FALSE,
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),

  title = div(
    class = "app-title",
    span(class = "app-title-main", "Football Integrity Analytics"),
    span(
      class = "app-title-sub",
      "Player Performance • Match Analysis • Integrity Signals"
    )
  ),

  theme = bs_theme(
    version = 5,
    primary = "#0B2E4F",
    secondary = "#1E5B8C",
    success = "#0F8B8D",
    bg = "#F5F7FA",
    fg = "#1D2733"
  ),

  sidebar = sidebar(
    width = 330,

    div(
      class = "sidebar-logo",
      tags$img(src = "logo.jpg", class = "main-logo")
    ),

    div(
      class = "sidebar-intro",
      h5("Analysis workspace"),
      p(
        "Explore match performance, spatial patterns and statistical integrity indicators."
      )
    ),

    selectInput(
      "competition_id",
      "Competition",
      choices = NULL
    ),

    selectInput(
      "season_id",
      "Season",
      choices = NULL
    ),

    selectInput(
      "match_id",
      "Match",
      choices = NULL
    ),

    uiOutput("team_filter_ui"),

    hr(),

    div(
      class = "methodology-note",
      tags$b("Methodology note"),
      tags$p(
        "Integrity signals are exploratory statistical flags intended to support analyst review. They are not evidence of match manipulation."
      )
    ),

    div(
      class = "portfolio-note",
      bs_icon("shield-check"),
      span("Football Integrity Analytics"),
      span(class = "portfolio-subtitle", "Portfolio Project")
    )
  ),

  navset_card_tab(
    id = "main_tabs",

    nav_panel(
      "Overview",

      uiOutput("match_header"),

      div(
        class = "kpi-row",
        layout_columns(
          value_box(
            title = "Home xG",
            value = textOutput("home_xg", inline = TRUE),
            showcase = bs_icon("bullseye"),
            class = "kpi-box kpi-home"
          ),
          value_box(
            title = "Away xG",
            value = textOutput("away_xg", inline = TRUE),
            showcase = bs_icon("bullseye"),
            class = "kpi-box kpi-away"
          ),
          value_box(
            title = "Total shots",
            value = textOutput("total_shots", inline = TRUE),
            showcase = bs_icon("bounding-box"),
            class = "kpi-box"
          ),
          value_box(
            title = "Shots on target",
            value = textOutput("shots_on_target", inline = TRUE),
            showcase = bs_icon("crosshair"),
            class = "kpi-box kpi-purple"
          ),
          col_widths = c(3, 3, 3, 3)
        )
      ),

      div(
        class = "kpi-row",
        layout_columns(
          value_box(
            title = "Home pass completion",
            value = textOutput("home_pass_pct", inline = TRUE),
            showcase = bs_icon("check2-circle"),
            class = "kpi-box kpi-home"
          ),
          value_box(
            title = "Away pass completion",
            value = textOutput("away_pass_pct", inline = TRUE),
            showcase = bs_icon("check2-circle"),
            class = "kpi-box kpi-away"
          ),
          value_box(
            title = "Progressive passes",
            value = textOutput("progressive_passes", inline = TRUE),
            showcase = bs_icon("graph-up-arrow"),
            class = "kpi-box kpi-orange"
          ),
          value_box(
            title = "Final-third entries",
            value = textOutput("final_third_entries", inline = TRUE),
            showcase = bs_icon("box-arrow-in-right"),
            class = "kpi-box kpi-green"
          ),
          col_widths = c(3, 3, 3, 3)
        )
      ),

      div(
        class = "kpi-row",
        layout_columns(
          value_box(
            title = "xG per shot (home)",
            value = textOutput("home_xg_per_shot", inline = TRUE),
            showcase = bs_icon("bar-chart-line"),
            class = "kpi-box kpi-home"
          ),
          value_box(
            title = "xG per shot (away)",
            value = textOutput("away_xg_per_shot", inline = TRUE),
            showcase = bs_icon("bar-chart-line"),
            class = "kpi-box kpi-away"
          ),
          value_box(
            title = "Shot accuracy (home)",
            value = textOutput("home_shot_accuracy", inline = TRUE),
            showcase = bs_icon("crosshair"),
            class = "kpi-box kpi-purple"
          ),
          value_box(
            title = "Shot accuracy (away)",
            value = textOutput("away_shot_accuracy", inline = TRUE),
            showcase = bs_icon("crosshair"),
            class = "kpi-box kpi-away"
          ),
          col_widths = c(3, 3, 3, 3)
        )
      ),

      div(
        class = "section-row",
        layout_columns(
          card(
            full_screen = TRUE,
            card_header("Team comparison"),
            DTOutput("team_summary")
          ),
          card(
            full_screen = TRUE,
            card_header("xG timeline"),
            plotOutput("xg_timeline", height = 360)
          ),
          col_widths = c(5, 7)
        )
      ),

      div(
        class = "section-row",
        layout_columns(
          card(
            full_screen = TRUE,
            card_header("Shot map"),
            plotOutput("shot_map", height = 560)
          ),
          card(
            full_screen = TRUE,
            card_header("Attacking profile"),
            plotOutput("attacking_profile", height = 560)
          ),
          col_widths = c(7, 5)
        )
      )
    ),

    nav_panel(
      "Player Analysis",

      layout_columns(
        card(
          card_header("Player"),
          selectInput("player_name", "Select player", choices = NULL)
        ),
        card(
          card_header("Player summary"),
          uiOutput("player_kpis")
        ),
        col_widths = c(4, 8)
      ),

      layout_columns(
        card(
          full_screen = TRUE,
          card_header("Player event map"),
          plotOutput("player_map", height = 470)
        ),
        card(
          full_screen = TRUE,
          card_header("Player profile"),
          plotOutput("player_shooting_plot", height = 470)
        ),
        col_widths = c(7, 5)
      ),

      card(
        full_screen = TRUE,
        card_header("Player performance table"),
        DTOutput("player_table")
      )
    ),

    nav_panel(
      "Spatial Analysis",

      layout_columns(
        card(
          full_screen = TRUE,
          card_header("Pass map"),
          plotOutput("pass_map", height = 520)
        ),
        card(
          full_screen = TRUE,
          card_header("Event density"),
          plotOutput("event_density", height = 520)
        ),
        col_widths = c(7, 5)
      ),

      layout_columns(
        card(
          full_screen = TRUE,
          card_header("Progressive passes"),
          plotOutput("progressive_map", height = 480)
        ),
        card(
          full_screen = TRUE,
          card_header("Final-third entries"),
          plotOutput("final_third_map", height = 480)
        ),
        col_widths = c(6, 6)
      )
    ),

    nav_panel(
      "Integrity Signals",

      layout_columns(
        value_box(
          title = "Match anomaly score",
          value = textOutput("anomaly_score", inline = TRUE),
          showcase = bs_icon("exclamation-triangle"),
          class = "kpi-box kpi-orange"
        ),
        value_box(
          title = "Signal level",
          value = textOutput("signal_level", inline = TRUE),
          showcase = bs_icon("shield-exclamation"),
          class = "kpi-box kpi-purple"
        ),
        value_box(
          title = "Largest deviation",
          value = textOutput("largest_deviation", inline = TRUE),
          showcase = bs_icon("graph-up-arrow"),
          class = "kpi-box"
        ),
        col_widths = c(4, 4, 4)
      ),

      card(
        card_header("Exploratory integrity indicators"),
        p(
          class = "text-muted",
          "Indicators compare the selected match with the distribution of team-match observations in the loaded competition."
        ),
        DTOutput("integrity_table")
      ),

      card(
        full_screen = TRUE,
        card_header("Deviation profile"),
        plotOutput("integrity_plot", height = 420)
      )
    )
  )
)

server <- function(input, output, session) {
  con <- get_shiny_connection()

  observe({
    competitions <- competition_data %>%
      distinct(
        competition_id,
        competition_name
      ) %>%
      arrange(competition_name)

    competition_choices <- setNames(
      competitions$competition_id,
      competitions$competition_name
    )

    updateSelectInput(
      session,
      "competition_id",
      choices = competition_choices,
      selected = competitions$competition_id[1]
    )
  })

  observeEvent(input$competition_id, {
    req(input$competition_id)

    seasons <- competition_data %>%
      filter(
        competition_id == as.integer(input$competition_id)
      ) %>%
      distinct(
        season_id,
        season_name
      ) %>%
      arrange(desc(season_name))

    season_choices <- setNames(
      seasons$season_id,
      seasons$season_name
    )

    updateSelectInput(
      session,
      "season_id",
      choices = season_choices,
      selected = seasons$season_id[1]
    )
  })

  observeEvent(
    list(
      input$competition_id,
      input$season_id
    ),
    {
      req(
        input$competition_id,
        input$season_id
      )

      match_df <- get_matches_by_competition_shiny(
        con,
        competition_id = as.integer(
          input$competition_id
        ),
        season_id = as.integer(
          input$season_id
        )
      )
      req(nrow(match_df) > 0)
      match_labels <- paste0(
        match_df$match_date,
        " | ",
        match_df$home_team_name,
        " ",
        match_df$home_score,
        " - ",
        match_df$away_score,
        " ",
        match_df$away_team_name
      )

      match_choices <- setNames(
        match_df$match_id,
        match_labels
      )

      updateSelectInput(
        session,
        "match_id",
        choices = match_choices,
        selected = match_df$match_id[1]
      )
    },
    ignoreInit = FALSE
  )

  session$onSessionEnded(function() {
    if (DBI::dbIsValid(con)) DBI::dbDisconnect(con)
  })

  selected_match_id <- reactive({
    req(input$match_id)
    as.integer(input$match_id)
  })

  match_info <- reactive(get_match_info_shiny(con, selected_match_id()))
  team_summary <- reactive(get_match_summary_shiny(con, selected_match_id()))
  shots <- reactive(get_shots_shiny(con, selected_match_id()))
  match_events <- reactive(get_match_events_shiny(con, selected_match_id()))
  player_stats <- reactive(get_player_performance_shiny(
    con,
    selected_match_id()
  ))
  advanced_match <- reactive(get_advanced_match_metrics_shiny(
    con,
    selected_match_id()
  ))
  integrity_data <- reactive(get_integrity_signals_shiny(
    con,
    selected_match_id()
  ))

  home_team <- reactive(match_info()$home_team_name[1])
  away_team <- reactive(match_info()$away_team_name[1])

  output$team_filter_ui <- renderUI({
    teams <- c(home_team(), away_team())
    selectInput(
      "team_name",
      "Team for spatial analysis",
      choices = teams,
      selected = teams[1]
    )
  })

  observeEvent(
    player_stats(),
    {
      p <- player_stats()$player_name
      updateSelectInput(session, "player_name", choices = p, selected = p[1])
    },
    ignoreInit = FALSE
  )

  output$match_header <- renderUI({
    i <- match_info()

    div(
      class = "match-header",
      div(class = "match-kicker", "MATCH OVERVIEW"),
      h2(
        span(class = "home-name", i$home_team_name[1]),
        span(
          class = "score",
          paste0(" ", i$home_score[1], " – ", i$away_score[1], " ")
        ),
        span(class = "away-name", i$away_team_name[1])
      ),
      div(class = "text-muted", paste("Match date:", i$match_date[1]))
    )
  })

  get_team_value <- function(df, team, col, fallback = 0) {
    v <- df[df$team_name == team, col, drop = TRUE]
    if (length(v) == 0 || is.na(v[1])) fallback else v[1]
  }

  output$home_xg <- renderText({
    sprintf("%.2f", get_team_value(team_summary(), home_team(), "total_xg", 0))
  })

  output$away_xg <- renderText({
    sprintf("%.2f", get_team_value(team_summary(), away_team(), "total_xg", 0))
  })

  output$total_shots <- renderText({
    as.integer(sum(team_summary()$shots, na.rm = TRUE))
  })

  output$shots_on_target <- renderText({
    as.integer(sum(advanced_match()$shots_on_target, na.rm = TRUE))
  })

  output$home_pass_pct <- renderText({
    paste0(
      get_team_value(team_summary(), home_team(), "pass_completion", 0),
      "%"
    )
  })

  output$away_pass_pct <- renderText({
    paste0(
      get_team_value(team_summary(), away_team(), "pass_completion", 0),
      "%"
    )
  })

  output$progressive_passes <- renderText({
    as.integer(sum(advanced_match()$progressive_passes, na.rm = TRUE))
  })

  output$final_third_entries <- renderText({
    as.integer(sum(advanced_match()$final_third_entries, na.rm = TRUE))
  })

  output$home_xg_per_shot <- renderText({
    sprintf(
      "%.3f",
      get_team_value(advanced_match(), home_team(), "xg_per_shot", 0)
    )
  })

  output$away_xg_per_shot <- renderText({
    sprintf(
      "%.3f",
      get_team_value(advanced_match(), away_team(), "xg_per_shot", 0)
    )
  })

  output$home_shot_accuracy <- renderText({
    paste0(
      get_team_value(advanced_match(), home_team(), "shot_accuracy", 0),
      "%"
    )
  })

  output$away_shot_accuracy <- renderText({
    paste0(
      get_team_value(advanced_match(), away_team(), "shot_accuracy", 0),
      "%"
    )
  })

  output$team_summary <- renderDT({
    display_data <- team_summary() %>%
      transmute(
        Team = team_name,
        Shots = shots,
        xG = total_xg,
        Passes = passes,
        `Pass %` = pass_completion,
        Carries = carries,
        Pressures = pressures
      )

    datatable(
      display_data,
      rownames = FALSE,
      class = "compact hover",
      options = list(
        dom = "t",
        paging = FALSE,
        ordering = FALSE,
        autoWidth = TRUE
      )
    )
  })

  output$shot_map <- renderPlot({
    plot_shots_shiny(shots(), home_team(), away_team())
  })

  output$xg_timeline <- renderPlot({
    plot_xg_timeline(shots(), home_team(), away_team())
  })

  output$attacking_profile <- renderPlot({
    plot_attacking_profile(advanced_match(), home_team(), away_team())
  })

  output$player_table <- renderDT({
    datatable(
      player_stats(),
      rownames = FALSE,
      class = "compact hover",
      options = list(pageLength = 12, scrollX = TRUE)
    )
  })

  selected_player <- reactive({
    req(input$player_name)
    input$player_name
  })

  output$player_kpis <- renderUI({
    r <- player_stats()[
      player_stats()$player_name == selected_player(),
      ,
      drop = FALSE
    ]
    req(nrow(r) > 0)

    layout_columns(
      value_box("Shots", r$shots[1], class = "kpi-box"),
      value_box("xG", sprintf("%.2f", r$total_xg[1]), class = "kpi-box"),
      value_box("Passes", r$passes[1], class = "kpi-box"),
      value_box(
        "Pass completion",
        paste0(r$pass_completion[1], "%"),
        class = "kpi-box"
      ),
      col_widths = c(3, 3, 3, 3)
    )
  })

  output$player_map <- renderPlot(plot_player_events(
    match_events(),
    selected_player()
  ))
  output$player_shooting_plot <- renderPlot(plot_player_profile(
    player_stats(),
    selected_player()
  ))

  output$pass_map <- renderPlot({
    req(input$team_name)
    plot_pass_map(match_events(), input$team_name)
  })

  output$event_density <- renderPlot({
    req(input$team_name)
    plot_event_density(match_events(), input$team_name)
  })

  output$progressive_map <- renderPlot({
    req(input$team_name)
    plot_progressive_passes(match_events(), input$team_name)
  })

  output$final_third_map <- renderPlot({
    req(input$team_name)
    plot_final_third_entries(match_events(), input$team_name)
  })

  output$integrity_table <- renderDT({
    datatable(
      integrity_data()$signals,
      rownames = FALSE,
      class = "compact hover",
      options = list(dom = "t", paging = FALSE, ordering = FALSE)
    )
  })

  output$anomaly_score <- renderText(sprintf(
    "%.1f / 100",
    integrity_data()$score
  ))
  output$signal_level <- renderText(integrity_data()$level)

  output$largest_deviation <- renderText({
    x <- integrity_data()$signals
    if (nrow(x) == 0) {
      return("—")
    }
    paste0(x$team_name[1], " • ", x$metric[1], " • |z|=", x$abs_z[1])
  })

  output$integrity_plot <- renderPlot(plot_integrity_profile(
    integrity_data()$signals
  ))
}

shinyApp(ui, server)
