include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>;

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
chamfer = 0.5;

// General wall thickness between voids
wall = 1.2;

/* [Rail Body Shape] */

// Main outer corner rounding; the big one.
rail_outer_rounding = 30;

// Minor outer corner rounding; these are the outside corners of the interior edges.
rail_inner_rounding = 2.4;

// Wall thickness beside filter slots.
rail_wall = 12;

/* [Rail Interlocks] */

// Optional pivot pin to index each rail before engaging interlock dovetail.
pivot_pin = 6;

// Diamter of interlocking dovetail.
interlock_d = 8;

// Corner smoothing amount for interlocking dovetail; not technically a crisp chamfer, but the metric applies similarly to a chamfer depth.
interlock_chamfer = 1.5;

// Degree of interlocking dovetail polygon; for large enough dovetail diameter, a pentagon is better since it comes to a point like a teardrop shape, decreasing stringing inside bottom cavity.
interlock_ngon = 5;

/* [Bore and Thru holes] */

// Optional vertical bore hole diamter thru rail spine.
bore_d = 10;

// Optional horizontal hole diamter thru rail spine, joining X and Y exterior faces.
thru_d = 10;

// Z spacing of horizontal thru holes.
thru_every = 30;

// Z setback of horizontal thru holes from part top/bottom.
thru_margin = 15;

// Additional X/Y setback of thru hole bores from outer rounding start; postive values make the thru hole more shallow.
thru_offset = 5;

/* [Rail Size Lables] */

// Font size.
label_size = 5;

// Top emboss depth.
label_depth_top = 0.4;

// Bottom emboss depth.
label_depth_bottom = 0.4;

/* [Part Selection] */

mode = 10; // [0:Assembly, 10:Test Rail, 11:Rail, 100:Dev, 101:Rail Profile, 102:Filer Panel]

/* [Target Filter Panel] */
filter_size = [

  // NOTE these are nominally 20x20x1 (all in inches) panels on spec...
  //  ... but labeled actual size is 500.1 x 500.1 x 19.1

  // 20 * 25.4,
  // 20 * 25.4,
  // 1 * 25.4

  500.1,
  500.1,
  19.1

];

filter_cardboard_thickness = 1;

filter_inside_frame = 18;

filter_outside_frame = 25;

filter_baffle_pitch = 20;

filter_baffle_thickness = 2;

filter_frame = [ 25, 1 ];

filter_spacing = filter_size.x + filter_size.z + 2*wall;

filter_slot = [
  filter_size.z + 2*tolerance,
  filter_frame.x + filter_cardboard_thickness // TODO + grip room
];

filter_slot_chamfer = 1;

rail_width = rail_wall + filter_slot.x + rail_wall + filter_slot.y;

rail_fillet = sqrt(2 * ( filter_slot.y - rail_wall*1.5 )^2);

function interlock_profile(
  n=interlock_ngon,
  d=interlock_d,
  tolerance=0,
  chamfer=interlock_chamfer,
) = let (
  points = n % 2 == 0
    ? regular_ngon(n=n, d=d + tolerance, align_side=[0, -1])
    : regular_ngon(n=n, d=d + tolerance, align_tip=[0, 1]),
  chamfer_points = len(points)-2,
  chamfers = n % 2 == 0
    ? concat(
      [0, 0],
      repeat(chamfer, chamfer_points)
    )
    : concat(
      repeat(chamfer, ceil(chamfer_points/2)),
      [0, 0],
      repeat(chamfer, floor(chamfer_points/2))
    ),
) round_corners(points, method="smooth", joint=chamfers);

module filter_panel(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=filter_size) {
    render() diff() cuboid(filter_size) {

      interior_size = filter_size - [
        2*filter_cardboard_thickness,
        2*filter_cardboard_thickness,
        2*filter_cardboard_thickness,
      ];

      // front window cutout
      tag("remove")
        attach(TOP, BOTTOM, overlap=filter_cardboard_thickness+$eps)
        cuboid([
          filter_size.x - 2*filter_outside_frame,
          filter_size.y - 2*filter_outside_frame,
          filter_cardboard_thickness + 2*$eps
        ]);

      // rear lattice grid cutout
      face_mask(BOTTOM) {
        region = [
          filter_size.x - 2*filter_inside_frame,
          filter_size.y - 2*filter_inside_frame,
        ];
        inside = rect(region);
        intersection() {
          cuboid([region.x, region.y, 2]);
          zrot(45)
          grid_copies(inside=1.5*inside, spacing=105)
            cuboid([95, 95, 2], chamfer=16, edges="Z");
        }
      }

      // interior hollow
      tag("remove")
        attach(CENTER, CENTER)
        cuboid(interior_size);

      // embafflement
      baffle_points = let(
        length = filter_size.x - 2*filter_baffle_thickness,
        depth = filter_size.z - 2*filter_baffle_thickness,
        pitch = filter_baffle_pitch,
        hap = pitch/2,
        ang = 2*atan2(depth, hap),
        count = ceil(length/pitch),
        mid = turtle([
          "angle", ang,
          "length", sqrt(hap^2 + depth^2),
          "turn", -ang/2,
          "move",
          "repeat", count, [
            "left", "move",
            "right", "move",
          ],
        ]),
        off = filter_baffle_thickness/2,
      ) concat(
        move([-count*pitch/2, depth/2 + off], mid),
        reverse(move([-count*pitch/2, depth/2 - off], mid))
      );

      tag("keep")
      intersection() {
        cuboid(interior_size);
        xrot(90)
        color("grey")
        linear_extrude(height=filter_size.y - 2*filter_cardboard_thickness, center=true)
          polygon(points = baffle_points);
      }
    }
    children();
  }
}

