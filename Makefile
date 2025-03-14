# TODO generalize past 1 file

SCAD=handle.scad
MODELS=$(shell grep '//@make ' $(SCAD) | grep -E -o -- ' -o +[^ ]+' | sed -e 's/^ -o //')

all: $(MODELS)

clean:
	rm -f $(MODELS)

$(MODELS): $(SCAD)
	test -d $(dir $@) || mkdir -p $(dir $@)
	openscad $< $(shell grep '//@make ' $< | grep -- ' -o $@' | sed -r -e 's/^\/\/@make //')

$(SCAD): init

init: BOSL2/std.scad
	git config filter.lfs.smudge >/dev/null || git config --local include.path ../.gitconfig

BOSL2/std.scad:
	git submodule update --init
