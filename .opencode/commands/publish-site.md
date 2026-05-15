---
description: Render and publish notebook site updates
---

Refresh this Quarto website from the configured source notebooks and publish `docs/` only if the rendered site changed. This command is for notebooks that may have been updated outside this repo.

Follow this workflow exactly:

1. Inspect current git state.

- Confirm the current branch is `main`.
- Check whether the worktree has existing changes.
- Do not revert, discard, or overwrite unrelated changes.
- If unrelated source changes are present, continue only if they do not block rendering. Do not commit them.

2. Validate and render. Run these commands in order and stop immediately on failure:

```bash
bash -n build_funcs.sh
. ./build_funcs.sh && validate_sources
. ./build_funcs.sh && render_site && validate_site
```

If any validation step fails, stop. Do not commit and do not push.

3. Check whether the rendered site changed.

Run:

```bash
. ./build_funcs.sh && site_has_changes
```

If there are no `docs/` changes:

- Report `site unchanged; nothing to publish.`
- Do not commit.
- Ask whether to push only if the local branch is already ahead of origin.

4. If `docs/` changed, ask for commit behavior.

Suggest this commit message by default:

```text
update published notebooks
```

Ask the user to choose exactly one option:

- Use suggested commit message
- Enter manual commit message
- No commit

Before committing, state explicitly:

```text
Only docs/ will be committed.
```

Then ask the user to proceed or stop. If they proceed, run:

```bash
git add docs
git commit -m "<message>" -- docs
```

Do not include source files or unrelated worktree changes.

5. Push prompt.

After a successful commit, ask whether to push to `origin main`. If yes, run:

```bash
git push origin main
```

If the user chose no commit, ask whether they still want to push only if the branch is already ahead of origin. Never push without explicit confirmation.

Report the final state clearly: validation result, whether `docs/` changed, commit result, and push result.