function rail_profile(
  x_slot = filter_slot,
  y_slot = filter_slot,
  x_slot_chamfer = filter_slot_chamfer,
  y_slot_chamfer = filter_slot_chamfer,
  wall = rail_wall,
  outer_rounding = rail_outer_rounding,
  inner_rounding = rail_inner_rounding,
) = let (
  wid = wall + y_slot.x + wall + x_slot.y,
  hei = wall + x_slot.x + wall + y_slot.y,

  start = [-wid/2, -hei/2],

  inner_plate = sqrt(y_slot.y^2 + x_slot.y^2),
  inner_travel = wall, // TODO kill this, let rounding handle the blend to 45? leave it 90?

  // TODO slot draft angle ; inteead of lip chamfer?

  moves = [
    "move", wid,

    "turn",

    "move", wall,
    "turn",
    "move", x_slot.y,
    "turn", -90,
    "move", x_slot.x,
    "turn", -90,
    "move", x_slot.y,
    "turn",

    "move", inner_travel,
    "turn", 45,
    "move", inner_plate,
    "turn", 45,
    "move", inner_travel,

    "turn",
    "move", y_slot.y,
    "turn", -90,
    "move", y_slot.x,
    "turn", -90,
    "move", y_slot.y,
    "turn",
    "move", wall,
  ],

  basic_path = turtle(moves, state=[[start], [1, 0], 90, 0]),

  cut_path = round_corners(basic_path, method="chamfer", cut=[
    0,
    0,
    x_slot_chamfer,
    0,
    0,
    x_slot_chamfer,
    0,
    0,
    y_slot_chamfer,
    0,
    0,
    y_slot_chamfer,
    0,
  ]),

  smooth_path = round_corners(cut_path, method="smooth", k=0.5, joint=[
    outer_rounding,
    inner_rounding,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    chamfer,
    inner_rounding
  ]),

) [
  ["x_slot", x_slot],
  ["y_slot", y_slot],
  ["x_slot_chamfer", x_slot_chamfer],
  ["y_slot_chamfer", y_slot_chamfer],
  ["wall", wall],
  ["outer_rounding", outer_rounding],
  ["inner_rounding", inner_rounding],

  ["inner_plate", inner_plate],
  ["width", wid],
  ["height", hei],
  ["moves", moves],
  ["basic_path", basic_path],
  ["cut_path", cut_path],
  ["smooth_path", smooth_path],
];

function rail_body(h) = let(
  prof = rail_profile(),
  size = [
    struct_val(prof, "width"),
    struct_val(prof, "height"),
    h
  ],

  wall = struct_val(prof, "wall"),
  x_slot = struct_val(prof, "x_slot"),
  y_slot = struct_val(prof, "y_slot"),

  pivot_at = [
    size.x/2 - x_slot.y,
    size.y/2 - y_slot.y,
    0 ],

  x_slot_at = [
    pivot_at.x,
    -size.y/2 + wall + x_slot.x/2,
    0 ],
  y_slot_at = [
    -size.x/2 + wall + y_slot.x/2,
    pivot_at.y,
    0 ],

  outer_rounding = struct_val(prof, "outer_rounding"),
  thru_loc = outer_rounding - thru_offset,

  inner_at = [
    size.x/2 - x_slot.y/2,
    size.y/2 - y_slot.y/2,
    0 ],

  spine_at = rot(-45, cp=pivot_at, p=[x_slot_at.x, x_slot_at.y, 0] ),
) concat(prof, [
  ["size", size],
  ["x_slot_at", x_slot_at],
  ["y_slot_at", y_slot_at],
  ["thru_loc", thru_loc],
  ["pivot_at", pivot_at],
  ["inner_at", inner_at],
  ["spine_at", spine_at],
]);

