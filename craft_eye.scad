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

// General wall thickness between voids
wall = 1.2;

/* [Designed Supports] */

// Interface gap between support and supported part.
support_gap = 0.2;

// Thickness of support walls.
support_width = 0.8;

// Thickness of internal support struts.
support_strut = 0.4;

// Thickness of footer support walls that run parallel to and underneath floating external walls.
support_wall_width = 2.4;

/* [Part Selection] */

mode = 100; // [0:Assembly, 100:Dev]

// Section cutaway in preview mode.
preview_cut = false;

// Show top interlock interference ghost.
full_arc_preview = true;

// Show support walls in preview, otherwise only active in production renders.
$support_preview = false;

/// dispatch / integration

module main() {
  if (mode == 0) {
    assembly();
  }
  else if (mode == 100) {
    dev();
  }
}

module assembly() {

  // TODO body ( w/ attach )
  // TODO glyph

}

module base_reference(anchor = CENTER, spin = 0, orient = UP) {
  d = 10;
  h = 4.35;
  attachable(anchor, spin, orient, d=d,h=h) {
    down(h/2)
    right(52.585)
    fwd(39.18)
      import("craft_buttons/Blank Eye.stl");
    children();
  }
}

module base_reference_15(anchor = CENTER, spin = 0, orient = UP) {
  d = 15;
  r = d/2;
  h = 6.5;
  attachable(anchor, spin, orient, d=d,h=h) {
    left(r)
    fwd(r)
    down(h/2)
      import("craft_buttons/Blank Eye 15mm.stl");
    children();
  }
}

module base(
  d,
  h,
  base = 1.5,
  chamfer = 0,
  anchor = CENTER, spin = 0, orient = UP,
) {
  r = d/2;
  z = default(h, r);

  // TODO fully spherical top
  prof = let (
    basic = [
      [ 0, 0 ],
      [ r, 0 ],
      [ r, base ],
      [ r, z ],
      [ 0, z ],
    ],
    cut = round_corners(basic, method="chamfer", joint=[
      0,
      chamfer,
      0,
      0,
      0,
    ]),
    a = z - base,
    smooth = round_corners(cut, method="smooth", k=1.0, joint=[
      0,
      0,
      0,
      0,
      a,
      0,
    ]),
  ) fwd(z/2, smooth);

  attachable(anchor, spin, orient, d=d, h=z) {
    rotate_sweep(prof);
    children();
  }
}

module dev() {

  // echo(str("prof", prof));
  // color("red")
  //   stroke(prof, width=feature);
  //   // down(.2) polygon(struct_val(prof, "basic_path"));
  // // color("blue") down(.1) polygon(struct_val(prof, "cut_path"));
  // // color("yellow") polygon(struct_val(prof, "smooth_path"));

  // #cyl(d=10, h=4.35, anchor=BOTTOM, rounding=2);

  // #cuboid(
  //   size=[ 10, 10, 4.35 ],
  //   anchor=BOTTOM,
  //   rounding=5, edges=[
  //     [0, 0, 0, 0], // yz -- +- -+ ++
  //     [0, 0, 0, 0], // xz
  //     [1, 1, 1, 1], // xy
  //   ]);

  // #cyl(d=10, h=1.5, anchor=BOTTOM)
  //   attach(TOP, CENTER)
  //   top_half()
  //   sphere(d=10);

  // #base(d=10, h=4.35, chamfer=0.5);
  // base_reference()

  wall = 1.5;
  d = 15;
  h = 6.5;
  bar = [2, 1];

