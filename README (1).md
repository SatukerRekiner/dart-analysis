# dart-analysis — opis projektu i uruchomienie

Aplikacja prezentuje **analizy turniejów darta** (PDC) w formie interaktywnego dashboardu (Shiny).
Zawiera m.in.:
- przegląd **najważniejszych turniejów** i ich **sum nagród** w latach,
- **statystyki Premier League** (wraz z wizualizacją „tarczy”),
- przegląd **krajów w rankingu PDC**.

Projekt jest zaprojektowany do oglądania w **przeglądarce** (nie w Viewerze RStudio). W Viewerze niektóre elementy mogą nie wyglądać idealnie — to normalne.

---

## Spis treści
- [Struktura repozytorium](#struktura-repozytorium)  
- [Dane i ich rola](#dane-i-ich-rola)  
- [Zakładki (co zobaczysz w aplikacji)](#zakładki-co-zobaczysz-w-aplikacji)  
- [Wymagania](#wymagania)  
- [Szybki start (zalecane)](#szybki-start-zalecane)  
- [Alternatywny start](#alternatywny-start)  
- [Najczęstsze problemy i rozwiązania](#najczęstsze-problemy-i-rozwiązania)  
- [Zrzuty ekranu (opcjonalnie)](#zrzuty-ekranu-opcjonalnie)  
- [Licencja](#licencja)

---

## Struktura repozytorium

```
dart-analysis/
├─ index.R                 # plik główny/host aplikacji (wykrywany przez starter)
├─ apka.R                  # moduł „Najważniejsze turnieje”
├─ proba.r                 # moduł „Statystyki Premier League”
├─ JACKPOT.r               # moduł „Kraje rankingu PDC”
├─ start_from_order_lenient.R   # starter: wczytuje pliki wg START_ORDER.txt i uruchamia app
├─ START_ORDER.txt              # KOLEJNOŚĆ plików do wczytania (jeden na linię)
├─ www/                    # zasoby statyczne (ikony turniejów, tarcza, itp.)
│  ├─ icon1.jpg ... icon9.jpg
│  └─ dartboard.png
├─ dane/ lub data/         # pliki danych (CSV/XLSX) – nazwy mogą się różnić
│  ├─ nagrody.xlsx
│  ├─ ogladalnosc.xlsx
│  └─ zwyciezcy.xlsx
└─ (opcjonalnie) scripts/  # skrypty przygotowujące środowisko/transformacje
```

> Jeśli trzymasz dane w innym folderze, upewnij się, że ścieżki w kodzie do nich wskazują poprawnie.

---

## Dane i ich rola

- **`nagrody.xlsx`** – sumy nagród w turniejach w latach (kolumny: `Year`, + kolumny z nazwami turniejów).  
- **`ogladalnosc.xlsx`** – m.in. `Peak_viewership` do wykresu oglądalności (Premier League / WDC).  
- **`zwyciezcy.xlsx`** – listy zwycięzców (wykorzystywane do wyświetlania tekstowych zestawień).

> Format/zakres mogą być zaktualizowane – ważne, aby kolumny używane w kodzie istniały (np. `Year`, nazwy turniejów zgodne z wektorem `tournaments`, `Peak_viewership`).

---

## Zakładki (co zobaczysz w aplikacji)

### 1) Najważniejsze turnieje
- **Siatka 9 ikon** (w `www/icon*.jpg`) reprezentujących turnieje z wektora:
  ```
  c("World Darts Championship","UK Open","World Matchplay","World Grand Prix",
    "Grand Slam of Darts","Players Championship Finals","European Championship",
    "World Masters","Premier League Darts")
  ```
- Po kliknięciu ikony wyświetla się **wykres sum nagród** dla wybranego turnieju (punkty + linia, oś X = `Year`).
- Dla **ikony nr 1** (WDC) pojawia się dodatkowo panel:
  - **tekst** (lista zwycięzców z `zwyciezcy.xlsx`),
  - **wykres oglądalności** z `ogladalnosc.xlsx` (`Peak_viewership`).

### 2) Statystyki Premier League
- Wczytuje/prezentuje dane specyficzne dla Premier League (m.in. **„tarcza”** – grafika w `www/dartboard.png`).  
- Wykresy/tekst bazują na obiekcie danych przygotowanym przy starcie (np. `koniczila` lub jego odpowiednik przekazany do modułu).

### 3) Kraje rankingu PDC
- Zestawienia/wykresy na poziomie krajów (np. suma punktów, liczba graczy, itp.).  
- Widoki tabelaryczne/wykresowe zależnie od danych.

---

## Wymagania
- **R ≥ 4.2**  
- **RStudio** (zalecane)  
- Pakiety: `shiny`, `shinythemes`, `dplyr`, `tidyr`, `ggplot2`, `plotly`, `readxl`  
  (jeśli używasz `renv`, to `renv::restore()` odtworzy dokładne wersje)

---

## Szybki start (zalecane)

1) **Klon repo**:
```bash
git clone https://github.com/SatukerRekiner/dart-analysis.git
cd dart-analysis
```

2) **Upewnij się, że dane i obrazy są na miejscu**  
   - `www/icon1.jpg ... icon9.jpg`, `www/dartboard.png`  
   - pliki `*.xlsx` (`nagrody.xlsx`, `ogladalnosc.xlsx`, `zwyciezcy.xlsx`) w oczekiwanej lokalizacji (patrz kod)

3) **Ustal kolejność plików do wczytania**  
   Otwórz **`START_ORDER.txt`** i ustaw **kolejność**, w jakiej *Ty ręcznie* odpalasz pliki (po jednym na linię), np.:
   ```
   apka.R
   proba.r
   JACKPOT.r
   ```
   > **Nie dodawaj** tutaj `index.R` / `app.R` – starter sam je spróbuje uruchomić na końcu.

4) **Uruchom starter** (w RStudio z katalogu projektu):
```r
source("start_from_order_lenient.R")
```
Starter:
- **wczyta pliki dokładnie wg `START_ORDER.txt`** (brakujące pliki tylko **ostrzega**, nie przerywa),
- zarejestruje `/static → ./www` (żeby obrazki działały w przeglądarce),
- spróbuje uruchomić aplikację w tej kolejności:
  1) `app.R` (jeśli istnieje),
  2) `shiny::runApp("index.R")`,
  3) `source("index.R")` i automatyczne `shinyApp(ui, server)` (jeśli wykryje parę obiektów),
  4) ostatecznie — złoży minimalną aplikację z modułów `apka/proba/jackpot`.

**Uwaga:** Otwieraj w **przeglądarce** („Open in Browser”), nie w RStudio Viewer.

---

## Alternatywny start
Jeśli nie chcesz używać `START_ORDER.txt`, możesz ręcznie:
```r
# 1) (opcjonalnie) renv
# install.packages("renv"); renv::restore()

# 2) wczytaj pliki, których potrzebujesz:
source("apka.R")
source("proba.r")
source("JACKPOT.r")

# 3) uruchom host:
source("index.R")               # jeśli index.R sam odpala Shiny
# lub
# shiny::runApp("index.R")      # jeśli index.R jest app-skryptem
# lub
# shinyApp(ui, server)          # jeśli index.R definiuje obiekty ui/server
```

---

## Najczęstsze problemy i rozwiązania

**1) Obrazki ikon/tarczy się nie ładują (404):**  
- Pliki są w `www/` (np. `www/icon1.jpg`, `www/dartboard.png`).  
- W UI odwołujesz się do nich jako `src = "icon1.jpg"` lub (jeśli alias) `src = "static/icon1.jpg"`.  
- Starter rejestruje alias `/static → ./www`.  
- Jeśli deploy (np. shinyapps.io) – `www/` musi być w katalogu aplikacji, który wysyłasz.

**2) Błąd: „nie wybrano kolumn” / „brak obiektu” (`koniczila`):**  
- Oznacza, że **plik, który tworzy ten obiekt, nie został wczytany** przed startem.  
- Dodaj go wyżej w **`START_ORDER.txt`** (kolejność ma znaczenie).  
- W module możesz dopisać defensywkę `validate(need(...))`, aby UI nie „wysadzało” całej zakładki.

**3) W Viewerze RStudio layout wygląda inaczej:**  
- To oczekiwane. Otwórz w **pełnej przeglądarce**.

---

## Zrzuty ekranu (opcjonalnie)

Wstaw tu 1–3 obrazki (folder `www/` + odwołanie względne lub URL):

```markdown
![Najważniejsze turnieje](www/screenshot_turnieje.png)
![Premier League – tarcza](www/screenshot_tarcza.png)
```

---

## Licencja
Wstaw tutaj wybraną licencję (np. MIT).
