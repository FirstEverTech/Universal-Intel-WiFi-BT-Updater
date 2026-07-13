#!/usr/bin/env python3
import os, sys, math, time, requests, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timezone
from pathlib import Path

REPO    = os.environ["REPO"]
TOKEN   = os.environ.get("GITHUB_TOKEN")
HEADERS = {
    "Accept": "application/vnd.github.v3.star+json",
    "Authorization": f"Bearer {TOKEN}",
    "User-Agent": "FirstEverTech-stars-graph",
}

def fetch_stars(repo):
    dates, page = [], 1
    while True:
        for attempt in range(5):
            r = requests.get(
                f"https://api.github.com/repos/{repo}/stargazers",
                headers=HEADERS, params={"per_page": 100, "page": page}, timeout=30,
            )
            if r.status_code == 403 and "rate limit" in r.text.lower():
                wait = int(r.headers.get("Retry-After", 30))
                print(f"[WARN] secondary rate limit, waiting {wait}s (attempt {attempt+1}/5)", file=sys.stderr)
                time.sleep(wait)
                continue
            if r.status_code != 200:
                print(f"[DEBUG] status={r.status_code}", file=sys.stderr)
                print(f"[DEBUG] body={r.text}", file=sys.stderr)
                print(f"[DEBUG] x-ratelimit-remaining={r.headers.get('x-ratelimit-remaining')}", file=sys.stderr)
                print(f"[DEBUG] x-ratelimit-reset={r.headers.get('x-ratelimit-reset')}", file=sys.stderr)
                print(f"[DEBUG] x-github-request-id={r.headers.get('x-github-request-id')}", file=sys.stderr)
            r.raise_for_status()
            break
        else:
            raise RuntimeError(f"Failed to fetch page {page} after retries")

        data = r.json()
        if not data:
            break
        dates += [datetime.fromisoformat(i["starred_at"].rstrip("Z")) for i in data]
        page += 1
        time.sleep(0.5)   # throttle między stronami, żeby nie triggerować WAF
    return sorted(dates)

# ---------- COLORS ----------
BLUE     = "#58a6ff"
LINE     = "#1f6feb"
GRID_MAJ = "#283d58"

def x_axis_config(start: datetime, end: datetime):
    """Returns (locator, formatter, xlabel) based on span."""
    days  = (end - start).days
    years = days / 365.25

    if days < 32:
        loc = mdates.FixedLocator(mdates.date2num([start, end]))
        fmt = mdates.DateFormatter("%b '%y")
        lbl = "Date"
    elif years < 1:
        loc = mdates.MonthLocator()
        fmt = mdates.DateFormatter("%b '%y")
        lbl = "Month"
    elif years < 3:
        loc = mdates.MonthLocator(bymonth=[1, 4, 7, 10])
        fmt = mdates.DateFormatter("%b '%y")
        lbl = "Quarter"
    elif years < 6:
        loc = mdates.MonthLocator(bymonth=[1, 7])
        fmt = mdates.DateFormatter("%b '%y")
        lbl = "Half-year"
    elif years < 10:
        loc = mdates.YearLocator()
        fmt = mdates.DateFormatter("%Y")
        lbl = "Year"
    else:
        loc = mdates.YearLocator(2)
        fmt = mdates.DateFormatter("%Y")
        lbl = "Year"

    return loc, fmt, lbl

def generate(dates, repo, out):
    counts  = list(range(1, len(dates) + 1))
    owner, name = repo.split("/")
    now     = datetime.utcnow()
    x_start = dates[0]
    x_end   = now

    # --- PRZEDŁUŻENIE DANYCH O DZISIEJSZĄ DATĘ ---
    if dates[-1] < now:
        extended_dates = dates + [now]
        extended_counts = counts + [counts[-1]]
    else:
        extended_dates = dates
        extended_counts = counts

    fig, ax = plt.subplots(figsize=(10, 3.2), dpi=150)
    fig.patch.set_facecolor("none")
    ax.set_facecolor("none")

    ax.plot(extended_dates, extended_counts, color=LINE, linewidth=2.5, zorder=3)
    ax.fill_between(extended_dates, extended_counts, color=LINE, alpha=0.15, zorder=2)

    x31 = np.linspace(mdates.date2num(x_start), mdates.date2num(x_end), 31)
    date_nums_ext = mdates.date2num(extended_dates)
    y31 = np.interp(x31, date_nums_ext, extended_counts)
    ax.scatter(mdates.num2date(x31), y31, color=BLUE, s=30, zorder=4, linewidths=0)

    x_pad = (x_end - x_start) * 0.02
    ax.set_xlim(x_start - x_pad, x_end + x_pad)

    NUM_Y_LINES = 8
    y_max = max(counts)
    step = math.ceil(y_max / (NUM_Y_LINES - 1)) if y_max > 0 else 1
    nice_max = step * (NUM_Y_LINES - 1)
    if nice_max < NUM_Y_LINES - 1:
        nice_max = NUM_Y_LINES - 1

    ax.set_ylim(0, nice_max + step * 0.5)
    ax.set_yticks(np.linspace(0, nice_max, NUM_Y_LINES))

    ax.set_axisbelow(True)
    loc, fmt, x_lbl = x_axis_config(x_start, x_end)
    ax.xaxis.set_major_locator(loc)
    ax.xaxis.set_major_formatter(fmt)
    ax.grid(True, which="major", color=GRID_MAJ, linewidth=0.7, linestyle=':')

    ax.tick_params(axis="both", which="both", colors=BLUE, labelsize=7)
    fig.autofmt_xdate(rotation=0, ha="center")
    for lbl in ax.get_xticklabels() + ax.get_yticklabels():
        lbl.set_fontweight("bold")
        lbl.set_color(BLUE)

    for spine in ax.spines.values():
        spine.set_edgecolor(GRID_MAJ)

    ax.set_ylabel("Stars", color=BLUE, fontsize=8,
                  fontfamily="DejaVu Sans", fontweight="bold")
    ax.set_xlabel(x_lbl,   color=BLUE, fontsize=8,
                  fontfamily="DejaVu Sans", fontweight="bold")
    ax.set_title(
        f"{owner} / {name} · Stars History",
        color=BLUE, fontsize=10, fontweight="normal",
        fontfamily="DejaVu Sans", pad=10,
    )

    plt.tight_layout(pad=0.8)
    out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out, format="svg", bbox_inches="tight", transparent=True)
    plt.close(fig)

if __name__ == "__main__":
    stars = fetch_stars(REPO)
    if not stars:
        sys.exit(0)
    generate(stars, REPO, Path("assets/stars-graph.svg"))
