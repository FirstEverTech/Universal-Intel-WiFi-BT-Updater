# Graph Historii Gwiazdek — Wdrożenie

1. Utwórz `.github/workflows/star-history.yml` — skopiuj z `FirstEverTech/Universal-Intel-Chipset-Updater`
2. Utwórz `.github/scripts/generate_star_history.py` — skopiuj z tego samego repo
3. Utwórz `assets/.gitkeep` — pusty plik

**Actions → Generate Star History → Run workflow**

Dodaj do `README.md`:
![Star History](assets/star-history.svg)

Skrypt wykrywa repo automatycznie przez `github.repository` — nic nie zmieniasz.