include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>;
include <BOSL2/screws.scad>;
include <BOSL2/walls.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Part Parameters] */

// General fit tolerance.
tolerance = 0.4;

// Minimum feature size, more or less nozzle size.
feature = 0.4;

// Generic chamfer for things like bed interface and outside non-interface edges.
chamfer = 1.5;

// Generic rounding for anonymous edges.
rounding = 1.5;

wall = 2.0;

/* [Part Selection] */

mode = 100; // [0:Hook, 100:Dev]

/* [Part-iculars] */

// measurements
// - flat top 18.2
// - span 24
// - front height 18.8
// - rear height 10

mount_size = [23, 19];

travel = 25;

travel_ang = 30;

loop_r = 15;

loop_ang = 180;

hook_width = 3.5;

/// dispatch / integration

module main() {
  if (mode == 0) {
  }
  else if (mode == 100) {
    dev();
  }
}

function hook_profile() = let (
  mount_span = mount_size.x + 2*tolerance,
  // travel_span = sin(travel_ang)*travel,
  // loop_span = TODO arc width how
  path = turtle([
    "turn", -90,

    "move", mount_size.y,
    "turn", 90,
    "move", mount_span,
    "turn", 90,
    "move", mount_size.y,

    "turn", -travel_ang,
    "move", travel,

    "arcright", loop_r, loop_ang -travel_ang,
  ]),
  bnds = pointlist_bounds(path),
) move([
    (bnds[0].x - bnds[1].x)/2,
    mount_size.y + (bnds[0].y - bnds[1].y)/2,
  ], path);

module dev() {

  prof = hook_profile();
  inner = offset(prof, delta=-wall/2);
  outer = offset(prof, delta=wall/2);
  hook_shape = concat(inner, reverse(outer));

  // echo(str("prof", prof));
  // color("red") stroke(prof, width=feature);
  // color("blue") stroke(outer, width=feature);
  // color("green") stroke(inner, width=feature);

  // color("blue") polygon(hook_shape);

  linear_sweep(hook_shape, hook_width);

  // color("yellow") polygon(struct_val(prof, "smooth_path"));

  // TODO profile
  // TODO extrude
  // TODO chamfer bottom

  // body(15, 6.5)
  // // glyph()
  // {
  //   // %show_anchors(std=false);
  //   // attach([
  //   //   "mount_up_0",
  //   //   "mount_up_1",
  //   //   "mount_up_2",
  //   //   "mount_up_3",
  //   // ]) anchor_arrow();
  //   // zrot(-45)
  //   // #cube([ feature, 2*$parent_size.y, 2*$parent_size.z ], center=true);
  //   // %cube($parent_size, center=true);
  // }

  // echo(str("prof", prof));
  // color("red")
  //   stroke(prof, width=feature);
  //   // down(.2) polygon(struct_val(prof, "basic_path"));
  // // color("blue") down(.1) polygon(struct_val(prof, "cut_path"));
  // // color("yellow") polygon(struct_val(prof, "smooth_path"));

  // shape = XXX();
  // if ($preview) {
  //   stroke(shape, width=feature);
  // } else {
  //   linear_sweep(shape, 0.4);
  // }
  // // color("red") 
  //   // polygon(shape);
  //   // debug_region(shape);

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

}

// like cumsum, but only sums "after" each ; therefore starts with 0, and final
// value is dropped.
function postsum(v) =
  v==[] ? [] :
  assert(is_consistent(v), "\nThe input is not consistent." )
  [for (a = 0, i = 0; i < len(v); a = a+v[i], i = i+1) a];

function scalar_vec2(v, dflt) =
  is_undef(v)? undef :
  is_list(v)? [for (i=[0:1]) default(v[i], default(dflt, 0))] :
  !is_undef(dflt)? [v,dflt] : [v,v];

module preview_cut(v=BACK, s=10000) {
  if ($preview && preview_cut)
    half_of(v=v, s=s) children();
  else
    children();
}

main();
