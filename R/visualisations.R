library(ggplot2)
library(dplyr)


draw_pitch <- function() {
  
  ggplot() +
    # Outer boundaries
    annotate(
      "rect",
      xmin = 0, xmax = 120,
      ymin = 0, ymax = 80,
      fill = NA,
      colour = "black"
    ) +
    
    # Halfway line
    annotate(
      "segment",
      x = 60, xend = 60,
      y = 0, yend = 80
    ) +
    
    # Centre circle
    annotate(
      "path",
      x = 60 + 10 * cos(seq(0, 2 * pi, length.out = 200)),
      y = 40 + 10 * sin(seq(0, 2 * pi, length.out = 200))
    ) +
    
    # Centre spot
    annotate(
      "point",
      x = 60,
      y = 40,
      size = 1.5
    ) +
    
    # Left penalty area
    annotate(
      "rect",
      xmin = 0, xmax = 18,
      ymin = 18, ymax = 62,
      fill = NA
    ) +
    
    # Right penalty area
    annotate(
      "rect",
      xmin = 102, xmax = 120,
      ymin = 18, ymax = 62,
      fill = NA
    ) +
    
    # Left six-yard box
    annotate(
      "rect",
      xmin = 0, xmax = 6,
      ymin = 30, ymax = 50,
      fill = NA
    ) +
    
    # Right six-yard box
    annotate(
      "rect",
      xmin = 114, xmax = 120,
      ymin = 30, ymax = 50,
      fill = NA
    ) +
    
    coord_fixed(
      xlim = c(0, 120),
      ylim = c(0, 80)
    ) +
    
    theme_void()
}


plot_shot_map <- function(shots, team = NULL) {
  
  plot_data <- shots %>%
    filter(
      !is.na(x),
      !is.na(y),
      !is.na(shot_xg)
    )
  
  if (!is.null(team)) {
    plot_data <- plot_data %>%
      filter(team_name == team)
  }
  
  plot_data <- plot_data %>%
    mutate(
      is_goal = outcome == "Goal"
    )
  
  draw_pitch() +
    
    geom_point(
      data = plot_data,
      aes(
        x = x,
        y = y,
        size = shot_xg,
        shape = is_goal
      ),
      alpha = 0.75
    ) +
    
    scale_size_continuous(
      name = "xG",
      range = c(2, 10)
    ) +
    
    scale_shape_manual(
      name = "Outcome",
      values = c(
        `FALSE` = 1,
        `TRUE` = 16
      ),
      labels = c(
        `FALSE` = "No Goal",
        `TRUE` = "Goal"
      )
    ) +
    
    labs(
      title = ifelse(
        is.null(team),
        "Shot Map",
        paste("Shot Map -", team)
      ),
      subtitle = "Marker size proportional to StatsBomb xG"
    ) +
    
    theme(
      legend.position = "bottom",
      plot.title = element_text(
        face = "bold",
        size = 16
      ),
      plot.subtitle = element_text(
        size = 10
      )
    )
}