# dart-analysis — Quickstart & uruchomienie

Projekt startuje z pliku **`index.R`**, ale **najpierw** uruchom skrypty, które przygotowują środowisko (ścieżki, dane, cache).
Poniżej masz gotowe kroki do README oraz opcjonalny „bootstrap” `start.R`, który robi to wszystko jednym poleceniem.

---

## Wymagania
- R ≥ 4.2
- (Zalecane) RStudio
- Pakiety z `renv.lock` (jeśli używasz renv) lub ręcznie doinstalowane

---

## 1) Klon repozytorium
```bash
git clone https://github.com/SatukerRekiner/dart-analysis.git
cd dart-analysis
```

## 2) (Opcjonalnie) Odtwórz środowisko pakietów przez renv
```r
install.packages("renv")
renv::restore()   # przywraca dokładne wersje pakietów
```
> Jeśli nie używasz renv, zainstaluj brakujące pakiety zwykłym `install.packages()`.

## 3) Przygotuj środowisko (skrypty inicjalizujące)
W RStudio (lub R):
```r
source("scripts/00_init.R")       # konfiguracja: ścieżki, seedy, helpery
source("scripts/01_load_data.R")  # wczytanie i czyszczenie danych
source("scripts/02_features.R")   # (opcjonalnie) transformacje/feature engineering
```
Te skrypty tworzą obiekty i pamięć podręczną tak, aby **`index.R`** miał wszystko „na gotowo”.

## 4) Start głównego pliku
```r
source("index.R")
# albo jeśli to Shiny:
# shiny::runApp("index.R")
```

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