  // back_half()
  diff()
  base(d=d, h=h, chamfer=0.5)
  // base_reference_15()
  // body()
  // // glyph()
  {

    hole_d = d - 2*wall;

    tag("remove")
      attach(BOTTOM, TOP, overlap=hole_d/2)
      onion(d=hole_d, cap_h=h - wall);

    tag("keep")
      up(bar.y)
      attach(BOTTOM, FRONT)
      cuboid(
        size=[
          hole_d + 2*$eps,
          bar.y,
          bar.x,
        ],
        rounding=bar.y*0.4, edges=[
          [1, 0, 1, 0], // yz -- +- -+ ++
          [0, 0, 0, 0], // xz
          [0, 0, 0, 0], // xy
        ]);

    // %show_anchors(std=false);
    // attach([
    //   "mount_up_0",
    //   "mount_up_1",
    //   "mount_up_2",
    //   "mount_up_3",
    // ]) anchor_arrow();
    // zrot(-45)
    // #cube([ feature, 2*$parent_size.y, 2*$parent_size.z ], center=true);
    // %cube($parent_size, center=true);
  }

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

module restore_part(part) {
  req_children($children);
  $parent_geom = part[1];
  $anchor_inside = part[2];
  T = part[3];
  $parent_parts = [];
  multmatrix(T)
    children();
}

// like cumsum, but only sums "after" each ; therefore starts with 0, and final
// value is dropped.
function postsum(v) =
  v==[] ? [] :
  assert(is_consistent(v), "\nThe input is not consistent." )
  [for (a = 0, i = 0; i < len(v); a = a+v[i], i = i+1) a];

function pcb_part_size(info, pcb_h) = let (
  size = struct_val(info, "size"),
  d = struct_val(info, "d"),
  reg = struct_val(info, "region"),
  h = struct_val(info, "h", pcb_h),
)
  is_def(reg) ? let(
    bnd = pointlist_bounds(is_region(reg) ? flatten(reg) : reg),
    s2 = bnd[1] - bnd[0],
  ) [s2.x, s2.y, h]
  : is_def(d) ? [d, d, h]
  : size;

module if_support() {
  if (!$preview || $support_preview) {
    children();
  }
}

function scalar_vec2(v, dflt) =
  is_undef(v)? undef :
  is_list(v)? [for (i=[0:1]) default(v[i], default(dflt, 0))] :
  !is_undef(dflt)? [v,dflt] : [v,v];

module support_wall(
  h, l,
  gap = support_gap,
  width = support_width,
  strut = support_strut,
  anchor = CENTER, spin = 0, orient = UP
) {
  if_support()
  tag("keep")
  attachable(anchor, spin, orient, size=[width, l, h]) {
    sparse_wall(
      h=h - 2*gap,
      l=l - 2*gap,
      thick=width,
      strut=strut);

    children();
  }
}

function ngon_max_bottom(path) = let (
  bounds = pointlist_bounds(path),
) [
  for (pt = path)
    pt.y == bounds[0].y
      ? [pt.x < 0 ? bounds[0].x : bounds[1].x, pt.y]
      : pt
];

function cutaway_shape(w, h, shape) = let (
  cut_bounds = pointlist_bounds(shape),
  cut_x = cut_bounds[1].x + w,
  cut_y = h,
  bot_y = cut_bounds[0].y,
  bot_x = cut_bounds[0].x,
  top_y = cut_bounds[1].y,
  slant_from = [bot_x, top_y],
  max_slant_to = [cut_x, cut_y + $eps],
  cut_out = [cut_x, bot_y - $eps],

  basic = [
    cut_out,
    [bot_x - chamfer - $eps, bot_y - $eps],
    [bot_x, bot_y+ chamfer],
    slant_from,
    line_intersection(
      [ slant_from, slant_from + [ 1, 1 ] ],
      [ cut_out, max_slant_to ],
    ),
  ],
  out = round_corners(basic, method="smooth", joint=[0, 0, 0, 2*chamfer, 0]),
) out;

function interlock_profile(
  n=interlock_ngon,
  d=interlock_d,
  tolerance=0,
  chamfer=interlock_chamfer,
  sharp=false,
  open=false,
) = let (
  points = n % 2 == 0
    ? regular_ngon(n=n, d=d + tolerance, align_side=[0, -1])
    : regular_ngon(n=n, d=d + tolerance, align_tip=[0, 1]),
  chamfer_points = len(points)-2,
  chamfers = n % 2 == 0
    ? concat(
      [0, 0],
      repeat(chamfer, floor(chamfer_points/2)-1),
      repeat(sharp ? 0 : chamfer, 2),
      repeat(chamfer, floor(chamfer_points/2)-1),
    )
    : concat(
      [sharp ? 0 : chamfer],
      repeat(chamfer, floor(chamfer_points/2)),
      [0, 0],
      repeat(chamfer, floor(chamfer_points/2))
    ),
) round_corners(open ? ngon_max_bottom(points) : points, method="smooth", joint=chamfers);

module preview_cut(v=BACK, s=10000) {
  if ($preview && preview_cut)
    half_of(v=v, s=s) children();
  else
    children();
}

main();
