# --- dart-analysis: start_from_order.R ---
# Sourcing strictly in the order listed in START_ORDER.txt, then launch app.

message("Starting from START_ORDER.txt …")

# 0) Project dir ----
.get_project_dir <- function() {
  d <- tryCatch(normalizePath(dirname(sys.frame(1)$ofile), winslash = "/"),
                error = function(e) NA_character_)
  if (is.na(d) || d == "") d <- normalizePath(getwd(), winslash = "/")
  d
}
proj_dir <- .get_project_dir()
setwd(proj_dir)
message("Project dir: ", proj_dir)

# 1) Optional renv ----
if (file.exists("renv.lock")) {
  message("Found renv.lock → renv::restore()")
  if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
  try({ renv::restore(prompt = FALSE) }, silent = TRUE)
}

# 2) Static resources (so images from www/ work) ----
if (dir.exists("www")) {
  if (!"static" %in% names(shiny::resourcePaths())) {
    shiny::addResourcePath("static", normalizePath("www"))
    message("Registered /static → ./www")
  }
}

# 3) Read START_ORDER.txt ----
order_file <- "START_ORDER.txt"
stopifnot(file.exists(order_file))
lines <- readLines(order_file, warn = FALSE)
lines <- trimws(lines)
lines <- lines[nzchar(lines) & !startsWith(lines, "#")]

# 4) Source strictly in that order ----
.source_safe <- function(f) {
  if (!file.exists(f)) stop("Missing file from START_ORDER.txt: ", f)
  message("source: ", f)
  source(f, chdir = TRUE, local = .GlobalEnv)
}
invisible(lapply(lines, .source_safe))

# 5) Launch strategy ----
# (A) If app.R exists, it likely calls shinyApp itself
if (file.exists("app.R")) {
  message("Running app.R …")
  source("app.R", chdir = TRUE)
  quit("no")
}

# (B) Try runApp('index.R') – this worked for you earlier
if (file.exists("index.R")) {
  message("Trying shiny::runApp('index.R') …")
  ok <- FALSE
  try({
    shiny::runApp("index.R")
    ok <- TRUE
  }, silent = TRUE)
  if (ok) quit("no")
  message("runApp('index.R') did not launch (will try other strategies).")
}

# (C) Try source('index.R') then auto-detect ui/server and launch
if (file.exists("index.R")) {
  message("Sourcing index.R …")
  try(source("index.R", chdir = TRUE), silent = TRUE)
}

ui_candidates     <- c("ui","app_ui","ui_main","ui2")
server_candidates <- c("server","app_server","server_main","server2")
for (u in ui_candidates) for (s in server_candidates) {
  if (exists(u, inherits = TRUE) && exists(s, inherits = TRUE)) {
    message(sprintf("Launching shinyApp(%s, %s)", u, s))
    shiny::shinyApp(get(u, inherits = TRUE), get(s, inherits = TRUE))
    quit("no")
  }
}

# (D) Last resort: compose from modules if present
if (exists("mod_apka_ui") && exists("mod_apka_server")) {
  message("Composing minimal navbar app from modules …")
  theme_try <- tryCatch(shinythemes::shinytheme("cerulean"), error = function(e) NULL)
  ui2 <- shiny::navbarPage(
    title = "Dart",
    theme = theme_try,
    tabPanel("Najważniejsze turnieje", mod_apka_ui("apka")),
    if (exists("mod_proba_ui"))   tabPanel("Statystyki Premier League", mod_proba_ui("proba")),
    if (exists("mod_jackpot_ui")) tabPanel("Kraje rankingu PDC", mod_jackpot_ui("jackpot"))
  )
  server2 <- function(input, output, session) {
    mod_apka_server("apka")
    if (exists("mod_proba_server"))   mod_proba_server("proba", df_koniczila = get0("koniczila", inherits = TRUE))
    if (exists("mod_jackpot_server")) mod_jackpot_server("jackpot")
  }
  shiny::shinyApp(ui2, server2)
  quit("no")
}

stop("Nie udało się uruchomić aplikacji po wykonaniu START_ORDER.txt.\nUpewnij się, że na końcu masz app.R lub index.R (z wywołaniem shinyApp/runApp), albo że tworzysz obiekty 'ui' i 'server'.")
