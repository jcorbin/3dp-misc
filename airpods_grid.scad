include <BOSL2/std.scad>;
use <grid2.scad>

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;


module body(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[42, 42, 7*4]) {
    left(21)
    fwd(21)
    down(7*2)
      import("Airpods+Pro+Gridfinity+Vertical.stl");

    children();
  }
}

diff()
body() {
  // extracted from grid_foot
  grid_rounding = 8;
  grid_tolerance = 0.5;
  h1 = 0.8;
  h3 = 2.15;
  size3 = [$parent_size.x, $parent_size.y] - [grid_tolerance, grid_tolerance];
  size2 = size3 - [2*h3, 2*h3];
  size1 = size2 - [2*h1, 2*h1];

  tag("remove")
  attach(BOTTOM, TOP, overlap=2)
    grid_copies(spacing = size1.x - 2*4.8, n=[2, 2])
    cyl(d=6.5, h=2 + $eps);
}
