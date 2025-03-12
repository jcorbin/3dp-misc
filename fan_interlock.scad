include <BOSL2/std.scad>;
include <BOSL2/metric_screws.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [XXX] */

fan_width = 120;

hole_d = 4.3;

hole_spacing = [ 105, 16 ];

margin = 4;

{

  tol = 0.5;
  chamfer = 0.5;

  extra = 10;

  length = hole_spacing.y + hole_d + 2*margin;

  diff()
  cuboid([fan_width, length, 5], chamfer=chamfer) {

    hx = hole_spacing.x/2;
    hy = hole_spacing.y/2;

    tag("remove")
    move_copies([
      [-hx, -hy, 0],
      [-hx,  hy, 0],
      [ hx, -hy, 0],
      [ hx,  hy, 0],
    ]) {
      coi = $idx;
      attach(BOTTOM, TOP, overlap=10)
        cyl(d=hole_d + tol, h=20);

      D = get_metric_nut_size(4);
      T = get_metric_nut_thickness(4);
      dc = D/cos(30);

      metric_nut(size=4, hole=false)
        translate([0, coi % 2 == 0 ? -D/2 : D/2, 0])
        attach(CENTER)
        cuboid([dc, D, T]);
    }


  }
}

// XXX()
// {
//   // position(TOP) #sphere(1);
//   %show_anchors();
//   // #cube($parent_size, center=true);
// }

// module XXX(anchor = CENTER, spin = 0, orient = UP) {
//   size = [XXX.x, XXX.z, XXX.y];
//   attachable(anchor, spin, orient, size=size) {
//     xrot(-90)
//     down(size.z/2)
//     back(size.y/2)
//     left(size.x/2)
//       import("XXX.stl");
//     children();
//   }
// }

// module XXX(anchor = CENTER, spin = 0, orient = UP) {
//   size = [XXX.x, XXX.z, XXX.y];
//   attachable(anchor, spin, orient, size=size) {
//     XXX();
//     children();
//   }
// }
