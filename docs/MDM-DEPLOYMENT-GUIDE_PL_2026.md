<p align="left">
  <a href="https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇬🇧 English</a> |
  <a href="https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_PL_2026.md">🇵🇱 Polski</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=de&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇩🇪 Deutsch</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=fr&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇫🇷 Français</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=es&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇪🇸 Español</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=pt&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇧🇷 Português</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=nl&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇳🇱 Nederlands</a>
  <br>
  <a href="https://translate.google.com/translate?sl=en&tl=zh-CN&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇨🇳 中文</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=ja&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇯🇵 日本語</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=ko&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇰🇷 한국어</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=it&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇮🇹 Italiano</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=tr&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇹🇷 Türkçe</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=ar&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇸🇦 العربية</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=hi&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇮🇳 हिन्दी</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=ru&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇷🇺 Русский</a>
</p>

## Wdrażanie Universal Intel Wi-Fi and Bluetooth Drivers Updater za pomocą MDM

Zarządzanie aktualizacjami sterowników Intel Wi-Fi i Bluetooth w całej flocie komputerów oznaczało do tej pory albo poleganie na tym, że Windows Update w końcu dostarczy właściwą wersję, albo ręczną obsługę każdego urządzenia. Dzięki flagom `-quiet` i `-auto` wprowadzonym w wersji v2026.03.0002, **Universal Intel Wi-Fi and Bluetooth Drivers Updater** w pełni nadaje się do cichego, bezobsługowego wdrażania za pośrednictwem dowolnej platformy MDM w przedsiębiorstwie.

Ten przewodnik opisuje wdrażanie dla **Microsoft Intune**, **Microsoft SCCM / Configuration Manager**, **VMware Workspace ONE** i **PDQ Deploy** — z użyciem aktualnego wydania w momencie pisania tego tekstu.

---

### Wymagania wstępne (dla wszystkich platform)

Przed wdrożeniem za pomocą dowolnego rozwiązania MDM, sprawdź następujące elementy na komputerach docelowych:

- **Windows 10 build 17763 (LTSC 2019) lub nowszy** — wymagany do pełnej obsługi TLS 1.2 od razu po instalacji
- **.NET Framework 4.7.2 lub nowszy** — wymagany do łączności z GitHub i weryfikacji skrótów (hashy)
- **Uprawnienia administratora** — skrypt automatycznie podnosi swoje uprawnienia, ale kontekst wdrożenia musi już działać jako SYSTEM lub lokalne konto administratora
- **Dostęp do Internetu (GitHub)** — skrypt pobiera pakiety CAB ze sterownikami i weryfikuje skróty z `raw.githubusercontent.com` i zasobów wydań GitHub; upewnij się, że nie są one blokowane przez twoje proxy lub zaporę sieciową
- **Zasady wykonywania PowerShell** — flaga `-ExecutionPolicy Bypass` w poleceniu uruchomieniowym rozwiązuje tę kwestię; nie jest wymagana żadna zmiana zasad na komputerze docelowym

