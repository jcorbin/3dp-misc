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

// Shell wall thickness.
wall = 2;

// Button outer size, diamter X height.
body_size = [ 15, 6.5 ];

/* [Part Selection] */

mode = 100; // [0:Assembly, 1:Body, 100:Dev]

/// dispatch / integration

module main() {
  if (mode == 0) {
    assembly();
  }
  else if (mode == 1) {
    body(body_size.x, body_size.y);
  }
  else if (mode == 100) {
    dev();
  }
}

module assembly() {

  body(body_size.x, body_size.y);
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

module base(d, h,
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

module body(d, h,
  wall = wall,
  bar = [2, 1],
  anchor = CENTER, spin = 0, orient = UP,
) {
  hole_d = d - 2*wall;
  attachable(anchor, spin, orient, d=d, h=h) {
    diff()
    base(d=d, h=h, chamfer=0.5) {
      tag("remove")
      attach(BOTTOM, TOP, overlap=hole_d/2)
        onion(d=hole_d, cap_h=h - wall);
      tag("keep")
      up(bar.y)
      // zrot_copies(rots=[-45, 45])
      attach(BOTTOM, FRONT)
        cuboid(
          size=[hole_d + 2*$eps, bar.y, bar.x],
          rounding=bar.y*0.4, edges=[
            [1, 0, 1, 0], // yz -- +- -+ ++
            [0, 0, 0, 0], // xz
            [0, 0, 0, 0], // xy
          ]);

    }
    children();
  }
}

use <noto-emoji-2.051/fonts/NotoColorEmoji.ttf>;

module dev() {

  // ⭐
  // 🌟
  // ✴️
  // ✨
  // ✳️
  // ❇️
  
  // use <NotoEmoji-VariableFont_wght.ttf>
  // font = "Noto Emoji:style=Regular";
  //             text("🌠⚙♻↔♥🌱🍔",size=20,font=font);
  // echo(textmetrics("🌠⚙♻↔♥🌱🍔",size=20,font=font));

  minkowski() {

    text3d(
      "♥️",
      // "⭐",
      // "🌟",
      // "✴️",
      // "✨",
      // "✳️",
      // "❇️",

      $eps, center=true,

      // TODO params
      size=10,
      // font="Noto Sans:style=Black",
      // font="Noto Sans Symbols:style=Black",
      // font="Noto Sans Symbols 2:style=Regular",
      font="Noto Emoji:style=Regular",
    );

    sphere(1); // TODO param

  }

  // body(15, 6.5)
  // // base_reference_15()
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
