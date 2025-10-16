# Load packages
library(shiny)
library(dplyr)
library(leaflet)
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)

pdc2021 <- read.csv("pdc2021.csv")
pdc2022 <- read.csv("pdc2022.csv")
pdc2023 <- read.csv("pdc2023.csv")
pdc2024 <- read.csv("pdc2024.csv")
pdc2025 <- read.csv("pdc2025.csv")


# Helper: read and prepare one year (expecting ISO only)
dprepare <- function(file) {
  pdc <- read.csv(file, stringsAsFactors = FALSE)
  # Expect column: iso_a3, Player
  pdc <- pdc %>%
    filter(!is.na(iso_a3)) %>%
    group_by(iso_a3) %>%
    summarise(
      count = n(),
      top_players = paste(head(Player, 5), collapse = ", "),
      .groups = "drop"
    )
  return(pdc)
}

# Preload data summaries per year
years <- 2021:2025
pdc_summary_list <- lapply(years, function(y) {
  file <- paste0("pdc", y, ".csv")
  ds <- dprepare(file)
  names(ds)[names(ds) == "count"] <- paste0("count_", y)
  names(ds)[names(ds) == "top_players"] <- paste0("top_players_", y)
  ds
})
names(pdc_summary_list) <- as.character(years)

# Load world map
world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  mutate(
    iso_a3 = case_when(
      admin == "France"  ~ "FRA",
      admin == "Norway"  ~ "NOR",
      admin == "Kosovo"  ~ "XKX",
      TRUE ~ iso_a3
    )
  )


mod_jackpot_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
  titlePanel("Mapa narodowości zawodników w rankingu PDC"),
  sidebarLayout(
    sidebarPanel(
      radioButtons(
        inputId = ns("year"),
        label   = "Wybierz rok:",
        choices = as.character(years),
        selected = "2025",
        inline = TRUE
      )
    ),
    mainPanel(
      leafletOutput(ns("map"), height = "700px")
    )
  )
)
}

mod_jackpot_server <- function(id) {
  moduleServer(id, function(input, output, session) {
  # Reactive merged data for selected year
  map_data <- reactive({
    sel <- pdc_summary_list[[input$year]]
    sel <- sel %>%
      rename(
        count = paste0("count_", input$year),
        top_players = paste0("top_players_", input$year)
      )
    # join with world to get country_name
    world %>%
      left_join(sel, by = "iso_a3")
  })
  
  output$map <- renderLeaflet({
    df <- map_data()
    pal <- colorNumeric("YlOrRd", domain = df$count, na.color = "#eeeeee")
    df <- df %>%
      mutate(
        count = case_when(
          is.na(count) ~ 0,
          TRUE ~ count
        )
      ) %>% 
    leaflet() %>%
      addTiles() %>%
      setView(lng = 0, lat = 30, zoom = 2) %>%
      addPolygons(
        fillColor = ~pal(count),
        weight = 1,
        color = "white",
        fillOpacity = 0.7,
        popup = ~paste0(
          "<b>", admin, "</b> (", count, " ",
          ifelse(count == 1, "player", "players"), ")",
          ifelse(!is.na(top_players) & top_players != "", 
                 paste0(ifelse(count>=5,"<br><b>Top 5:</b> ",paste0("<br><b>Top ",count,":</b> ")), top_players), 
                 "")
        ),
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "13px",
          direction = "auto",
          html = TRUE
        ),
        highlight = highlightOptions(
          weight = 2,
          color = "black",
          fillOpacity = 0.9,
          bringToFront = TRUE
        )
      ) %>%
      addLegend(pal = pal, values = ~count, title = paste("Liczba graczy w", input$year))
  })
  })
  }

shinyApp(ui, server)