module rail_body(h,
  chamfer1 = chamfer,
  chamfer2 = 0,
  anchor = CENTER, spin = 0, orient = UP
) {
  prof = rail_body(h);
  size = struct_val(prof, "size");
  wall = struct_val(prof, "wall");
  thru_loc = struct_val(prof, "thru_loc");
  pivot_at = struct_val(prof, "pivot_at");
  inner_at = struct_val(prof, "inner_at");
  spine_at = struct_val(prof, "spine_at");

  attachable(anchor, spin, orient, size=size, anchors=[
    named_anchor("x_slot",  struct_val(prof, "x_slot_at"), RIGHT),
    named_anchor("y_slot",  struct_val(prof, "y_slot_at"), BACK),
    named_anchor("inner", inner_at, [1, 1, 0]),
    named_anchor("inner_up", [ inner_at.x, inner_at.y, size.z/2 ], UP),
    named_anchor("inner_down", [ inner_at.x, inner_at.y, -size.z/2 ], DOWN),

    named_anchor("pivot",  pivot_at, UP),
    named_anchor("pivot_up", [ pivot_at.x, pivot_at.y, size.z/2 ], UP),
    named_anchor("pivot_down", [ pivot_at.x, pivot_at.y, -size.z/2 ], DOWN),

    named_anchor("spine",  spine_at, DOWN),
    named_anchor("spine_up", [ spine_at.x, spine_at.y, size.z/2 ], UP),
    named_anchor("spine_down", [ spine_at.x, spine_at.y, -size.z/2 ], DOWN),

    named_anchor("thru_up", [ -size.x/2 + thru_loc/2, -size.y/2 + thru_loc/2, size.z/2 ], UP),
    named_anchor("thru_down", [ -size.x/2 + thru_loc/2, -size.y/2 + thru_loc/2, -size.z/2 ], DOWN),
    named_anchor("thru_z", [ -size.x/2 + thru_loc/2, -size.y/2 + thru_loc/2, 0 ], UP),
    named_anchor("thru_x", [ -size.x/2 + thru_loc, -size.y/2, 0 ], [ 1, -1, 0 ]),
    named_anchor("thru_y", [ -size.x/2, -size.y/2 + thru_loc, 0 ], [ -1, 1, 0 ]),
  ]) {
    offset_sweep(
      struct_val(prof, "smooth_path"),
      h=h,
      cp="box",
      bot=chamfer1 ? os_chamfer(cut=chamfer1) : undef,
      top=chamfer2 ? os_chamfer(cut=chamfer2) : undef,
      anchor=CENTER
    );
    children();
  }
}

module rail(h, anchor = CENTER, spin = 0, orient = UP) {
  prof = rail_body(h);
  size = struct_val(prof, "size");
  wall = struct_val(prof, "wall");

