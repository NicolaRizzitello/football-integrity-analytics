# Football Integrity Analytics — Shiny V5

Complete dashboard code.

## What changed

- full `app.R`
- fixed KPI scientific-notation issue
- larger logo
- professional navy header
- white sidebar
- stronger home/away visual identity
- 12 KPI cards in Overview
- cleaner DataTables
- unified ggplot2 palette
- improved shot map
- improved xG timeline
- labels on attacking-profile bars
- polished player/spatial/integrity charts
- portfolio disclaimer in sidebar

## Required packages

```r
install.packages(c(
  "shiny",
  "bslib",
  "bsicons",
  "DT",
  "DBI",
  "RPostgres",
  "dplyr",
  "ggplot2",
  "viridis",
  "tidyr",
  "scales"
))
```

## Files

Copy the contents of this package over your current:

```text
football-integrity-analytics/shiny/
├── app.R
├── R/
│   ├── db.R
│   ├── data.R
│   ├── metrics.R
│   └── plots.R
└── www/
    └── custom.css
```

Keep your existing logo as:

```text
shiny/www/uefa-logo.png
```

Then run:

```r
setwd("C:/Users/Nicola/Desktop/football-integrity-analytics/shiny")
shiny::runApp()
```

## Notes

The dashboard uses:
- Home team: coral/red
- Away team: teal
- Integrity navy: dark blue

Integrity signals remain exploratory flags for analyst review and are not evidence of match manipulation.


## V5.1 layout fix

This build changes the dashboard to normal document flow:

- `page_sidebar(fillable = FALSE)`
- `navset_card_tab(fillable = FALSE)`
- fixed-height, readable KPI cards (`124px`)
- vertical spacing between KPI rows and analytical sections
- normal browser vertical scrolling
- no viewport-height compression
- fixes `small()` by using a styled `span`

The result is intentionally a longer dashboard page: scroll down naturally to reach the
comparison tables and ggplot2 visualisations instead of compressing all content into one screen.
