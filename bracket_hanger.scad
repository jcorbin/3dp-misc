include <BOSL2/std.scad>

/* [Plate Dimensions] */

plate_d = 200;

plate_h = 3;

plate_chamfer = 1;

/* [Bracket Mount Dimensions] */

mount_offset = 10;

mount_hole_d = 5;

mount_hole_spacing = 33;

/* [Hang Holes] */

hang_hole_d = 5;

hang_hole_spacing = 170;

hang_hold_offset = -40;

/* [Feet Lift]*/

foot_lift = 25;

foot_size = [20, 10];

foot_taper = 1;

foot_offset = 20;

foot_spacing = 125;

foot_spin = 40;

top_foot_spacing = 130;

top_foot_offset = -40;

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustment value for cutouts
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

module plate(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[plate_d, plate_d/2, plate_h]) {
    back(plate_d/4)
    front_half(s=2*plate_d)
      cyl(d=plate_d, h=plate_h, chamfer2=plate_chamfer);

    children();
  }
}

diff() plate() {
  fwd(mount_offset)
  tag("remove")
    ycopies(n=2, spacing= mount_hole_spacing)
    cyl(d=mount_hole_d, h=plate_h + 2*$eps);


  fwd(hang_hold_offset)
  tag("remove")
    xcopies(n=2, spacing=hang_hole_spacing)
    cyl(d=hang_hole_d, h=plate_h + 2*$eps);

  if (foot_size.x * foot_size.y > 0) {
    fwd(foot_offset)
    attach(BOTTOM, TOP, overlap=$eps)
    xcopies(n=2, spacing=foot_spacing)
    prismoid(
      size1=foot_size - [2*foot_taper, 2*foot_taper],
      size2=foot_size,
      spin=($idx % 2 == 1 ? -1 : 1) * foot_spin,
      h=foot_lift + $eps);


    fwd(top_foot_offset)
    attach(BOTTOM, TOP, overlap=$eps)
    xcopies(n=2, spacing=top_foot_spacing)
    prismoid(
      size1=foot_size - [2*foot_taper, 2*foot_taper],
      size2=foot_size,
      h=foot_lift + $eps);
  }
}

