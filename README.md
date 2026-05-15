This repo is for my personal website where I collect selected Jupyter notebooks from multiple local research projects.

The Quarto project is intended to live next to the research project directories, for example:

```text
/home/trade/Dev/quarto_website
/home/trade/Dev/trading-research
/home/trade/Dev/payroll-anomaly-ranking
```

`build_funcs.sh` stages only the selected notebooks into website-owned paths before rendering. This keeps published URLs stable while allowing source notebooks to live in separate repos.

The website is manually rendered into `docs/` and deployed from the `main` branch when needed. GitHub Pages should be configured with:

```text
Source: Deploy from a branch
Branch: main
Folder: /docs
```

Manual deployment:

```bash
. build_funcs.sh
deploy_site "short description of the update"
```

`deploy_site` expects to run from a clean `main` branch. Commit source changes first, then run the deploy when you want to refresh the published `docs/` output.

Useful manual checks:

```bash
. build_funcs.sh
validate_sources
render_site
validate_site
```
