include <BOSL2/std.scad>;

// Rounded square mounting plate with four holes and a domed center post
// OpenSCAD units are millimeters.

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Fitment and Quality] */

// General fit tolerance.
tolerance = 0.4;

// Minimum feature size, more or less nozzle size.
feature = 0.4;

// Generic chamfer for things like bed interface and outside non-interface edges.
chamfer = 1.5;

// Generic rounding for anonymous edges.
rounding = 1.5;

/* [Part-iculars] */

inch = 25.4;

// Base plate size
plate_size = [2.25, 2.25, 0.25] * inch;

// Plate corner rounding radius.
corner_radius = 0.125 * inch;

// Mounting hole diameter.
hole_diameter = 0.375 * inch;

// Center-to-center spacing of the four mounting holes.
hole_spacing = 1.25 * inch;

// Center post diameter.
post_diameter = 1 * inch;

// Straight cylindrical height of the center post.
post_height = 1.50 * inch;

// Rounded dome cap height atop the post.
dome_height = 0.25 * inch;

// Number of interior radial micro-fins reinforcing the post.
fin_n = 8;

/* [Part Selection] */

mode = 100; // [0:Foot, 1:Body, 100:Dev]


/***
STL auto generation entry points; easy to hang something like a Makefile off //@make comment directives:

```Makefile

SCAD=handle.scad
MODELS=$(shell grep '//@make ' $(SCAD) | grep -E -o -- ' -o +[^ ]+' | sed -e 's/^ -o //')

all: $(MODELS)

clean:
	rm -f $(MODELS)

$(MODELS): $(SCAD)
	test -d $(dir $@) || mkdir -p $(dir $@)
	openscad $< $(shell grep '//@make ' $< | grep -- ' -o $@' | sed -r -e 's/^\/\/@make //')

$(SCAD): init

# suggest using git-lfs to track rendered STL artifacts
init: BOSL2/std.scad
	git config filter.lfs.smudge >/dev/null || git config --local include.path ../.gitconfig

# suggest using a git submodule to pin your bosl2 version
BOSL2/std.scad:
	git submodule update --init

```
*/

//@make -o foot.stl -D mode=0

/// dispatch / integration

module main() {
  if (mode == 0) {
    foot();
  }
  else if (mode == 1) {
    body();
  }
  else if (mode == 100) {
    dev();
  }
}

module dev() {

  // // Ghost the uncut body to reveal its named anchors and bounding box.
  // foot();
  // %body() {
  //   show_anchors(s=10, std=false);
  //   cube($parent_size, center=true);
  // }

  // Partial cutaway with transparent ghost overlay of the remnant
  back_half()
  foot();
  #foot();
}

// The uncut plate + post solid, before holes and fins are differenced out.
// Attachable with named "mount_0".."mount_3" anchors at the mounting
// holes and a "tip" anchor at the dome apex, all facing UP.
module body(anchor = CENTER, spin = 0, orient = UP) {
  post_h = post_height + dome_height;
  size = plate_size + [0, 0, post_h];

  plate_top = (plate_size.z - post_h) / 2;
  plate_z = -post_h / 2;

  // The four mounting-hole locations, on the plate's top face.
  mount_locs = grid_copies(n=2, spacing=[hole_spacing, hole_spacing], p=[0, 0, plate_top]);

  attachable(
    anchor, spin, orient, size=size,
    anchors=[
      for (i = idx(mount_locs)) named_anchor(str("mount_", i), mount_locs[i], UP),
      named_anchor("tip", [0, 0, size.z / 2], UP),
    ],
  ) {
    // Rounded mounting plate, dropped so the whole body is bbox-centered.
    up(plate_z)
    cuboid(
      plate_size,
      rounding=corner_radius, edges="Z")
      // Centered straight cylinder with a rounded dome tip
      attach(TOP, BOTTOM, overlap=$eps)
      cyl(
        h=post_h + $eps,
        d=post_diameter,
        chamfer1=-3*chamfer,
        rounding2=dome_height);

    children();
  }
}

// The finished foot: body with mounting holes and interior micro-fins removed.
module foot(anchor = CENTER, spin = 0, orient = UP) {
  post_radius = post_diameter / 2;

  // room for plenty of post perimeters
  fin_w = 2*post_radius - 8 * feature;

  // tall enough to span into the post, into the base, and thru the post's fillet region
  fin_h = plate_size.z/2 + 3*chamfer + post_height/4;

  // Plate mid-plane in the bounding-box-centered frame (see body()).
  plate_z = -(post_height + dome_height) / 2;

  diff()
  body(anchor, spin, orient) {
    // Mounting holes, drilled down through the plate at each mount anchor.
    tag("remove")
    attach([ "mount_0", "mount_1", "mount_2", "mount_3" ], BOTTOM, overlap=plate_size.z + $eps)
      cyl(h=plate_size.z + 2*$eps, d=hole_diameter);

    // Interior micro-fins for more strength, rising from the plate mid-plane.
    tag("remove")
    up(plate_z + fin_h/2)
    zrot_copies(n=fin_n)
    cuboid([fin_w, feature, fin_h]);

  }
}

main();
