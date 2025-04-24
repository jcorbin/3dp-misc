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
cap_id = 40;

// Cap Wall Thickness.
cap_wall = 3;

// Height of cap tubular section.
cap_depth = 29;

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

lift = 25;

{

  h = cap_depth + cap_wall;
  chamfer1 = rim_chamfer;
  chamfer2 = rim_chamfer;

  r = cap_od / 2;
  extra = lift - r;

  outline = turtle([
    "left", 180,
    "move", r + extra,
    "arcright", r, 180,
    "move", r + extra,
  ], state=[r + extra/2, -r]);

  profile = turtle([
    "right", 45,
    "move", sqrt(2)*chamfer2,
    "right", 45,
    "move", h - chamfer1 - chamfer2,
    "right", 45,
    "move", sqrt(2)*chamfer1,
  ], state=[
    [[-chamfer2, h/2]],
    [1, 0],
    90, 0
  ]);

  difference() {
    hull() path_sweep(profile, outline);
    down((cap_depth - h)/2)
    cyl(d=cap_id, h=cap_depth+$eps, chamfer1=rim_chamfer)
      attach(TOP, BOTTOM, overlap=$eps + rim_chamfer)
        cyl(d=cap_id + 2*rim_chamfer, h=4*rim_chamfer, chamfer1=rim_chamfer);
  }


  if (bump > 0 && bump_count > 0) {
    zrot_copies(n=bump_count)
    left(cap_id/2)
    down($eps)
    down(bump_inset)
    up(h/2)
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
