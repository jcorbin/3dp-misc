include <BOSL2/std.scad>
include <BOSL2/screws.scad>

/* [Plate Dimensions] */

plate_d = 200;

plate_h = 5;

plate_chamfer = 1;

/* [Bracket Mount Dimensions] */

mount_offset = 10;

mount_screw = "M5";

mount_screw_tol = 0.1;

mount_nut_tol = 0.6;

mount_hole_spacing = 33;

/* [Hang Holes] */

hang_hole_d = 5;

hang_hole_spacing = 50;

hang_hold_offset = -40;

/* [Rim Lift] */

rim_lift = 25;

rim_width = 10;

rim_gap = 25;

rim_taper = 1;

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

module rim(anchor = CENTER, spin = 0, orient = UP) {
  if (rim_lift > 0 && rim_width > 0) {
    h = rim_lift + $eps;

    attachable(anchor, spin, orient, size=[plate_d, plate_d/2, h]) {
      tag_scope("rim")
      diff()
        back(plate_d/4)
        front_half(s=2*plate_d)
        tube(od1=plate_d - rim_taper*2, od2=plate_d, wall=rim_width, h=h) {
          tag("remove")
          down(h/2 - $eps)
          attach(FRONT, FRONT, overlap=plate_d/4)
            prismoid(
              size2=[rim_gap, plate_d/2],
              size1=[rim_gap + 4*rim_taper, plate_d/2],
              h=2*h);
        }

      children();
    }
  }
}

module mount_hole(anchor = CENTER, spin = 0, orient = UP, h=10) {
  mount_screw_d = struct_val(screw_info(mount_screw), "diameter");
  mount_nut_d = struct_val(nut_info(mount_screw), "width");
  mount_nut_h = struct_val(nut_info(mount_screw), "thickness");
  hh = min(plate_h/2, mount_nut_h/2) + mount_nut_tol;
  d = mount_screw_d + 2*mount_screw_tol;

  attachable(anchor, spin, orient, d=d, h=h) {
    cyl(d=d, h=h)
      attach(BOTTOM, TOP, overlap=hh)
      cyl(d=mount_nut_d + 2*mount_nut_tol, h=hh, $fn=6);

    children();
  }
}

diff() plate() {
  fwd(mount_offset)
  tag("remove")
    ycopies(n=2, spacing=mount_hole_spacing)
    mount_hole(h=plate_h + 2*$eps);

  fwd(hang_hold_offset)
  tag("remove")
    xcopies(n=2, spacing=hang_hole_spacing)
    cyl(d=hang_hole_d, h=plate_h + 2*$eps);

  attach(BOTTOM, TOP, overlap=$eps) rim();
}
