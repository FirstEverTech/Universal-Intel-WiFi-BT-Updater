## Jak samodzielnie sprawdzić najnowsże sterowniki

Zamiast ufać innym aktualizatorom sterowników (nawet oficjalnemu narzędziu Intel Driver & Support Assistant), które często sugerują nieprawidłowe wersje lub downgrade, możesz łatwo ręcznie sprawdzić **prawdziwą najnowszą wersję sterownika** dla dowolnego urządzenia Intel Wi‑Fi lub Bluetooth. Oto jak:

---

### Instrukcja krok po kroku (wybierz urządzenie bezprzewodowe)

#### 1. Otwórz Menedżer urządzeń  
Wybierz jedną z metod:
- Naciśnij **Win + X** → **Menedżer urządzeń**
- Naciśnij **Win**, wpisz `Menedżer urządzeń` i zatwierdź Enterem
- Naciśnij **Win + R**, wpisz `devmgmt.msc` i zatwierdź Enterem

<img width="825" height="344" alt="Menedżer urządzeń z rozwiniętą sekcją Karty sieciowe i zaznaczonym urządzeniem Intel Wi‑Fi" src="https://github.com/user-attachments/assets/f51d40d6-565e-4129-ad69-a9826458bb7a" />

---

#### 2. Znajdź urządzenie Intel Wi‑Fi lub Bluetooth
- Rozwiń sekcję **„Karty sieciowe”** dla urządzeń Wi‑Fi lub **„Bluetooth”** dla urządzeń Bluetooth.
- Poszukaj pozycji zawierającej w nazwie **„Intel”**, **„Wi‑Fi”**, **„Wireless”**, **„Bluetooth”** itp.
- Często nazwa zawiera już model urządzenia – na przykład: `Intel(R) Wi‑Fi 6E AX211 160MHz` lub `Intel(R) Wireless Bluetooth(R)`. Dokładny identyfikator sprzętu znajdziesz w następnym kroku.

<img width="817" height="341" alt="Sekcja Kart sieciowych w Menedżerze urządzeń z podświetlonym urządzeniem Intel Wi‑Fi" src="https://github.com/user-attachments/assets/58c94b5e-d6e8-4a01-a161-21f3c3b78e7c" />

---

#### 3. Jeśli HWID nie znajduje się w nazwie, sprawdź właściwości Identyfikatory sprzętu
- Kliknij urządzenie prawym przyciskiem → **Właściwości** → zakładka **Szczegóły**.
- Z listy rozwijanej **Właściwość** wybierz **„Identyfikatory sprzętu”**.
- Zobaczysz coś w rodzaju: `PCI\VEN_8086&DEV_51F1&CC_0280` dla Wi‑Fi lub `USB\VID_8086&PID_0035` dla Bluetooth.  
  Część po **`DEV_`** (tutaj **`51F1`**) lub **`PID_`** jest najważniejszym identyfikatorem.

<img width="441" height="290" alt="Okno właściwości z wybranymi Identyfikatorami sprzętu, pokazujące identyfikator PCI urządzenia" src="https://github.com/user-attachments/assets/bb9d2ac3-27c0-4af8-b469-0d40f853386d" />

---

#### 4. Odnajdź urządzenie w bazach danych, które prowadzę na GitHub
Otwórz odpowiedni plik w przeglądarce:

- **Sterowniki Wi‑Fi:**  
  👉 **[intel-wifi-driver-latest.md](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/data/intel-wifi-driver-latest.md)**
- **Sterowniki Bluetooth:**  
  👉 **[intel-bt-driver-latest.md](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/data/intel-bt-driver-latest.md)**

Naciśnij **Ctrl+F** i wyszukaj model urządzenia (np. `AX211`) lub fragment identyfikatora (np. `51F1`).

<img width="891" height="194" alt="Wyszukiwanie AX211 w bazie sterowników na GitHub" src="https://github.com/user-attachments/assets/3f73a395-96f3-4aca-8c0d-2eb235e1b368" />

Od razu zobaczysz:
- ✅ **Najnowszą wersję sterownika** dla tego urządzenia,
- ✅ Który (najnowszy) **pakiet sterowników** (plik CAB) go zawiera,
- ✅ **Datę i wersję sterownika** zgodnie z oficjalnym wydaniem Intela.

> **Uwaga:** Jeśli urządzenie jest bardzo stare lub nie jest już wspierane przez Intel, może nie występować w tych bazach.

---

#### 5. Porównaj z tym, co mówi Twoje narzędzie do aktualizacji
Jeśli inny program nie widzi najnowszej wersji lub sugeruje downgrade do starszej, to jest to błędna informacja.

---

Uwierz mi, **nikt inny nie jest na tyle szalony**, aby pobrać, rozpakować i przeanalizować **każdy opublikowany kiedykolwiek pakiet sterowników Intel Wi‑Fi i Bluetooth**, a następnie skompilować je w kompletną, przeszukiwalną bazę danych. To właśnie zrobiłem – i to jest podstawa **[Universal Intel Wi‑Fi and Bluetooth Drivers Updater](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater)**.

To narzędzie wykonuje powyższe sprawdzenie **automatycznie** dla wszystkich urządzeń bezprzewodowych Intel w kilka sekund, a następnie pobiera i instaluje właściwe pakiety z pełną weryfikacją hash.

---

Autor: Marcin Grygiel aka FirstEver ([LinkedIn](https://www.linkedin.com/in/marcin-grygiel))