**Zalecane polecenie uruchomieniowe dla wszystkich wdrożeń MDM:**
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SystemRoot%\Temp\IntelWiFiBT\universal-intel-wifi-bt-driver-updater.ps1" -quiet
```

> **Uwaga:** `-quiet` implikuje `-auto` i wycisza wszystkie dane wyjściowe konsoli. Pełny dziennik instalacji jest zawsze zapisywany w `%ProgramData%\wifi_bt_update.log` niezależnie od trybu cichego — użyj go do weryfikacji wdrożenia.

---

### Microsoft Intune

Intune obsługuje dwie praktyczne metody wdrażania tego narzędzia: jako **aplikację Win32** (zalecane) lub za pomocą **zasad skryptów PowerShell**.

#### Metoda A: Aplikacja Win32 (zalecana)

Ta metoda zapewnia pełne reguły wykrywania, filtry przypisań i raportowanie.

**1. Przygotuj pakiet**

Pobierz najnowszy plik wykonywalny SFX ze [strony Releases](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases):
```
WiFiBTUpdater-2026.03.0002-Win10-Win11.exe
```

Utwórz skrypt opakowujący `install.cmd`, który uruchomi SFX w trybie cichym — SFX rozpakowuje pliki do `%SystemRoot%\Temp\IntelWiFiBT\` i automatycznie uruchamia plik PS1 z flagą `-quiet`:
```batch
WiFiBTUpdater-2026.03.0002-Win10-Win11.exe
```

> Pakiet SFX jest wstępnie skonfigurowany do rozpakowania i uruchomienia `universal-intel-wifi-bt-driver-updater.ps1 -quiet` automatycznie. Dodatkowy skrypt opakowujący nie jest potrzebny, chyba że chcesz dodać niestandardowe akcje przed lub po instalacji.

**2. Spakuj jako plik .intunewin**

Użyj [narzędzia Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool):
```
IntuneWinAppUtil.exe -c "C:\Package" -s "WiFiBTUpdater-2026.03.0002-Win10-Win11.exe" -o "C:\Output"
```

**3. Utwórz aplikację Win32 w Intune**

- Przejdź do **centrum administracyjnego Intune** → **Aplikacje** → **Windows** → **Dodaj** → **Aplikacja Windows (Win32)**
- Prześlij plik `.intunewin`
- Ustaw **Polecenie instalacji**:
  ```
  WiFiBTUpdater-2026.03.0002-Win10-Win11.exe
  ```
- Ustaw **Polecenie odinstalowania** (odinstalowanie nie jest potrzebne — sterowniki są zarządzane przez system Windows):
  ```
  cmd.exe /c echo Nie wymaga odinstalowania
  ```
- **Zachowanie podczas instalacji**: `System`
- **Zachowanie przy ponownym uruchomieniu urządzenia**: `Określ zachowanie na podstawie kodów powrotu`
  - Dodaj kod powrotu `3010` → `Miękki restart` (na wypadek, gdyby Windows oznaczył oczekujący restart po instalacji sterownika)

**4. Reguła wykrywania**

Użyj reguły wykrywania opartej na **Pliku** dla dziennika:
- **Ścieżka**: `C:\ProgramData`
- **Plik**: `wifi_bt_update.log`
- **Metoda wykrywania**: Plik lub folder istnieje

Lub użyj reguły wykrywania opartej na **Rejestrze**, aby sprawdzić, czy dziennik został zapisany (potwierdzając, że skrypt został uruchomiony):
- **Ścieżka klucza**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion`
- **Nazwa wartości**: *(pozostaw puste — wykrywaj tylko istnienie klucza)*

**5. Przypisz i wdróż**

Przypisz do grupy urządzeń. Do testów pilotażowych użyj najpierw **Przypisane** do grupy testowej, a następnie wdróż do szerszych grup poprzez **Dostępne** lub **Wymagane**.

---

#### Metoda B: Zasady skryptów PowerShell

Prostsza, ale z mniejszą szczegółowością raportowania. Użyj tej metody do szybkich wdrożeń.

- Przejdź do **centrum administracyjnego Intune** → **Urządzenia** → **Skrypty i korekty** → **Skrypty platformy** → **Dodaj** → **Windows 10 i nowsze**
- Prześlij bezpośrednio plik `universal-intel-wifi-bt-driver-updater.ps1`
- Ustawienia:
  - **Uruchom ten skrypt przy użyciu poświadczeń zalogowanego użytkownika**: `Nie` (uruchom jako SYSTEM)
  - **Wymuszaj sprawdzanie podpisu skryptu**: `Nie`
  - **Uruchom skrypt w 64-bitowym hoście PowerShell**: `Tak`
- Przypisz do grupy urządzeń

> **Ograniczenie:** Skrypty PowerShell w Intune mają domyślny limit czasu. W przypadku systemów, które tworzą duże punkty przywracania lub mają wolne dyski, całkowity czas wykonania może przekroczyć 10 minut. W przypadku przekroczenia limitu czasu przełącz się na metodę A (aplikacja Win32), która ma konfigurowalny limit czasu.

---

### Microsoft SCCM / Configuration Manager

SCCM oferuje największą kontrolę nad targetowaniem, harmonogramowaniem i raportowaniem zgodności.

#### 1. Utwórz pakiet

- W **konsoli Configuration Manager** przejdź do **Biblioteka oprogramowania** → **Zarządzanie aplikacjami** → **Pakiety** → **Utwórz pakiet**
- **Nazwa**: `Universal Intel Wi-Fi and BT Drivers Updater v2026.03.0002`
- **Folder źródłowy**: Wskaż udział sieciowy zawierający plik `WiFiBTUpdater-2026.03.0002-Win10-Win11.exe`
- Utwórz **Program standardowy** z:
  - **Wiersz polecenia**:
    ```
    WiFiBTUpdater-2026.03.0002-Win10-Win11.exe
    ```
  - **Uruchom**: `Ukryty`
  - **Program może być uruchomiony**: `Niezależnie od tego, czy użytkownik jest zalogowany`
  - **Uruchom z uprawnieniami administracyjnymi**: ✅ zaznaczone

#### 2. Alternatywnie — wdróż bezpośrednio plik PS1

Jeśli wolisz wdrożyć skrypt bez opakowania SFX:

