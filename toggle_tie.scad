include <BOSL2/std.scad>

size = [35, 16, 8];

hole = [5, 3];

rounding = 2;

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustment value for cutouts
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

module bar(size, anchor=CENTER, spin=0, orient=UP) {
  profile = let (
    x = size.y/2,
    y = size.z/2,
    ap = [[x - rounding, -y], [x, 0], [x - rounding, y]]
  ) make_region([
    arc(points=xflip(ap)),
    square([size.y - 2*rounding, size.z], center=true),
    arc(points=ap)
  ]);
  attachable(anchor, spin, orient, size=size) {
    xrot(90)
    yrot(90)
      linear_sweep(profile, h = size.x, center = true);
    children();
  }
}

diff() bar(size) {

  tag("remove")
  attach(TOP, BOTTOM, overlap=size.z + $eps)
    cuboid([hole.x, hole.y, size.z + 2*$eps], rounding=min(hole)/2, edges="Z");

    // cyl(d = hole, h = size.z + 2*$eps);

}
