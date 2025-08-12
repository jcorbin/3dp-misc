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

// Diamter of interlocking hexagonal dovetail.
interlock_d = 8;

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

mode = 10; // [0:Assembly, 10:Test Rail, 11:Rail, 100:Dev, 101:Rail Profile]

/* [Target Filter Panel] */
filter_size = [
  20 * 25.4,
  20 * 25.4,
   1 * 25.4
];

filter_frame = [ 25, 1 ];

filter_spacing = filter_size.x + filter_size.z + 2*wall;

filter_slot = [
  filter_size.z + 2*tolerance,
  filter_frame.x + filter_frame.y // TODO + grip room
];

filter_slot_chamfer = 1;

rail_width = rail_wall + filter_slot.x + rail_wall + filter_slot.y;

rail_fillet = sqrt(2 * ( filter_slot.y - rail_wall*1.5 )^2);

module filter_panel(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=filter_size) {
    render() diff()
      cuboid(filter_size) {
      tag("remove")
      attach([TOP, BOTTOM], BOTTOM, overlap=filter_frame.y)
      cuboid([
        filter_size.x - 2*filter_frame.x,
        filter_size.y - 2*filter_frame.x,
        filter_frame.y + $eps
      ]);
      // TODO model baffle triangles
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

  // TODO slot draft angle ; inteead of lip chamfer?

  moves = [
    "move", wid,

    "turn",

    "move", wall,
    "turn",
    "move", x_slot.x,
    "turn", -90,
    "move", x_slot.y,
    "turn", -90,
    "move", x_slot.x,
    "turn",
    "move", wall,

    "turn", 45,
    "move", inner_plate,
    "turn", 45,

    "move", wall,
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

module rail_body(h,
  chamfer1 = chamfer,
  chamfer2 = 0,
  anchor = CENTER, spin = 0, orient = UP
) {
  prof = rail_profile();

  size = [
    struct_val(prof, "width"),
    struct_val(prof, "height"),
    h
  ];

  wall = struct_val(prof, "wall");

  x_slot = struct_val(prof, "x_slot");
  y_slot = struct_val(prof, "y_slot");
  outer_rounding = struct_val(prof, "outer_rounding");
  thru_loc = outer_rounding - thru_offset;

  pivot = [ wall, wall ];

  x_slot_at = [ size.x/2 - x_slot.y, 0 - x_slot.x/2 ];
  y_slot_at = [ 0 - y_slot.y/2, size.y/2 - x_slot.x ];
  inner_at = [ wall/2 + size.x/4, wall/2 + size.y/4 ];
  spine_at = rot(-45, cp=pivot, p=x_slot_at );

  attachable(anchor, spin, orient, size=size, anchors=[
    named_anchor("x_slot", [ x_slot_at.x, x_slot_at.y, 0 ], RIGHT),
    named_anchor("y_slot", [ y_slot_at.x, y_slot_at.y, 0 ], BACK),
    named_anchor("inner", [ inner_at.x, inner_at.y, 0 ], [1, 1, 0]),
    named_anchor("inner_up", [ inner_at.x, inner_at.y, size.z/2 ], UP),
    named_anchor("inner_down", [ inner_at.x, inner_at.y, -size.z/2 ], DOWN),

    named_anchor("pivot", [ pivot.x, pivot.y, 0 ], UP),
    named_anchor("pivot_up", [ pivot.x, pivot.y, size.z/2 ], UP),
    named_anchor("pivot_down", [ pivot.x, pivot.y, -size.z/2 ], DOWN),

    named_anchor("spine", [ spine_at.x, spine_at.y, 0 ], DOWN),
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
  prof = rail_profile();
  size = [
    struct_val(prof, "width"),
    struct_val(prof, "height"),
    h
  ];
  wall = struct_val(prof, "wall");

  attachable(anchor, spin, orient, size=size) {

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
        // TODO wants to use a spine or pivot named anchor

        // TODO why is this necessary... the interior edge of x-slot back is slightly off
        interlock_fudge = 0.1;

        interlock_male = round_corners(hexagon(d=interlock_d), method="smooth", joint=[
          chamfer,
          0,
          0,
          chamfer,
          chamfer,
          chamfer,
        ]);

        interlock_female = round_corners(hexagon(d=interlock_d + tolerance), method="smooth", joint=[
          chamfer,
          0,
          0,
          chamfer,
          chamfer,
          chamfer,
        ]);
       
        up(size.z/2)
        up(interlock_d*sqrt(3)/4)
        down($eps)
        back(wall)
        right(wall - interlock_fudge)
          path_sweep(interlock_male, arc(r=25, angle=[-90,-180]));

        tag("remove") {
          down(size.z/2)
          up(interlock_d*sqrt(3)/4)
          down($eps)
          back(wall)
          right(wall - interlock_fudge)
            path_sweep(interlock_female, arc(r=25, angle=[-89,-191]));
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
          fwd(label_size)
            text3d(str("H", h), h=label_depth_bottom+$eps, size=label_size, anchor=CENTER, atype="ycenter");
        }

      }

      // TODO interior attachment system, e.g. attach("inner", ...) thread holes

    }

    children();
  }


}

// TODO filter grip bumps

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
