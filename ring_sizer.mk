SCAD=ring_sizer.scad

MODELS=$(shell grep '//@make ' $(SCAD) | grep -E -o -- ' -o +[^ ]+' | sed -e 's/^ -o //')

all: $(MODELS)

clean:
	rm -f $(MODELS)

$(MODELS): $(SCAD)
	test -d $(dir $@) || mkdir -p $(dir $@)
	openscad $< $(shell grep '//@make ' $< | grep -- ' -o $@' | sed -r -e 's/^\/\/@make //')
