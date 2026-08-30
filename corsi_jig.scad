include <BOSL2/std.scad>;
include <BOSL2/metric_screws.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Plate Specs] */

// Width of the mounting board.
plate_w = 200;

// Thickness of the mounting board.
plate_t = 5;

/* [Fan Specs] */

// Fan body width; typically 120 or 140.
fan_body_w = 120;

// Fan bore diameter; typically 116 or 134.
fan_hole_d = 116;

// Fan mount screw spacing; typically 105 or 125.
fan_screw_spacing = 105;

/* [Fan Screw Specs] */

// Spacing between fan mount holes from one fan body to the next; both 120 and 140 standard fan specs have an ideal value of 15 here, so 16 is a sane default, allowing 1mm tolerance between fan bodies.
inter_fan_screw_spacing = 16;

// Screw hole diamter; M4 is the ideal screw size here, so a decent place to start. Alternatively a smaller value like 2, would allow only smaller pinning of the registration holes.
screw_hole_d = 4;

/* [Jig Details] */

// Thickness of jig walls.
jig_wall = 2;

// Chamfer applied to jig outer edges and inner corners.
chamfer = 0.5;

{

  tol = 0.5;
  body_w = fan_body_w;
  fan_d = fan_hole_d;
  next = inter_fan_screw_spacing;
  screw_spacing = fan_screw_spacing;

  shx = screw_spacing/2;
  shy = screw_spacing/2;

  cx = plate_w/2 - 8*jig_wall;

  cut = 10;

  margin = 2*jig_wall;

  length = body_w + margin + next;

  diff()
  cuboid([
    plate_w + margin,
    length,
    jig_wall + plate_t,
  ], chamfer=chamfer, edges="Y") {
    left(jig_wall + $eps)
    attach(TOP, BOTTOM, overlap=plate_t)
    tag("remove")
      cuboid([
        plate_w + 2*tol + jig_wall + $eps,
        length + 2*$eps,
        2*plate_t
      ], chamfer=chamfer, edges="Y");

    reg_moves = let (
      ny = shy + next,
    ) flatten([

      // fan mount holes
      [
        for (y = [-shy, shy])
        for (x = [-shx, shx])
        [x, y, 0]
      ],

      // center alignment holes
      [
        [cx, 0, 0],
        [-cx, 0, 0],
      ],

      // next fan registration holes
      [
        [-shx, ny, 0],
        [ shx, ny, 0]
      ],

    ]);

    fwd(next/2)
    tag("remove") {
      attach(BOTTOM, TOP, overlap=cut/2)
        cyl(d=fan_d + 2*tol, h=cut);
      move_copies(reg_moves)
        attach(BOTTOM, TOP, overlap=cut/2)
        cyl(d=screw_hole_d + tol, h=cut);
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