- Umieść `universal-intel-wifi-bt-driver-updater.ps1` w swoim punkcie dystrybucji
- Ustaw **Wiersz polecenia** na:
  ```
  powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "universal-intel-wifi-bt-driver-updater.ps1" -quiet
  ```
- **Uruchom**: `Ukryty`
- **Program może być uruchomiony**: `Niezależnie od tego, czy użytkownik jest zalogowany`

#### 3. Dystrybucja i wdrożenie

- **Rozpowszechnij zawartość** do swoich punktów dystrybucji
- **Wdróż** do kolekcji urządzeń
  - **Cel**: `Wymagane` dla obowiązkowego wdrożenia, `Dostępne` dla samoobsługi
  - **Harmonogram**: Ustaw okno konserwacji, jeśli chcesz kontrolować czas (zalecane — skrypt tworzy punkt przywracania, co może być intensywne dla operacji we/wy, a połączenie Wi-Fi zostanie krótko przerwane podczas instalacji sterownika)
  - **Doświadczenie użytkownika** → **Zezwalaj klientom na uruchamianie oprogramowania niezależnie od przypisań**: zależy od twojej polityki
  - **Kody powrotu**: Dodaj `3010` jako **Miękki restart**, jeśli jeszcze nie istnieje

#### 4. Weryfikacja zgodności

Utwórz **element konfiguracji**, który sprawdza istnienie pliku `%ProgramData%\wifi_bt_update.log` lub odczytuje datę ostatniej modyfikacji tego pliku, aby potwierdzić, że skrypt został uruchomiony w oczekiwanym oknie czasowym.

---

### VMware Workspace ONE (UEM)

Workspace ONE obsługuje wdrażanie za pomocą **Freestyle Orchestrator** lub klasycznego podejścia z wykorzystaniem **Skryptów** i **Czujników**.

#### Metoda A: Aplikacja wewnętrzna (SFX EXE)

- W **konsoli Workspace ONE UEM** przejdź do **Aplikacje i książki** → **Aplikacje** → **Natywne** → **Dodaj aplikację** → **Prześlij**
- Prześlij plik `WiFiBTUpdater-2026.03.0002-Win10-Win11.exe`
- **Opcje wdrożenia**:
  - **Polecenie instalacji**: *(pozostaw domyślne — SFX obsługuje wszystko)*
  - **Uprawnienia administratora**: `Tak`
  - **Kontekst instalacji**: `Urządzenie`
- W sekcji **Pliki** dodaj **skrypt po instalacji**, jeśli chcesz zweryfikować dziennik:
  ```powershell
  Test-Path "$env:ProgramData\wifi_bt_update.log"
  ```

#### Metoda B: Skrypty (PowerShell)

- Przejdź do **Zasoby** → **Skrypty** → **Dodaj** → **Windows**
- Prześlij lub wklej plik `universal-intel-wifi-bt-driver-updater.ps1`
- **Kontekst wykonania**: `System`
- **Architektura wykonania**: `64-bitowa`
- **Limit czasu**: Ustaw na `900` sekund (15 minut), aby uwzględnić tworzenie punktu przywracania na wolniejszych systemach
- W sekcji **Przypisanie**, wyceluj w odpowiednią grupę inteligentną

#### Czujnik do raportowania zgodności

Utwórz **Czujnik**, który raportuje, czy aktualizacja została uruchomiona pomyślnie:

```powershell
# Zwraca ostatnie linie dziennika zawierające status zakończenia
if (Test-Path "$env:ProgramData\wifi_bt_update.log") {
    $last = Get-Content "$env:ProgramData\wifi_bt_update.log" | Select-Object -Last 5
    return ($last -join " ")
} else {
    return "Nie znaleziono dziennika"
}
```

- **Typ oceny**: `Ciąg znaków`
- Przypisz do tej samej grupy inteligentnej, co wdrożenie

---

### PDQ Deploy

PDQ Deploy to najszybsza opcja dla środowisk lokalnych i wdrożeń ad-hoc.

#### 1. Utwórz nowy pakiet

- Otwórz **PDQ Deploy** → **Nowy pakiet**
- **Nazwa**: `Universal Intel Wi-Fi and BT Drivers Updater v2026.03.0002`

#### 2. Dodaj krok — Instalacja (SFX)

- **Typ kroku**: `Instalacja`
- **Plik instalacyjny**: Przeglądaj do `WiFiBTUpdater-2026.03.0002-Win10-Win11.exe`
- **Uruchom jako**: `Użytkownik wdrażający (PDQ)` lub `System lokalny` — obie opcje działają, ponieważ skrypt automatycznie podnosi uprawnienia
- **Kody sukcesu**: Dodaj `0`, `3010`

