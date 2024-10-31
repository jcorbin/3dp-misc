init:
	git config filter.lfs.smudge >/dev/null || git config --local include.path ../.gitconfig
