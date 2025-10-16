# dart-analysis — Quickstart & uruchomienie

Projekt startuje z pliku **`index.R`**, ale **najpierw** uruchom skrypty, które przygotowują środowisko (ścieżki, dane, cache).

---


## Start jednym poleceniem (bootstrap — opcjonalny plik `start.R`)
Możesz uruchamiać projekt jednym poleceniem, korzystając z pliku **`start.R`** (dołączony niżej).
W RStudio:
```r
source("start.R")
```
W terminalu:
```bash
Rscript start.R
```

---

## Struktura katalogów (propozycja)
```
dart-analysis/
├─ index.R
├─ start.R                # opcjonalny bootstrap (jeden plik do uruchomienia)
├─ renv.lock              # jeśli używasz renv
├─ scripts/
│  ├─ 00_init.R
│  ├─ 01_load_data.R
│  └─ 02_features.R
├─ data/
│  ├─ raw/                # surowe (lokalnie / zmaskowane sample w repo)
│  └─ processed/          # przetworzone (cache)
└─ app/                   # (opcjonalnie) moduły Shiny, UI/server
```

---

## Uwagi o środowisku i historii
- Uruchamianie nie zależy od `.RData` / `.Rhistory` — konfiguracja jest jawnie w `scripts/00_init.R`.
- `index.R` zakłada, że poprzednie skrypty utworzyły wymagane obiekty (np. tabele, słowniki).

---

## Najczęstsze problemy
- **Brak pakietu** → `renv::restore()` lub `install.packages("<pakiet>")`.
- **Ścieżki względne** → w `00_init.R` ustaw working dir lub używaj `here::here()`.
- **Dane prywatne** → w repo trzymaj sample/wersje zmaskowane; pełne pliki lokalnie.

---

## Opcjonalny plik `start.R` (dołącz do repo)
```r
message("Bootstrapping…")

# 1) renv (opcjonalnie)
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}
try({ renv::restore() }, silent = TRUE)

# 2) helper do bezpiecznego source z chdir
src <- function(path) if (file.exists(path)) source(path, chdir = TRUE)

# 3) skrypty przygotowujące środowisko
src("scripts/00_init.R")
src("scripts/01_load_data.R")
src("scripts/02_features.R")

# 4) główny start
if (file.exists("index.R")) {
  # jeśli index to Shiny app:
  if (requireNamespace("shiny", quietly = TRUE)) {
    # heurystycznie sprawdź, czy index uruchamia shiny lub zawiera ui/server
    txt <- tryCatch(readLines("index.R", warn = FALSE), error = function(e) "")
    has_shiny <- any(grepl("shinyApp\(|runApp\(|fluidPage\(|navbarPage\(", txt))
    if (has_shiny) {
      shiny::runApp("index.R")
    } else {
      source("index.R", chdir = TRUE)
    }
  } else {
    source("index.R", chdir = TRUE)
  }
} else {
  stop("Brak pliku index.R w katalogu głównym projektu.")
}
```
