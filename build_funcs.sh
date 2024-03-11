function activate_env() {
	. /home/trade/.virtualenvs/trading-research/bin/activate
}

function require_clean_work_tree() {
    # Update the index
    git update-index -q --ignore-submodules --refresh
    err=0

    # Disallow unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules --
    then
        echo >&2 "cannot $1: you have unstaged changes."
        git diff-files --name-status -r --ignore-submodules -- >&2
        err=1
    fi

    # Disallow uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules --
    then
        echo >&2 "cannot $1: your index contains uncommitted changes."
        git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
        err=1
    fi

    if [ $err = 1 ]
    then
        echo >&2 "Please commit or stash them."
        return 1
    fi
}

# need changes committed in order to checkout gh-pages branch in flow
function require_main_branch_clean() {
	git checkout main -q
	return $(require_clean_work_tree)
}

# builds notebooks
function execute_notebooks() {
	activate_env
	jupyter nbconvert --inplace --execute "$@"
	deactivate
}

# quarto needs py env with nbconvert installed
function quarto_render() {
	rm -r _site || true
	activate_env
	quarto render
	deactivate
}

# fix relative html links due to quarto
function post_render() {
	mv notebooks _site/
	find _site -name '*.html' -type f -print0 | xargs -0 sed -i -e 's/quarto_website\///g'
	sed -i -e 's|\.\.\/||g' _site/index.html
}


# arg1: commit msg
# push _site content to root of gh_pages branch
function update_github_pages() {
	git checkout gh-pages -q
	
	git --work-tree=_site add --all
	git --work-tree=_site commit -m "update site: $1"
	git --work-tree=_site push
	
	# restore to main branch
	git checkout main -q
}

