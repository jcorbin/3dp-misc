include <BOSL2/std.scad>;

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

// Convert inches to mm
inch = 25.4;

// NOTE while I understand the desire to explicate units, and to be able to
// work in inches to spec, using expressions for parameters like below will
// actually make those aspect un-customizable from the OpenSCAD gui ; in
// general, you're much better off writing things like:
//     ring_height = 18; // close-enough to 3/4-inch

// Ring Dimensions
// ring_outer_d = 28.5 * inch;
// ring_offset  = 0.3 * inch;
// ring_inner_d = ring_outer_d - (2 * ring_offset); // Offset on both sides
ring_height  = 0.75 * inch;

// // Circle (Cap) Dimensions
// circle_d      = ring_outer_d + (4 * inch);
// circle_height = 0.75 * inch;

wedge_width = ring_height;
wedge_depth = ring_height;

module main() {
  prismoid(
    size1 = [wedge_width, wedge_depth],
    size2 = [wedge_width, 2*chamfer],
    h = ring_height,
    shift = [0, (wedge_depth - 2*chamfer)/2],
    chamfer = chamfer,
    orient=LEFT
  );
}

module dev() {
  // // 1. The Bottom Ring
  // difference() {
  //     cylinder(h = ring_height, d = ring_outer_d, center = false);
  //     // Subtract the inner core to make it a ring
  //     translate([0, 0, -1]) // Slight overlap to ensure a clean cut
  //         cylinder(h = ring_height + 2, d = ring_inner_d, center = false);
  // }


  // // 2. The Top Solid Circle (Stacked on top of the ring)
  // translate([0, 0, ring_height])
  //     cylinder(h = circle_height, d = circle_d, center = false);
}

main();
// dev();
