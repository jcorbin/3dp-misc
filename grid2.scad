include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

/* [Grid Specs] */

grid_unit = 42;

grid_rounding = 8;

grid_tolerance = 0.5;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

function grid_foot() =  [
  [ "profile_height", 0.8 + 1.8 + 2.15 ],
];

module grid_foot(
  size = [grid_unit, grid_unit], h = 7,
  anchor = CENTER, spin = 0, orient = UP
) {

  // TODO parameterize profile
  h1 = 0.8;
  h2 = 1.8;
  h3 = 2.15;
  h4 = max(0, h - h3 - h2 - h1);
  th = h1 + h2 + h3 + h4;

  r3 = (grid_rounding - grid_tolerance)/2;
  r2 = 3.2/2; // TODO maths?
  r1 = 1.6/2; // TODO maths?

  size3 = size - [grid_tolerance, grid_tolerance];
  size2 = size3 - [2*h3, 2*h3];
  size1 = size2 - [2*h1, 2*h1];

  attachable(anchor, spin, orient,
    size=[size1.x, size1.y, th],
    size2=size3
  ) {

    down(th/2)
    tag_scope("grid_foot")
    diff()
    prismoid(
      size1=size1,
      size2=size2,
      h=h1,
      rounding1=r1,
      rounding2=r2
    ) {
      attach(TOP, BOTTOM, overlap=$eps)
      cuboid(scalar_vec3(size2, h2 + 2*$eps), rounding=r2, edges="Z")
        attach(TOP, BOTTOM, overlap=$eps)
        prismoid(
          size1=size2,
          size2=size3,
          h=h3,
          rounding1=r2,
          rounding2=r3
        )
          if (h4 > 0)
          attach(TOP, BOTTOM, overlap=$eps)
          cuboid(scalar_vec3(size3, h4 + $eps), rounding=r3, edges="Z");

      tag("remove")
      attach(BOTTOM, TOP, overlap=2)
        grid_copies(spacing = size1.x - 2*4.8, n=[2, 2])
        cyl(d=6.5, h=2+$eps);

    }

    children();
  }
}

function grid_body(size = [grid_unit, grid_unit], h = 7) = let (
  // TODO parameterize profile
  h1 = 0.8,
  h2 = 1.8,
  h3 = 2.15,
  h4 = h - h3 - h2 - h1
) [
  [ "h1", 0.8 ],
  [ "h2", 1.8 ],
  [ "h3", 2.15 ],
  [ "h4", h - h3 - h2 - h1 ],
  [ "size", scalar_vec3(size - [grid_tolerance, grid_tolerance], h4) ],
  [ "rounding", (grid_rounding - grid_tolerance)/2 ]
];

module grid_body(size = [grid_unit, grid_unit], h = 7, anchor = CENTER, spin = 0, orient = UP) {
  info = grid_body(size, h);
  sz = struct_val(info, "size");
  r = struct_val(info, "rounding");
  attachable(anchor, spin, orient, size=sz) {
    cuboid(sz, rounding=r, edges="Z");
    children();
  }
}

module grid_platform(cols, rows, height = 1, anchor = CENTER, spin = 0, orient = UP) {
  size = [cols*grid_unit, rows*grid_unit, height*7];
  attachable(anchor, spin, orient, size=size) {
    union() {
      grid_copies(spacing=grid_unit, n=[cols, rows])
        grid_foot();
      up(4.75)
      down(size.z/2)
        grid_body([size.x, size.y], h=size.z, anchor=BOTTOM);
    }
    children();
  }
}

// TODO stacking lip

// TODO magnet holes

grid_platform(3, 3);

// {
//   %show_anchors();
//   #cube($parent_size, center=true);
// }