#### 3. Alternatywnie — krok PowerShell

Jeśli wdrażasz plik PS1 bezpośrednio (np. z udziału sieciowego):

- **Typ kroku**: `PowerShell`
- **Skrypt**:
  ```powershell
  $dest = "$env:SystemRoot\Temp\IntelWiFiBT"
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  Copy-Item "\\twoj-udział\skrypty\universal-intel-wifi-bt-driver-updater.ps1" "$dest\universal-intel-wifi-bt-driver-updater.ps1" -Force
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$dest\universal-intel-wifi-bt-driver-updater.ps1" -quiet
  ```
- **Uruchom jako**: `System lokalny`
- **Limit czasu**: `900` sekund

#### 4. Zaplanuj lub wdróż na żądanie

- Użyj **Automatycznych wdrożeń**, aby zaplanować cykliczne uruchamianie (np. co miesiąc, po wydaniu nowych pakietów sterowników przez Intel)
- Lub wdróż **Na żądanie** do poszczególnych maszyn lub grup z konsoli PDQ Deploy

#### 5. Zweryfikuj wyniki

Po wdrożeniu użyj **PDQ Inventory**, aby odpytać plik dziennika na wszystkich maszynach:
- **Skaner** → **Plik** → `C:\ProgramData\wifi_bt_update.log` → sprawdź datę **Ostatniej modyfikacji**

---

### Weryfikacja pomyślnego wdrożenia (wszystkie platformy)

Niezależnie od używanej platformy MDM, podstawową metodą weryfikacji jest plik dziennika:

```
%ProgramData%\wifi_bt_update.log
```

Pomyślne uruchomienie kończy się linią podobną do:
```
[2026-03-16 14:32:07] [INFO] Script execution completed in 3.47 minutes with 0 errors
```

Uruchomienie z problemami będzie zawierać wpisy `[ERROR]` — są one zawsze zapisywane w dzienniku nawet w trybie `-quiet`, więc dziennik jest zawsze autorytatywnym źródłem prawdy.

**Szybkie sprawdzenie PowerShell w całej flocie (uruchom ze swojej stacji roboczej administracyjnej):**
```powershell
$computers = Get-Content "C:\computers.txt"
foreach ($pc in $computers) {
    $log = "\\$pc\c$\ProgramData\wifi_bt_update.log"
    if (Test-Path $log) {
        $last = Get-Content $log | Select-Object -Last 1
        [PSCustomObject]@{ Computer = $pc; Status = $last }
    } else {
        [PSCustomObject]@{ Computer = $pc; Status = "Nie znaleziono dziennika" }
    }
} | Format-Table -AutoSize
```

---

### Uwagi dotyczące zachowania po restarcie

Skrypt instaluje sterowniki Wi-Fi i Bluetooth dostarczane jako pakiety CAB. Windows zazwyczaj nie wymusi natychmiastowego restartu, ale **restart jest zalecany** w celu pełnej aktywacji nowej wersji sterownika. Ponadto połączenie Wi-Fi i/lub Bluetooth zostanie **krótko przerwane** podczas instalacji sterownika — jest to oczekiwane zachowanie. Zaplanuj swoje okna wdrożeniowe odpowiednio:

- W **Intune**: użyj kodu powrotu miękkiego restartu `3010` i skonfiguruj okno konserwacji lub zezwól użytkownikowi na odroczenie
- W **SCCM**: skonfiguruj **Doświadczenie użytkownika** wdrożenia → **Zatwierdź zmiany w terminie lub podczas okna konserwacji**
- W **Workspace ONE**: użyj zasad ponownego uruchamiania po instalacji ustawionych na `Odrocz`
- W **PDQ Deploy**: dodaj krok **Restart** po kroku instalacji lub obsłuż to poprzez swoją standardową politykę restartów dla poprawek

---

Wdrażanie aktualizacji sterowników Wi-Fi i Bluetooth na dużą skalę wymagało do tej pory niestandardowego pakowania i tworzenia skryptów od podstaw. Flaga `-quiet` sprawia, że to narzędzie można łatwo zintegrować z każdym przepływem pracy MDM — trudna część (wykrywanie odpowiedniego sprzętu, dopasowywanie pakietów CAB, weryfikacja skrótów, tworzenie punktów przywracania) jest obsługiwana automatycznie.

👉 **[Universal Intel Wi-Fi and Bluetooth Drivers Updater — GitHub](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater)**

---

Autor: Marcin Grygiel aka FirstEver ([LinkedIn](https://www.linkedin.com/in/marcin-grygiel))
