library(shiny)
library(dplyr)
library(leaflet)
library(countrycode)
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)

# Wczytaj dane
pdc <- read.csv("final_pdc_clean.csv", stringsAsFactors = FALSE)

# Korekta narodowości
pdc <- pdc %>%
  mutate(
    country_name = recode(Nationality,
                          "English"            = "United Kingdom",
                          "England"            = "United Kingdom",
                          "Scotland"           = "United Kingdom",
                          "Wales"              = "United Kingdom",
                          "Northern Ireland"   = "United Kingdom",
                          "Northern Irleand"   = "United Kingdom",
                          "Dutch"              = "Netherlands",
                          "German"             = "Germany",
                          "Irleand"            = "Ireland",
                          .default = Nationality
    ),
    iso_a3 = countrycode(country_name, origin = "country.name", destination = "iso3c")
  ) %>%
  filter(!is.na(iso_a3))

# Agregacja
country_summary <- pdc %>%
  group_by(iso_a3, country_name) %>%
  summarise(
    count = n(),
    top_players = paste(head(Player,5), collapse = ", "),
    .groups = "drop"
  )

# Pobierz mapę
world <- ne_countries(scale = "medium", returnclass = "sf")
world <- world %>%
  mutate(
    iso_a3 = case_when(
      admin == "France" ~ "FRA",
      admin == "Norway" ~ "NOR",
      admin == "Kosovo" ~ "XKX",  # Używany kod dla Kosowa
      TRUE ~ iso_a3  # Pozostaw pozostałe bez zmian
    )
  )
# Połącz z danymi
map_data <- world %>%
  left_join(country_summary, by = "iso_a3")

# UI
ui <- fluidPage(
  titlePanel("Map of Nationalities"),
  leafletOutput("map", height = "700px")
)

# Server
server <- function(input, output, session) {
  pal <- colorNumeric("YlOrRd", domain = map_data$count, na.color = "#eeeeee")
  
  output$map <- renderLeaflet({
    leaflet(map_data) %>%
      addTiles() %>%
      setView(lng = 0, lat = 30, zoom = 2) %>%
      addPolygons(
        fillColor = ~pal(count),
        weight = 1,
        color = "white",
        fillOpacity = 0.7,
        label  = ~paste0(
          country_name, " (", count, " players)",
          ifelse(!is.na(top_players), paste0("Top 5: ", top_players), "")
        ),
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "13px",
          direction = "auto"
        ),
        highlight = highlightOptions(
          weight = 2,
          color = "black",
          fillOpacity = 0.9,
          bringToFront = TRUE
        )
      ) %>%
      addLegend(pal = pal, values = ~count, title = "Number of Players")
  })
}

shinyApp(ui, server)
