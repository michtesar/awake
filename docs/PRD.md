# Awake — Product Requirements Document (PRD)

## 1) Vize produktu
Awake je ultralehká menu bar aplikace pro macOS, která udržuje Mac v bdělosti pomocí několika pečlivě vybraných režimů. Cíl je „neviditelný“ produkt: okamžitě pochopitelný, bez zbytečných voleb, s estetikou nativní pro macOS 26 a stylem liquid glass.

## 2) Produktové cíle
- Umožnit zapnout „stay awake“ během 1 kliknutí z menu baru.
- Nabídnout jen několik rozumných presetů místo plné konfigurace.
- Být trvale dostupný po startu systému, bez ikony v Docku.
- Udržet konzistentní, čistý a prémiový vizuální jazyk.
- Spotřebovat minimální CPU/RAM a běžet stabilně dlouhodobě.

## 3) Co produkt není (non-goals)
- Není to automatizační nástroj s desítkami pravidel.
- Není to appka pro správu energetických profilů celého systému.
- Není cílem podporovat desítky edge-case voleb v UI.

## 4) Cílový uživatel
- Profesionál, který často sdílí obrazovku, prezentuje, renderuje, stahuje data nebo monitoruje procesy.
- Uživatel preferující nativní Apple UX bez onboarding složitosti.

## 5) Klíčové use-cases
- „Začínám meeting“ -> zapnu Awake na 1 hodinu.
- „Spouštím delší úlohu“ -> zapnu Awake „Until turned off“.
- „Jdu pryč od Macu“ -> jedním klikem vypnu Awake.

## 6) UX principy
- One-glance stav: uživatel vždy ihned vidí, zda je Awake aktivní.
- One-click akce: hlavní akce musí být max. 1 klik z menu baru.
- Progressive disclosure: pokročilé volby jen v Settings, ne v hlavním flow.
- Nativní microcopy: krátké, jednoznačné texty.

## 7) Informační architektura
### 7.1 Menu bar položka
- Ikona stavu:
  - Idle: neutrální (např. moon.zzz / cup-and-saucer)
  - Active: zvýrazněná (např. cup-and-saucer.fill)
- Volitelně text vedle ikony pouze při aktivním časovači (např. „24m“).

### 7.2 Menu obsah
- Sekce `Quick Start`
  - `Keep Awake for 30 minutes`
  - `Keep Awake for 1 hour`
  - `Keep Awake for 4 hours`
  - `Keep Awake until turned off`
- Sekce `Current Session` (zobrazená jen při aktivním režimu)
  - Stav + zbývající čas
  - `Stop`
- Sekce `Preferences`
  - `Launch at Login` (toggle)
  - `Show Remaining Time in Menu Bar` (toggle)
- Sekce `App`
  - `About Awake`
  - `Quit`

## 8) Funkční požadavky
### FR-1: Spuštění režimu bdělosti
- Uživatel může spustit 4 presety: 30m / 1h / 4h / until off.
- Aktivace je okamžitá bez potvrzovacího dialogu.

### FR-2: Ukončení režimu bdělosti
- Uživatel může aktivní režim kdykoliv ukončit přes `Stop`.
- Po vypršení časového limitu se režim ukončí automaticky.

### FR-3: Stavová signalizace
- Menu bar ikona vždy reflektuje aktivní/neaktivní stav.
- Při timed režimu je volitelně zobrazován countdown.

### FR-4: Launch at Login
- Aplikace umí registrovat běh po přihlášení uživatele.
- Stav preference je per-user a per-device.

### FR-5: Menu bar only
- Aplikace neběží v Docku a nemá hlavní permanentní okno.
- Primární interakce je výhradně přes menu bar.

### FR-6: Stabilita session
- Aplikace obnoví interní stav po restartu aplikace korektně:
  - Pokud byla aktivní timed session a čas již vypršel -> session se neobnovuje.
  - Pokud byl aktivní „until off“ režim -> session se obnoví jako aktivní.

## 9) Nefunkční požadavky
- Start aplikace do 300 ms (cold start cíl).
- Idle CPU téměř 0 %, paměťový footprint nízký (řádově desítky MB).
- Žádný síťový provoz v běžném provozu.
- Lokální-first, bez telemetrie ve v1.

## 10) Design systém (macOS 26, liquid glass)
- Použít nativní material vrstvy (`.regularMaterial` / odpovídající AppKit material) konzistentně.
- Preferovat SF Symbols a systémovou typografii pro nativní čitelnost.
- Vysoký kontrast stavů active vs idle bez agresivních barev.
- Jemné animace (100-180ms) pouze pro přechod stavů a countdown refresh.
- Žádné custom „ornamenty“ které porušují menu bar minimalismus.