  attachable(anchor, spin, orient, size=size, anchors=[
    named_anchor("x_slot",  struct_val(prof, "x_slot_at"), RIGHT),
    named_anchor("y_slot",  struct_val(prof, "y_slot_at"), BACK),
  ]) {

    diff() rail_body(h) {

      if (bore_d) {
        tag("remove")
        attach("thru_z", BOTTOM, overlap=h/2+$eps)
          cyl(d=bore_d, h=h + 2*$eps, chamfer=-chamfer);
      }

      if (thru_d && thru_every) {
      tag("remove")
        attach("thru_x", FRONT, overlap=60.5)
          zrot(45)
          ycopies(l=h - 2*thru_margin, spacing=thru_every)
          teardrop(d=thru_d, h=75);
      }

      if (pivot_pin > 0) {
        tag("remove") {
          attach("pivot_down", TOP, overlap=5)
            cyl(d1=pivot_pin + 2 * tolerance, d2=pivot_pin - 2*chamfer + 2 * tolerance, h=5+$eps, chamfer1=-chamfer);
        }
        attach("pivot_up", BOTTOM)
          cyl(d1=pivot_pin, d2=pivot_pin - 2*chamfer, h=5, chamfer1=-chamfer);
      }

      if (interlock_d > 0) {
        xat = struct_val(prof, "x_slot_at");
        yat = struct_val(prof, "y_slot_at");
        pat = struct_val(prof, "pivot_at");
        interlock_arc_base = norm([xat.x - yat.x, xat.y - yat.y]);
        interlock_arc_r = norm([xat.x - pat.x, xat.y - pat.y]);
        interlock_arc_ang = 2*asin((interlock_arc_base/2)/interlock_arc_r);

        tag("remove") {
          up(interlock_d/2)
          up(size.z/2)
          right($eps)
          attach("x_slot", BOTTOM)
            cuboid([1.5*interlock_d, 1.5*interlock_d, 5]);

          up(interlock_d/2)
          up(size.z/2)
          back($eps)
          attach("y_slot", BOTTOM)
            cuboid([1.5*interlock_d, 1.5*interlock_d, 5]);
        }

        position("pivot_up")
        let (
          profile = interlock_profile(tolerance=0),
          bounds = pointlist_bounds(profile),
          profile_h = bounds[1].y - bounds[0].y,
        )
        down(tolerance)
        up(profile_h/2)
          path_sweep(profile, arc(r=interlock_arc_r, angle=[
            -134 + interlock_arc_ang/2,
            -136 - interlock_arc_ang/2
          ]));

        tag("remove") {
          position("pivot_down")
          let(
            profile = interlock_profile(tolerance=tolerance),
            bounds = pointlist_bounds(profile),
            profile_h = bounds[1].y - bounds[0].y,
          )
          down(tolerance)
          up(profile_h/2)
            path_sweep(profile, arc(r=interlock_arc_r, angle=[
            -134 + interlock_arc_ang/2,
            -136 - interlock_arc_ang/2
            ]));
        }
      }

      if (label_size > 0) {
        if (label_depth_top > 0) {
          tag("remove")
          position("inner_up")
          down(label_depth_top/2)
          zrot(-45)
          fwd(label_size)
            text3d(str("H", h), h=label_depth_top+$eps, size=label_size, anchor=CENTER, atype="ycenter");
        }

        if (label_depth_bottom > 0) {
          tag("remove")
          position("inner_down")
          up(label_depth_bottom/2)
          zrot(-45)
          xflip()
          fwd(label_size)
            text3d(str("H", h), h=label_depth_bottom+$eps, size=label_size, anchor=CENTER, atype="ycenter");
        }

      }

      // TODO interior attachment system, e.g. attach("inner", ...) thread holes

    }

    children();
  }


}

// TODO interlock-vs-bulkhead interference
// 1. show the co-arc in dev preview
// 2. either trim bulkhead, or tweak interlock placement

// TODO maybe add inner lip filter retention bumps

// TODO fan holder / grip

// TODO base plate holder

// TODO stitch pins for base plate / filter rim

module preview_cut() {
  if ($preview)
    back_half(s=10000) children();
  else
    children();
}

if (mode == 0) {
  ycopies(spacing=filter_spacing)
    filter_panel(orient=FRONT);
  xcopies(spacing=filter_spacing)
    filter_panel(orient=RIGHT);

  // TODO model the box 

  // TODO model the baseplate ; may be 5th filter dba base

  // TODO feet

  // TODO fan holder / grip

  // TODO handles

}

else if (mode == 10) {
  rail(50);
}

else if (mode == 11) {
  // 500 = 200 + 150 + 150

  // 16 * 25.4 = 406.4
  // 406.4 = 200 + 206.4

  // 20 * 25.4 = 508.0
  // 508 = 200 + 179 + 179

  // 25 * 25.4 = 635.0
  // 635 = 200 + 179 + 179 + 95

  // 30 * 25.4 = 762.0
  // 762.0 = 200 + 200 + 179 + 183.0

  // TODO imprint inside for ID
  rail(200);

  // TODO attach buddies to named anchor points
  // filter_panel(orient=FRONT, anchor=LEFT);
  // filter_panel(orient=RIGHT, anchor=FRONT);

}

else if (mode == 100) {

  zrot(-90)
  path_sweep(
    hexagon(
      d=interlock_d,
      rounding=chamfer
    ),
    arc(r=25, angle=-90),
  );

  // {
  // // position(TOP) #sphere(1);
  // // %show_anchors(std=false);
  // // zrot(-45)
  // // #cube([ feature, 2*$parent_size.y, 2*$parent_size.z ], center=true);
  // // #cube($parent_size, center=true);
  // }

}

else if (mode == 101) {
  prof = rail_profile();
  color("red") down(.2) polygon(struct_val(prof, "basic_path"));
  color("blue") down(.1) polygon(struct_val(prof, "cut_path"));
  color("yellow") polygon(struct_val(prof, "smooth_path"));
}

else if (mode == 102) {
  filter_panel(orient=FRONT);
}

// rail(50)
// // rail_body(50)
// {
//   // show_anchors(s = 10, std = false, custom = true);
//   // position(TOP) #sphere(1);
//   %show_anchors(std=false);
//   // zrot(-45)
//   // #cube([ feature, 2*$parent_size.y, 2*$parent_size.z ], center=true);
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
