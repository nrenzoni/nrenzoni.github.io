WEBSITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd "$WEBSITE_ROOT/.." && pwd)"
TRADING_RESEARCH_ROOT="$DEV_ROOT/trading-research"
PAYROLL_ANOMALY_RANKING_ROOT="$DEV_ROOT/payroll-anomaly-ranking"

# List source notebooks and their website-relative staging destinations.
function staged_notebooks() {
	cat <<EOF
$TRADING_RESEARCH_ROOT/notebooks/render-demo.ipynb|notebooks/render-demo.ipynb
$TRADING_RESEARCH_ROOT/notebooks/pr_graph/eda_04_intraday_news_execution.ipynb|notebooks/pr_graph/eda_04_intraday_news_execution.ipynb
$TRADING_RESEARCH_ROOT/notebooks/target_engineering/eda_01_target_engineering.ipynb|notebooks/target_engineering/eda_01_target_engineering.ipynb
$PAYROLL_ANOMALY_RANKING_ROOT/notebooks/08_snf_payroll_approval_case_studies.ipynb|payroll-anomaly-ranking/08_snf_payroll_approval_case_studies.ipynb
$PAYROLL_ANOMALY_RANKING_ROOT/notebooks/09_model_ablation_and_ml_value.ipynb|payroll-anomaly-ranking/09_model_ablation_and_ml_value.ipynb
EOF
}

# Run commands inside the uv environment that has Quarto/Jupyter deps.
function uv_run_project() {
	UV_PROJECT_ENVIRONMENT="$TRADING_RESEARCH_ROOT/.venv" uv run --project "$TRADING_RESEARCH_ROOT" --extra quarto "$@"
}

# Fail unless deployment starts from main.
function require_main_branch() {
	local branch
	branch="$(git branch --show-current)"
	if [ "$branch" != "main" ]
	then
		echo >&2 "cannot $1: current branch is $branch, expected main."
		return 1
	fi
}

# Fail if source or generated changes are already pending.
function require_clean_work_tree() {
	git update-index -q --ignore-submodules --refresh
	local err=0

	if ! git diff-files --quiet --ignore-submodules --
	then
		echo >&2 "cannot $1: you have unstaged changes."
		git diff-files --name-status -r --ignore-submodules -- >&2
		err=1
	fi

	if ! git diff-index --cached --quiet HEAD --ignore-submodules --
	then
		echo >&2 "cannot $1: your index contains uncommitted changes."
		git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
		err=1
	fi

	if [ "$err" = 1 ]
	then
		echo >&2 "Please commit or stash them."
		return 1
	fi
}

# Fail unless deployment is starting from a clean main checkout.
function require_main_branch_clean() {
	require_main_branch "$1" || return 1
	require_clean_work_tree "$1"
}

# Validate local repos and website inputs before rendering.
function validate_sources() {
	if ! command -v git >/dev/null 2>&1
	then
		echo >&2 "missing required command: git"
		return 1
	fi

	if ! command -v uv >/dev/null 2>&1
	then
		echo >&2 "missing required command: uv"
		return 1
	fi

	for path in "$TRADING_RESEARCH_ROOT" "$PAYROLL_ANOMALY_RANKING_ROOT"
	do
		if [ ! -d "$path" ]
		then
			echo >&2 "missing source directory: $path"
			return 1
		fi
	done

	local src dest
	while IFS='|' read -r src dest
	do
		if [ ! -f "$src" ]
		then
			echo >&2 "missing source notebook: $src"
			return 1
		fi
	done < <(staged_notebooks)

	for path in "$WEBSITE_ROOT/_quarto.yml" "$WEBSITE_ROOT/index.qmd" "$WEBSITE_ROOT/about.qmd" "$WEBSITE_ROOT/trading-research.qmd" "$WEBSITE_ROOT/payroll-anomaly-ranking/index.qmd" "$WEBSITE_ROOT/styles.css"
	do
		if [ ! -f "$path" ]
		then
			echo >&2 "missing website file: $path"
			return 1
		fi
	done
}

# Copy selected notebooks into stable website paths.
function stage_notebooks() {
	rm -rf "$WEBSITE_ROOT/notebooks"
	rm -f "$WEBSITE_ROOT/payroll-anomaly-ranking"/*.ipynb

	local src dest
	while IFS='|' read -r src dest
	do
		mkdir -p "$(dirname "$WEBSITE_ROOT/$dest")"
		cp "$src" "$WEBSITE_ROOT/$dest"
	done < <(staged_notebooks)
}

# Render the Quarto site into docs/ for GitHub Pages.
function render_site() {
	stage_notebooks
	rm -rf docs
	uv_run_project quarto render
}

# Verify the rendered site has expected entry points.
function validate_site() {
	for path in "$WEBSITE_ROOT/docs/index.html" "$WEBSITE_ROOT/docs/search.json"
	do
		if [ ! -f "$path" ]
		then
			echo >&2 "missing rendered site file: $path"
			return 1
		fi
	done
}

# Return success when docs/ has staged or unstaged changes.
function site_has_changes() {
	if [ -n "$(git status --porcelain -- docs)" ]
	then
		return 0
	fi

	echo "site unchanged; nothing to publish."
	return 1
}

# Commit and push only generated docs/ changes.
function publish_site() {
	local message="${1:-}"
	if [ -z "$message" ]
	then
		echo >&2 "usage: publish_site <message>"
		return 1
	fi

	git add docs
	if git diff --cached --quiet -- docs
	then
		echo "site unchanged; nothing to publish."
		return 0
	fi

	git commit -m "update site: $message" -- docs
	git push origin main
}

# Full manual deployment entrypoint.
function deploy_site() {
	local message="${1:-}"
	if [ -z "$message" ]
	then
		echo >&2 "usage: deploy_site <message>"
		return 1
	fi

	require_main_branch_clean deploy || return 1
	validate_sources || return 1
	render_site || return 1
	validate_site || return 1
	publish_site "$message"
}
