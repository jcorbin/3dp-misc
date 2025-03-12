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

// Width of the mounting board that the jig holds/marks.
plate_w = 200;

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

// Extra screw hole registration X spacing; typically use "the other" typical value from fan_screw_spacing (105 or 125); may provide more than 1 value if many holes are desired.
extra_reg = [
  125, // 140-spec holes for a 120-spec jig
  // 105, // 120-spec holes for a 140-spec jig
  // NOTE: may also specify [ X, Y ] vec2 if Y offset is needed
  // [ 125,  9 ]
];

/* [Jig Details] */

// Thickness of jig walls.
jig_wall = 2;

// Chamfer applied to jig outer edges and inner corners.
chamfer = 0.5;

{

  extra_reg_yoff = max([
    for (reg = extra_reg)
    is_num(reg) ? 0 : reg.y < 0 ? 0 : reg.y
  ]);

  tol = 0.5;
  body_w = fan_body_w;
  fan_d = fan_hole_d;
  next = inter_fan_screw_spacing;
  screw_spacing = fan_screw_spacing;

  extra = next + extra_reg_yoff;

  shx = screw_spacing/2;
  shy = screw_spacing/2;

  plate_t = 5;

  cut = 10;

  margin = 2*jig_wall;

  length = body_w + margin + extra;

  diff()
  cuboid([plate_w + margin, length, jig_wall + plate_t], chamfer=chamfer, edges="Y") {
    attach(TOP, BOTTOM, overlap=plate_t)
    tag("remove")
      cuboid([plate_w + 2*tol, length + 2*$eps, 2*plate_t], chamfer=chamfer, edges="Y");

    reg_moves = let (
      ny = shy + next,
    ) flatten([
      [
        // fan mount holes
        for (y = [-shy, shy])
        for (x = [-shx, shx])
        [x, y, 0]
      ],

      // next fan registration holes
      [
        [-shx, ny, 0],
        [ shx, ny, 0]
      ],

      // extra fan registration holes
      for (reg = extra_reg)
      let (
        rx = (is_num(reg) ? reg : reg.x)/2,
        ry =  is_num(reg) ? 0   : reg.y,
      ) [
        [-rx, ny + ry, 0],
        [ rx, ny + ry, 0]
      ]

    ]);

    fwd(extra/2)
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