## 11) Technická architektura
### 11.1 Stack
- Swift 6 + SwiftUI App lifecycle
- Menu bar shell: `MenuBarExtra`
- Integrace bdělosti: `caffeinate` proces orchestrace (v1)
- Settings persistence: `UserDefaults` (`@AppStorage`)
- Launch at login: `SMAppService.mainApp`

### 11.2 Core komponenty
- `AwakeApp` (entry point, menu bar scéna)
- `AwakeSessionManager` (single source of truth pro stav session)
- `CaffeinateController` (start/stop a monitoring subprocessu)
- `LoginItemManager` (registrace launch at login)
- `PreferencesStore` (app storage klíče)

### 11.3 Stavový model
- `AwakeMode`
  - `.timed(duration: TimeInterval)`
  - `.indefinite`
- `AwakeState`
  - `.inactive`
  - `.active(mode: AwakeMode, startedAt: Date, endsAt: Date?)`

### 11.4 Strategie `caffeinate`
- V1 použít `/usr/bin/caffeinate` přes `Process`.
- Doporučené flagy pro user scénáře:
  - `-d` zabránění usnutí displeje
  - `-i` zabránění idle sleep systému
  - `-m` zabránění disk idle sleep
- Timed režim:
  - použít `-t <seconds>` + fail-safe timer v appce.
- Indefinite režim:
  - běh bez `-t`, ukončení přes terminate procesu.

Poznámka: V2 lze zvážit přechod na přímé IOKit assertions (`IOPMAssertionCreateWithName`) pro hlubší kontrolu a méně procesního overheadu.

## 12) Chování při chybách
- Pokud `caffeinate` nejde spustit:
  - Session se nepřepne do active.
  - Uživatel dostane nenásilnou chybu v menu (`Unable to start Awake`).
- Pokud proces nečekaně skončí:
  - Stav se resetuje na inactive.
  - Volitelně jednorázová notifikace (v1 lze vypnout).

## 13) Bezpečnost a soukromí
- Bez sběru osobních dat.
- Bez externích API.
- Žádné elevated privileges.

## 14) Přístupnost
- VoiceOver labels pro všechny menu položky.
- Smysluplné textové popisy stavových ikon.
- Kontrast ověřen pro Light i Dark appearance.

## 15) Lokalizace
- v1: angličtina.
- v1.1: čeština + další jazyky přes String Catalog.

## 16) Metriky úspěchu (v1)
- Time-to-awake (klik -> aktivní stav) < 200 ms.
- Crash-free sessions > 99.9 %.
- 80 %+ uživatelů používá Quick Start bez otevření Settings.

## 17) Release plán
### Milestone A — Functional Core (2-3 dny)
- SessionManager + CaffeinateController
- MenuBarExtra se 4 presety + stop
- Stabilní stav a countdown

### Milestone B — Native polish (1-2 dny)
- Visual polish (material, spacing, micro-animace)
- Launch at login toggle
- About/Preferences panel

### Milestone C — Hardening (1-2 dny)
- Edge-cases: restart app, crash recovery, race conditions
- Jednotkové testy core logiky + smoke UI test

## 18) Akceptační kritéria (Definition of Done)
- Aplikace běží bez Dock ikony a ovládá se z menu baru.
- Všechny 4 presety fungují konzistentně.
- `Stop` vždy okamžitě ukončí aktivní session.
- Launch at login je funkční a perzistentní.
- UI je nativní, čisté a bez přeplnění.
- Základní testy pro session přechody procházejí.

## 19) Návrh implementačního postupu pro tento repozitář
1. Přepnout app na menu bar only (`MenuBarExtra`, `LSUIElement=YES`).
2. Přidat doménové modely (`AwakeMode`, `AwakeState`) a `AwakeSessionManager`.
3. Implementovat `CaffeinateController` s robustním start/stop a observací procesu.
4. Napojit menu akce na session manager + countdown render.
5. Přidat `SMAppService.mainApp` toggle pro launch at login.
6. Vyladit UI detaily a stavy chyb.
7. Dopsat unit testy pro session transitions.

## 20) Otevřené produktové volby (doporučení)
- Zda zobrazovat zbývající čas přímo v menu baru jako default (doporučení: ON).
- Zda v1 zahrnout notifikaci při vypršení timed režimu (doporučení: OFF, aby app zůstala „tichá“).
- Zda přidat preset 2 hodiny (doporučení: zatím NE, držet 4 presety).
