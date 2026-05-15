---
description: Sync notebook pipeline with external source locations
---

Validate that every notebook in `staged_notebooks` still exists at its external source location. For any missing sources, offer to remove their references from the render pipeline and re-render the site.

Follow this workflow exactly:

1. Check git state.

- Confirm the worktree is clean. If uncommitted changes exist, stop and tell the user to commit or stash them first.

2. Inventory external sources.

Source `build_funcs.sh` and parse every `source|destination` pair from `staged_notebooks`. For each pair, check whether the source file exists on disk.

Replace `<N>` and `<M>` with actual counts and report:

\<N\> of \<M\> external notebook sources exist.

List each missing source with its full path and its website destination.

3. If all sources exist, stop.

Report `All external notebook sources exist; nothing to sync.`

4. If any sources are missing, present this question:

Found missing notebook sources that don't exist externally

Options:
- "Remove all missing from pipeline (Recommended)"
- "Choose per notebook"
- "Stop"

5. If the user chooses "Stop", print:

```
Sync cannot complete while external notebook sources are missing.
Resolve these paths before re-running this command:

  /path/to/missing/notebook.ipynb

Options:
- Restore the notebook at the expected external path.
- Re-run this command and choose "Remove ..." to clean up stale references.
```

Then stop.

6. If the user chooses "Remove all missing", proceed to remove every missing notebook.

Before editing any file, read the current contents of `build_funcs.sh`, `_quarto.yml`, and any affected `index.qmd` listings so you see the exact lines.

7. If the user chooses "Choose per notebook", present the same question for each missing notebook individually.

For each one show:

```
Notebook: <filename>
Source: <full external path>
Destination: <website-relative path>

This notebook no longer exists at its external source location.
```

Options:
- "Remove from pipeline"
- "Skip (resolve externally later)"

If "Skip" is chosen, warn that the pipeline will remain inconsistent until that external source is resolved.

8. For each notebook being removed, edit these files.

Read each file first, then make minimal targeted edits:

- `build_funcs.sh` — remove the exact `source|destination` line from `staged_notebooks`. Include enough surrounding lines in the match to avoid ambiguity.
- `_quarto.yml` — remove the destination path from `project.render`. Include the surrounding list entries in the match.
- If the destination is under a subdirectory that contains an `index.qmd` whose `listing:` block includes the notebook filename, remove that filename from `listing.contents`.

After editing all configuration files, delete the staged `.ipynb` file at the destination path:

```bash
rm -f "payroll-anomaly-ranking/01_problem_framing_and_data_maturity.ipynb"
```

(use the actual destination path from the removed entry, not the example above)

9. Validate and re-render.

Run these commands in order, stopping immediately on failure:

```bash
bash -n build_funcs.sh
. ./build_funcs.sh && validate_sources
. ./build_funcs.sh && render_site && validate_site
```

`render_site` deletes and regenerates `docs/` from scratch. This ensures `listings.json`, `search.json`, and rendered HTML files match the cleaned pipeline exactly.

If any step fails, stop. Do not commit and do not push.

10. Commit prompt.

Suggest a commit message:

```text
sync: remove X stale notebook references
```

Ask the user to choose exactly one option:

- Use suggested commit message
- Enter manual commit message
- No commit

Before committing, list every file that was edited or deleted and confirm with the user. Then if they proceed, add and commit only those files plus `docs/`:

```bash
git add <edited files> docs
git commit -m "<message>" -- <edited files> docs
```

Do not include unrelated files.

11. Push prompt.

After a successful commit, ask whether to push to `origin main`. If yes, run:

```bash
git push origin main
```

If the user chose no commit, ask whether they still want to push only if the branch is already ahead of origin. Never push without explicit confirmation.

Report the final state clearly: which notebooks were removed, re-render result, validation result, commit result, and push result.
