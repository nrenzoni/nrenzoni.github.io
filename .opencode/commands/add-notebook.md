---
description: Add a notebook to the site render pipeline
---

Add a new notebook to this Quarto website pipeline. If `$ARGUMENTS` is empty, ask the user for the source notebook path. If `$ARGUMENTS` is present, treat it as the source notebook path and still ask for confirmation before editing files.

Follow this workflow exactly:

1. Validate the source notebook path before editing anything.

Requirements:

- The path must exist.
- The path must be a file.
- The path must end with `.ipynb`.
- The path must not be inside this repo's generated `docs/`, `.quarto/`, `_site/`, or staged notebook copies.

2. Inspect `build_funcs.sh` and `_quarto.yml`.

Use the existing `*_ROOT` variables and `staged_notebooks` mappings to infer project conventions. Do not hardcode project names like `trading-research` or `payroll-anomaly-ranking`; treat them only as current examples.

3. Infer the source project root.

- If the notebook is under an existing `*_ROOT`, reuse that root variable.
- If the notebook is outside all existing roots, infer the sibling project directory from the path. Prefer the nearest ancestor that contains `notebooks/` as a child path in the notebook location.
- If this inference is ambiguous, ask the user for the project root.
- If a new project root is needed, add a new uppercase shell variable near the existing root variables in `build_funcs.sh`, using the sibling directory name converted to a safe variable prefix. Example: `MY_PROJECT_ROOT="$DEV_ROOT/my-project"`.

4. Infer the website destination.

- If the notebook is under `<project-root>/notebooks/...`, default to `<project-directory-name>/<relative path under notebooks>`.
- If the existing mappings for that project use a different destination convention, follow the existing convention.
- If the inferred destination conflicts, escapes the repo, is not repo-relative, or does not end with `.ipynb`, ask the user for the destination.
- Show the inferred destination and ask for confirmation before editing.

5. Check duplicates before editing.

Fail and stop if any of these are true:

- The source notebook is already present in `staged_notebooks`.
- The destination is already present in `staged_notebooks`.
- The destination is already listed under `project.render` in `_quarto.yml`.

6. Edit files.

- Add the new root variable to `build_funcs.sh` if needed.
- Add one `source|destination` row to `staged_notebooks` in `build_funcs.sh`.
- Add the destination path under `project.render` in `_quarto.yml`.

Keep edits minimal and preserve the existing style.

7. Validate the pipeline. Run these commands in order and stop immediately on failure:

```bash
bash -n build_funcs.sh
. ./build_funcs.sh && validate_sources
. ./build_funcs.sh && render_site && validate_site
```

If any validation step fails, do not commit and do not push.

8. Commit prompt.

After validation succeeds, suggest a commit message based on the notebook filename. Use this format unless the user chooses a manual message:

```text
add <notebook-slug> notebook to site
```

Ask the user to choose exactly one option:

- Use suggested commit message
- Enter manual commit message
- No commit

Before committing, state explicitly:

```text
Only these paths will be committed: build_funcs.sh, _quarto.yml, docs/
```

Then ask the user to proceed or stop. If they proceed, run:

```bash
git add build_funcs.sh _quarto.yml docs
git commit -m "<message>" -- build_funcs.sh _quarto.yml docs
```

Do not include unrelated files, even if present in the worktree.

9. Push prompt.

After a successful commit, ask whether to push to `origin main`. If yes, run:

```bash
git push origin main
```

If the user chose no commit, ask whether they still want to push only if the branch is already ahead of origin. Never push without explicit confirmation.

Report the final state clearly: validation result, commit result, and push result.
