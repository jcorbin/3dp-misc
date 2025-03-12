include <BOSL2/std.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Part Parameters] */

// Cap Inner Diameter.
cap_id = 19.5;

// Cap Wall Thickness.
cap_wall = 2;

// Height of cap tubular section.
cap_depth = 20;

// Inner and outer chamfer around the rim.
rim_chamfer = 0.4;

// Proportion of tip sphere to cut off / truncate.
tip_cut = 0.2;

// Cap Outer Diameter.
cap_od = cap_id + 2*cap_wall;

// Grip bump depth inside cap_id.
bump = 0.75;

// Grip offset from tube rim.
bump_inset = 2;

// Radial grip count.
bump_count = floor(PI * cap_id / (2*bump) / 2);

{
  // Sphere truncation remainder.
  rem = cap_od/2*(1.0 - tip_cut);

  // Total assembly height.
  total_h = cap_depth + $eps + rem;

  down(total_h/2) // recenter geometry around origin
  yrot(180) // reorient to print on truncated flat face
  bottom_half() down(cap_depth/2 + rem) // truncate sphere tip from tube+sphere assembly
  tube(h=cap_depth+$eps, id=cap_id, od=cap_od, ichamfer1=rim_chamfer, ochamfer1=rim_chamfer)
    attach(TOP, CENTER, overlap=$eps)
    top_half() spheroid(d=cap_od, style="aligned");

  if (bump > 0 && bump_count > 0) {
    zrot_copies(n=bump_count)
    left(cap_id/2)
    down($eps)
    down(bump_inset)
    up(total_h/2)
    cyl(r=bump, h=cap_depth+$eps - bump_inset, anchor=TOP, chamfer2=bump);
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
