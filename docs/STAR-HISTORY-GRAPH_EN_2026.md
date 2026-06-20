# Star History Graph — Setup

1. Create `.github/workflows/star-history.yml` — copy from `FirstEverTech/Universal-Intel-Chipset-Updater`
2. Create `.github/scripts/generate_star_history.py` — copy from same repo
3. Create `assets/.gitkeep` — empty file

**Actions → Generate Star History → Run workflow**

Add to `README.md`:
![Star History](assets/star-history.svg)

No configuration needed — repo is detected automatically via `github.repository`.