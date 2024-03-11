function activate_env() {
	. /home/trade/.virtualenvs/trading-research/bin/activate
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
	git checkout gh-pages
	git --work-tree=_site add --all
	git --work-tree=_site commit -m "update site: $1"
	git --work-tree=_site push
}

