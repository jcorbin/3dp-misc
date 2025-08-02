include <BOSL2/std.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Mode Parameters] */

mode = 0; // [0:Anchor, 1:Smol Test]

/* [Part Parameters] */

tolerance = 0.4;

shaft_d =  16.2;

// TODO shaft ribs?

foot_size = [ 18.2, 18.4 ];

anchor_size = [ 120, 30 ];

rounding = undef;

chamfer = 5;

// TODO weight inserts

module holder_void(h, anchor = CENTER, spin = 0, orient = UP) {
  trans = foot_size.x - shaft_d;
  d1 = foot_size.x + 2*tolerance;
  d2 = shaft_d + 2*tolerance;
  fh = foot_size.y + $eps;
  attachable(anchor, spin, orient, d=max(d1, d2), h=max(h, fh)) {
    down((h - fh)/2 - $eps)
    cyl(h=fh, d=d1) {
      attach(TOP, BOTTOM)
        cyl(h=trans, d1=d1, d2=d2);
      attach(BOTTOM, TOP, overlap=h - $eps)
        cyl(h=h, d=d2);
    }
    children();
  }
}

module anchnut(d=undef, h=undef, anchor = CENTER, spin = 0, orient = UP) {
  cd = is_undef(d) ? anchor_size.x : d;
  ch = is_undef(h) ? anchor_size.y : h;

  attachable(anchor, spin, orient, d=cd, h=ch) {
    diff() cyl(d=cd, h=ch, rounding2=rounding, chamfer2=chamfer) {
      tag("remove")
      attach(TOP, BOTTOM, overlap=anchor_size.y + $eps)
        holder_void(h=anchor_size.y + 2*$eps);
    }
    children();
  }
}

module preview_cut() {
  if ($preview)
    front_half(s=250) children();
  else
    children();
}

preview_cut() anchnut(
  d=mode == 1 ? 40 : undef,
  orient=$preview ? UP : DOWN
);

// {
//   // position(TOP) #sphere(1);
//   %show_anchors();
//   #cube($parent_size, center=true);
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
