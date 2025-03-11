include <BOSL2/std.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [XXX] */

{

  tol = 0.5;
  chamfer = 0.5;

  extra = 10;
  next = 16;

  diff()
  cuboid([204, 124 + extra, 7], chamfer=chamfer, edges="Y") {
    attach(TOP, BOTTOM, overlap=5)
    tag("remove")
      cuboid([200 + 2*tol, 124 + extra + 2*$eps, 2*5], chamfer=chamfer, edges="Y");

    fwd(extra/2)
    tag("remove") {
      attach(BOTTOM, TOP, overlap=5)
        cyl(d=120 + 2*tol, h=10);
      move_copies([
        [-105/2, -105/2, 0],
        [ 105/2, -105/2, 0],
        [-105/2,  105/2, 0],
        [ 105/2,  105/2, 0],
        [-105/2,  105/2 + next, 0],
        [ 105/2,  105/2 + next, 0],
      ])
        attach(BOTTOM, TOP, overlap=5)
        cyl(d=4.3 + tol, h=10);
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
