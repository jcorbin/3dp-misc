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

// Plate footprint width (X).
plate_width = 2.25 * inch;

// Plate footprint depth (Y).
plate_depth = 2.25 * inch;

// Plate thickness (Z).
plate_height = 0.25 * inch;

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
  // foot();
  body();
  // TODO dev convenience to show body attachment points and bounding box
}

// The uncut plate + post solid, before holes and fins are differenced out.
module body() {
  // TODO use attachable() w/ standard body(...) args
  // Rounded mounting plate
  cuboid(
    [plate_width, plate_depth, plate_height], 
    rounding=corner_radius, edges="Z")
    // Centered straight cylinder with a rounded dome tip
    attach(TOP, BOTTOM, overlap=$eps)
    cyl(
      h=post_height + dome_height + $eps,
      d=post_diameter,
      chamfer1=-3*chamfer,
      rounding2=dome_height)
    // Holes and fins are differenced out in the post's frame; see foot().
    children();
}

// The finished foot: body with mounting holes and interior micro-fins removed.
module foot() {
  post_radius = post_diameter / 2;

  // room for plenty of post perimeters
  fin_w = 2*post_radius - 8 * feature;

  // tall enough to span into the post, into the base, and thru the post's fillet region
  fin_h = plate_height/2 + 3*chamfer + post_height/4;

  diff()
  body() {

    // Mounting holes
    tag("remove")
    grid_copies(n=2, spacing=[ hole_spacing, hole_spacing ])
      cyl(h=100, d=hole_diameter);

    // Interior micro-fins for more strength
    tag("remove")
    down((post_height + dome_height)/2)
    up(fin_h/2)
    down(plate_height/2)
    zrot_copies(n=fin_n)
    cuboid([fin_w, feature, fin_h]);

  }
}

main();
