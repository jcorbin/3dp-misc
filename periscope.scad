include <BOSL2/std.scad>;

// A hex-shafted "periscope" wand: a long hex arm, a retaining disk, an L-bend,
// and a flared conical scope end.

/* [Part Selection] */

// Which part to model.
mode = 0; // [0:Periscope, 100:Dev, 101:Outline Path]

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Arm] */

// Hex shaft size, flat-to-flat.
hex_size = 7;

// Overall arm height, from the bend's base plane up to the shaft tip.
arm_height = 80;

// L-bend centerline radius.
bend_radius = 10;

/* [Retaining Disk] */

// Retaining disk diameter.
disk_diameter = 10;

// Retaining disk thickness.
disk_thickness = 2;

// Height of the disk's underside above the bend's base plane.
disk_height = 25;

/* [Scope End] */

// Length of the hex-to-cylinder flare.
scope_taper = 30;

// Outer diameter of the flared scope cylinder.
scope_diameter = 24;

// Rounding radius of the turret's top elbow. TODO unmodelled
scope_bend_radius = 8;

/// dispatch / integration

module __customizer_limit__() {}

// Circumscribed (corner-to-corner) diameter of the hex shaft, since hex_size is
// the flat-to-flat measure.
hex_od = hex_size / cos(30);

// Centerline of the arm and its bend: down the shaft from the tip, then a
// quarter turn out along +X. Drawn in 2D as (x, height), then stood up into the
// XZ plane so that the origin is the arm axis crossing the bend's base plane.
arm_path = xrot(90, p=path3d(turtle([
  "right", 90,
  "move", arm_height - bend_radius,
  "arcleft", bend_radius, 90,
], state=[0, arm_height])));

// Bounding box of hex_arm(), in that same natural frame: the shaft rises to
// arm_height, the bend reaches out to bend_radius, and the elbow's end face
// hangs half a hex below the base plane.
arm_bounds = [
  [ -hex_od/2,   -hex_od/2, -hex_od/2   ],
  [ bend_radius,  hex_od/2,  arm_height ],
];

// The hex shaft and its L-bend, swept as one piece so the corner has no seam.
// Attachable with a "tip" anchor at the top of the shaft facing UP, and an
// "elbow" anchor at the end face of the bend facing RIGHT.
module hex_arm(anchor = CENTER, spin = 0, orient = UP) {
  size = arm_bounds[1] - arm_bounds[0];
  center = (arm_bounds[0] + arm_bounds[1]) / 2;
  attachable(anchor, spin, orient, size=size, anchors=[
    named_anchor("tip", [0, 0, arm_height] - center, UP),
    named_anchor("elbow", [bend_radius, 0, 0] - center, RIGHT),
  ]) {
    translate(-center)
      path_sweep(hexagon(id=hex_size), arm_path);
    children();
  }
}

// The hex-to-cylinder flare, cast along +Z from its hex end face at BOTTOM to
// the wide scope face at TOP.
module scope_taper(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[scope_diameter, scope_diameter, scope_taper]) {
    down(scope_taper/2)
    hull() {
      linear_sweep(hexagon(id=hex_size), h=$eps, anchor=BOTTOM);
      up(scope_taper)
        linear_sweep(circle(d=scope_diameter), h=$eps, anchor=TOP);
    }
    children();
  }
}

// The whole wand. Attachable with "tip" at the shaft end, "disk" at the
// retaining disk's underside, and "scope" at the flare's wide face.
module periscope(anchor = CENTER, spin = 0, orient = UP) {
  // Widest thing on the shaft axis is the disk; widest overall is the scope flare.
  bounds = [
    [ -max(hex_od, disk_diameter)/2, -max(disk_diameter, scope_diameter)/2, -scope_diameter/2 ],
    [ bend_radius + scope_taper,      max(disk_diameter, scope_diameter)/2,  arm_height      ],
  ];
  size = bounds[1] - bounds[0];
  center = (bounds[0] + bounds[1]) / 2;

  attachable(anchor, spin, orient, size=size, anchors=[
    named_anchor("tip", [0, 0, arm_height] - center, UP),
    named_anchor("disk", [0, 0, disk_height] - center, UP),
    named_anchor("scope", [bend_radius + scope_taper, 0, 0] - center, RIGHT),
  ]) {
    translate(-center) {
      up(arm_height)
      hex_arm(anchor="tip")
        attach("elbow", BOTTOM)
        scope_taper();

      up(disk_height)
        cyl(d=disk_diameter, h=disk_thickness, anchor=BOTTOM);
    }

    children();
  }
}

//@make -o periscope.stl -D mode=0

module main() {

  // Periscope
  if (mode == 0) {
    periscope(anchor=BOTTOM);
  }

  // Dev
  else if (mode == 100) {
    dev();
  }

  // Outline Path
  else if (mode == 101) {
    stroke(arm_path, closed=false, width=1);
  }

}

module dev() {
  // %hex_arm()
  // %scope_taper()
  %periscope()
  {
    show_anchors(s=10, std=false);
    cube($parent_size, center=true);
  }
}

main();
