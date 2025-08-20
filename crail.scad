include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>;
include <BOSL2/walls.scad>;

/*

# Dev Log

## Draft 1

- bad: naive 25mm slot was far too loose, interlock ring interference show
  stopper
- good: smooth, thru holes seem useful, pivot seems to work, was able to shear
  pivot pin, force the fit, and test interlock after all
- mid: stringing on roof of hexagon interlock channel, flipped text on bottom

## Draft 2

- fixed slot metrics: towards a 19 mm filter (aka 3/4 inch)
- trying an experimental "dumbest fix" for interlock problem: cutaway bottom
  channel
- good: filter friction fit Feels Good Yo; seems we may not need retention
  bumps, interlock now works well
- bad: cutout channel leaves a tiny island on layer 1 that had a 50% chance to
  spaghettifi in my 2 test parts

## Draft 3

- made the pentagonal cavity tip sharp / non-rounded
- cut entire curved arc away from interior bulkhead
- added X and Y slot size labels

## Next

- added top chamfer to pivot pin
- strengthened pivot pin with internal micro fins
- strengthened interlock arc with an internal micro fin
- increased rail rounding

## WIP

- box fan mount; will interlock top side rail
- base plate holder / foot; will interlock bottom side rail

## TODO

- handles, probably integrated into the fan holder, but could be a separate part
- side rails?
- better fan holder, maybe even dynamic to fan size range

*/

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

/* [Designed Supports] */

// Interface gap between support and supported part.
support_gap = 0.2;

// Bridging gap between supports.
support_every = 15;

// Thickness of support walls and internal struts.
support_width = 0.8;

// Thickness of footer support walls that run parallel to and underneath floating external walls.
support_wall_width = 2.4;

/* [Rail Body Shape] */

// Main outer corner rounding; the big one.
rail_outer_rounding = 60;

// Minor outer corner rounding; these are the outside corners of the interior edges.
rail_inner_rounding = 9.5;

// Wall thickness beside filter slots.
rail_wall = 12;

/* [Rail Interlocks] */

// Optional pivot pin to index each rail before engaging interlock dovetail.
pivot_pin = [ 6, 5 ];

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
thru_offset = 20;

/* [Rail Size Labels] */

// Font size.
label_size = 4;

// Font emboss depth.
label_depth = 0.4;

/* [Filter Panel] */

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

/* [Box Fan] */

fan_frame_size = [

  // nominal 20-inch fan witha nominal 22x22x5 inch frame
  22 * 25.4,
  22 * 25.4,
  5 * 25.4

];

fan_frame_width = 25.4; // nominal guess

fan_frame_rounding = 3 * 25.4; // nominal 3-inch rounding

fan_frame_thickness = 2; // nominal guess

/* [Part Selection] */

mode = 10; // [0:Assembly, 10:Test Rail, 11:Rail, 12:Fan Mount, 13:Foot, 100:Dev, 101:Filer Panel, 102:Rail Profile, 103:Interlock Profile]

// Section cutaway in previe mode.
preview_cut = false;

// Show top interlock interference ghost.
full_arc_preview = true;

// Show support walls in preview, otherwise only active in production renders.
$support_preview = false;

/// dispatch / integration

module __customizer_limit__() {}

filter_slot = [
  filter_size.z + 2*tolerance,
  max(filter_inside_frame, filter_outside_frame)
  + filter_cardboard_thickness
  // TODO + grip room
];

filter_slot_chamfer = 1;

rail_width = rail_wall + filter_slot.x + rail_wall + filter_slot.y;

rail_fillet = sqrt(2 * ( filter_slot.y - rail_wall*1.5 )^2);

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
  anchor = CENTER, spin = 0, orient = UP
) {
  wid = scalar_vec2(width);
  if_support()
  tag("keep")
  attachable(anchor, spin, orient, size=[wid.x, l, h]) {
    sparse_wall(
      h=h - 2*gap,
      l=l - 2*gap,
      thick=wid.x,
      strut=wid.y);

    children();
  }
}

/* Distributes sparse support walls within a cubic volume.
 *
 * gap specifies interface gap around all 6 faces of the cube, and may be:
 * - a single number to use constant gap around
 * - a 3-list specifying x/y/x gap values
 * - further within the 3-list, each entry maybe a pair of negative/positive gap values
 * 
 * every specifies an upper bound on wall spacing along the Y axis:
 * - walls will be spaced at most this far apart between starting/ending Y gap offsets
 * - the actual spacing will be adjusted down to evenly distribute size.y after gap
 */
module support_walls(
  size,
  gap = support_gap,
  every = support_every,
  width = support_width,
  wall_width = support_wall_width,
  anchor = CENTER, spin = 0, orient = UP
) {
  if_support()
  tag("keep")
  attachable(anchor, spin, orient, size=size) {
    wid = scalar_vec2(width);

    xgap = scalar_vec2(is_list(gap) ? gap[0] : gap);
    ygap = scalar_vec2(is_list(gap) ? gap[1] : gap);
    zgap = scalar_vec2(is_list(gap) ? gap[2] : gap);
    pre_gap = [xgap[0], ygap[0], zgap[0]];
    post_gap = [xgap[1], ygap[1], zgap[1]];
    foot_gap = max(zgap);

    isize = size - pre_gap - post_gap;

    first_at = wid.x/2;
    last_at = isize.y - wid.x/2;
    at_span = last_at - first_at;
    at_space = at_span / ceil(at_span / every);
    nominal_at = [
      for (y = [ each [first_at : at_space : last_at], last_at ])
      y - isize.y/2
    ];

    xfoot = [
      pre_gap.x == 0 ? wall_width : 0,
      post_gap.x == 0 ? wall_width : 0
    ];
    yfoot = [
      pre_gap.y == 0 ? wall_width : wid.x,
      post_gap.y == 0 ? wall_width : wid.x
    ];

    xthick = flatten([
      xfoot[0] > 0 ? xfoot[0] : [],
      xfoot[1] > 0 ? xfoot[1] : []
    ]);
    ythick = [
      yfoot[0],
      each(repeat(wid.x, len(nominal_at) - 2)),
      yfoot[1]
    ];

    actual_at_x = flatten([
      xfoot[0] > 0 ? -(isize.x - wall_width)/2 : [],
      xfoot[1] > 0 ? (isize.x - wall_width)/2 : []
    ]);
    actual_at_y = [for (i=idx(nominal_at))
      nominal_at[i]
      + (i == 0 ? 1 : -1)
      * (ythick[i] - wid.x)/2
    ];

    translate((pre_gap - post_gap)/2) {

      if (len(actual_at_y) > 0)
      ycopies(spacing=actual_at_y)
      right(xfoot[0] > 0 ? (xfoot[0] - $eps)/2 : 0)
      left(xfoot[1] > 0 ? (xfoot[1] - $eps)/2 : 0)
        support_wall(
          h = isize.z,
          l = isize.x
            - (xfoot[0] > 0 ? xfoot[0] + $eps : 0)
            - (xfoot[1] > 0 ? xfoot[1] + $eps : 0)
            ,
          gap = 0,
          spin = 90,
          width = [ythick[$idx], wid.y]);

      if (len(actual_at_x) > 0)
      xcopies(spacing=actual_at_x)
        support_wall(
          h = isize.z,
          l = size.y - 2*foot_gap,
          gap = 0,
          width = [xthick[$idx], wid.y]);

    }

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

module box_fan(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=fan_frame_size) {
    render() diff() cuboid(fan_frame_size, rounding=fan_frame_rounding, edges="Z") {

      interior_size = fan_frame_size - [
        2*fan_frame_thickness,
        2*fan_frame_thickness,
        2*fan_frame_thickness,
      ];
      interior_rounding = fan_frame_rounding - fan_frame_thickness;

      window_size = [
        fan_frame_size.x - 2*fan_frame_width,
        fan_frame_size.y - 2*fan_frame_width,
        fan_frame_thickness + 2*$eps
      ];
      window_rounding = fan_frame_rounding - fan_frame_width;

      // front/back window cutouts
      tag("remove")
        attach([TOP, BOTTOM], BOTTOM, overlap=fan_frame_thickness+$eps)
        cuboid(window_size, rounding=window_rounding, edges="Z");

      // interior hollow
      tag("remove")
        attach(CENTER, CENTER)
        cuboid(interior_size, rounding=interior_rounding, edges="Z");

      // TODO grills
      // TODO struts
      // TODO spindle
      // TODO blades
      // TODO controls

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

  pivot_at = [
    wid/2 - x_slot.y,
    hei/2 - y_slot.y,
    0 ],
  x_slot_at = [
    pivot_at.x,
    wall - hei/2 + x_slot.x/2,
    0 ],
  y_slot_at = [
    wall - wid/2 + y_slot.x/2,
    pivot_at.y,
    0 ],
  inner_at = [
    wid/2 - x_slot.y/2,
    hei/2 - y_slot.y/2,
    0 ],
  spine_at = rot(-45, cp=pivot_at, p=[x_slot_at.x, x_slot_at.y, 0] ),

  thru_loc = outer_rounding - thru_offset,

  // TODO slot draft angle ; inteead of lip chamfer?

  solid_moves = [
    "move", wid,
    "turn",
    "move", wall + x_slot.x + inner_travel,
    "turn", 45,
    "move", inner_plate,
    "turn", 45,
    "move", inner_travel + y_slot.x + wall,
  ],

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
  solid_basic_path = turtle(solid_moves, state=[[start], [1, 0], 90, 0]),

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

  solid_smooth_path = round_corners(solid_basic_path, method="smooth", k=0.5, joint=[
    outer_rounding,
    inner_rounding,
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

  ["pivot_at", pivot_at],
  ["x_slot_at", x_slot_at],
  ["y_slot_at", y_slot_at],
  ["inner_at", inner_at],
  ["spine_at", spine_at],
  ["thru_loc", thru_loc],

  ["moves", moves],
  ["basic_path", basic_path],
  ["cut_path", cut_path],
  ["smooth_path", smooth_path],

  ["solid_moves", solid_moves],
  ["solid_smooth_path", solid_smooth_path],
];

function rail_body(h) = let(
  prof = rail_profile(),
  size = [
    struct_val(prof, "width"),
    struct_val(prof, "height"),
    h
  ],
) concat(prof, [
  ["size", size],
]);

module rail_body(h, anchor = CENTER, spin = 0, orient = UP,
  solid = false,
  chamfer1 = chamfer,
  chamfer2 = 0,
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
      struct_val(prof, solid ? "solid_smooth_path" : "smooth_path"),
      h=h,
      cp="box",
      bot=chamfer1 ? os_chamfer(cut=chamfer1) : undef,
      top=chamfer2 ? os_chamfer(cut=chamfer2) : undef,
      anchor=CENTER
    );
    children();
  }
}

module pivot_pin(size=pivot_pin, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, d=size.x, h=size.y) {
    cyl(
      h=size.y,
      d1=size.x,
      d2=size.x - 2*chamfer,
      chamfer1=-chamfer,
      chamfer2=chamfer,
    );
    children();
  }
}

module pivot_hole(size=pivot_pin, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, d=size.x, h=size.y) {
    cyl(
      h=size.y + $eps,
      d1=size.x + 2 * tolerance,
      d2=size.x - 2*chamfer + 2 * tolerance,
      chamfer1=-chamfer,
      chamfer2=chamfer,
    );
    children();
  }
}

module rail(h, anchor = CENTER, spin = 0, orient = UP,
  full_arc_preview = false,
  interlock_up = true,
  interlock_down = true,
  solid = false,
  strength_fins = true,
) {
  prof = rail_body(h);
  size = struct_val(prof, "size");
  pivot_at = struct_val(prof, "pivot_at");

  cutaway_slant = solid;
  with_x_slot = !solid;
  with_y_slot = !solid;

  attachable(anchor, spin, orient, size=size, anchors=[
    named_anchor("pivot",  pivot_at, UP),
    named_anchor("pivot_up", [ pivot_at.x, pivot_at.y, size.z/2 ], UP),
    named_anchor("pivot_down", [ pivot_at.x, pivot_at.y, -size.z/2 ], DOWN),

    named_anchor("x_slot",  struct_val(prof, "x_slot_at"), RIGHT),
    named_anchor("y_slot",  struct_val(prof, "y_slot_at"), BACK),
  ]) {
    tag_scope("rail_body")
    diff() rail_body(h, solid = solid) {

      if (bore_d) {
        tag("remove")
        attach("thru_z", BOTTOM, overlap=h/2+$eps)
          cyl(d=bore_d, h=h + 2*$eps, chamfer=-chamfer);
      }

      if (thru_d && thru_every && h >= thru_every + thru_d) {
        tag("remove")
        attach("thru_x", FRONT, overlap=60.5)
          zrot(45)
          ycopies(l=h - 2*thru_margin, spacing=thru_every)
          teardrop(d=thru_d, h=75);
      }

      if (pivot_pin.x > 0) {
        if (interlock_down) {
          tag("remove")
          attach("pivot_down", TOP, overlap=5)
            pivot_hole();
        }
        if (interlock_up) {
          attach("pivot_up", BOTTOM) pivot_pin()
            if (strength_fins) {
              down(feature) position(TOP)
              #tag("remove") {
                cuboid([pivot_pin.x/2, feature/2, pivot_pin.y*1.5-feature], anchor=BOTTOM, orient=DOWN);
                cuboid([feature/2, pivot_pin.x/2, pivot_pin.y*1.5-feature], anchor=BOTTOM, orient=DOWN);
              }
            }
        }
      }

      if (interlock_d > 0) {
        xat = struct_val(prof, "x_slot_at");
        yat = struct_val(prof, "y_slot_at");
        interlock_arc_base = norm([xat.x - yat.x, xat.y - yat.y]);
        interlock_arc = [
          xat.x - pivot_at.x,
          xat.y - pivot_at.y
        ];
        interlock_arc_r = norm(interlock_arc);
        interlock_arc_ang = 2*asin((interlock_arc_base/2)/interlock_arc_r);

        if (interlock_down) {
          tag("remove")
          position("pivot_down")
          let(
            profile = interlock_profile(tolerance=tolerance, sharp=true),
            insert = interlock_profile(tolerance=tolerance, sharp=true, open=true),
            bounds = pointlist_bounds(profile),
            profile_h = bounds[1].y - bounds[0].y,
            cutaway = cutaway_shape(
              norm([size.x, size.y])/2 - interlock_arc_r,
              size.z,
              insert),
          )
            down(tolerance) up(profile_h/2) {
              channel_length = interlock_arc_ang/2 + 25;
              cut_length = interlock_arc_ang/2;

              if (cutaway_slant) {
                down($eps)
                path_sweep(profile, arc(r=interlock_arc_r, angle=[
                  -90 + channel_length,
                  -180 - channel_length
                ]));

                let (
                  s=6 * interlock_arc_r,
                  spin=-45,
                  fudge = 3.4 // XXX why
                )
                zrot(-spin)
                half_of(v=[1, 0, -1], cp=DOWN * fudge, s=s)
                zrot(spin)
                  path_sweep(cutaway, arc(r=interlock_arc_r, angle=[
                    90 + cut_length,
                    0 - cut_length
                  ]));
              } else {
                down($eps)
                path_sweep(profile, arc(r=interlock_arc_r, angle=[
                  -134 + channel_length,
                  -136 - channel_length
                ]));
                path_sweep(cutaway, arc(r=interlock_arc_r, angle=[
                  90 + cut_length,
                  0 - cut_length
                ]));
              }

            }
        }

        if (interlock_up) {
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
          up(profile_h/2) {
            path_sweep(profile, arc(r=interlock_arc_r, angle=[
              -134 + interlock_arc_ang/2,
              -136 - interlock_arc_ang/2
            ]));

            if (strength_fins) {
              tag("remove")
              down(profile_h/4 + feature)
                #path_sweep(rect([feature/2, profile_h*1.5 - feature]), arc(r=interlock_arc_r, angle=[
                  -137 + interlock_arc_ang/2,
                  -133 - interlock_arc_ang/2
                ]));
            }

            if ($preview && full_arc_preview) {
              tag("keep")
              recolor("#ff663388")
              zrot(180)
              path_sweep(profile, arc(r=interlock_arc_r, angle=[
                -134 + (180 - interlock_arc_ang/2),
                -136 - (180 - interlock_arc_ang/2)
              ]));
            }
          }
        }

      }

      if (label_size > 0 && label_depth > 0) {

        // TODO option for different placement when cutting away top for fan_mount
        tag("remove")
        position("inner_up")
        down(label_depth/2)
        zrot(-45)
        fwd(label_size)
          text3d(str("H", h), h=label_depth+$eps, size=label_size, atype="ycenter", anchor=CENTER);

        if (with_x_slot) {
          tag("remove")
          right(size.x/3)
          back(label_size)
          down(label_depth/2)
          up(size.z/2)
          position(FRONT)
            text3d(str("X", struct_val(prof, "x_slot").x), h=label_depth+$eps, size=label_size, atype="baseline", anchor=CENTER, orient=UP, spin=0);
        }

        if (with_y_slot) {
          tag("remove")
          back(size.y/3)
          right(label_size)
          down(label_depth/2)
          up(size.z/2)
          position(LEFT)
            text3d(str("Y", struct_val(prof, "y_slot").x), h=label_depth+$eps, size=label_size, atype="baseline", anchor=CENTER, orient=UP, spin=-90);
        }

      }

      // TODO interior attachment system, e.g. attach("inner", ...) thread holes

    }

    children();
  }
}

module fan_mount(depth) {
  prof = rail_profile();
  pivot_at = struct_val(prof, "pivot_at");

  tag("remove")
  up(rail_wall)
  up(interlock_d)
  down(depth)
  back(pivot_at.y)
  right(pivot_at.x)
  right(filter_size.x/2)
  back(filter_size.y/2)
  cuboid(
    fan_frame_size + [2*tolerance, 2*tolerance, 0],
    rounding=fan_frame_rounding, edges="Z",
    anchor=BOTTOM
    );
}

module preview_cut(v=BACK, s=10000) {
  if ($preview && preview_cut)
    half_of(v=v, s=s) children();
  else
    children();
}

if (mode == 0) {

  fwd(filter_size.z/2)
  fwd(filter_size.y/2)
  fwd(rail_wall)
  filter_panel(orient=FRONT) {
    attach(LEFT, "x_slot", spin=180)
    rail(500)
      attach("y_slot", LEFT, spin=90)
      filter_panel()
        attach(RIGHT, "x_slot", spin=180)
        rail(500);

    attach(RIGHT, "y_slot", spin=90)
    rail(500)
      attach("x_slot", LEFT, spin=180)
      filter_panel()
        attach(RIGHT, "y_slot", spin=90)
        rail(500)
          attach("x_slot", LEFT, spin=180)
          filter_panel();

  }

  up(filter_size.y/2 + 10) // XXX mounting gap ala fan mount part
  box_fan(anchor=BOTTOM, orient=UP);

  // TODO model the baseplate ; may be 5th filter dba base

}

else if (mode == 10) {
  preview_cut(v=[-1, 1, 0])
    rail(20, full_arc_preview = full_arc_preview && !preview_cut);
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
  rail(200, full_arc_preview = true);

  // TODO attach buddies to named anchor points
  // filter_panel(orient=FRONT, anchor=LEFT);
  // filter_panel(orient=RIGHT, anchor=FRONT);

}

else if (mode == 12) {

  // ydistribute(spacing=struct_val(rail_profile(), "width")) {

  diff() rail(50, solid=true, interlock_up=false) {
    tag("remove") fan_mount(25);
  }

  //   zrot(-90) rail(50, full_arc_preview=true);
  // }
}

else if (mode == 13) {

  // TODO hoist parameter section

  baseplate_offset = 2;

  baseplate_thickness = 5;

  baseplate_chamfer = 20;

  diff() rail(
    2*(baseplate_thickness + baseplate_offset),
    solid=true,
    interlock_down=false,
    strength_fins=false,
  ) {
    prof = rail_profile();
    wid = struct_val(prof, "width");
    hei = struct_val(prof, "height");
    x_slot = struct_val(prof, "x_slot");
    y_slot = struct_val(prof, "y_slot");
    x_slot_at = struct_val(prof, "x_slot_at");
    y_slot_at = struct_val(prof, "y_slot_at");

    down(baseplate_offset)
    position(TOP) {

      // TODO dial in cavity size, use it to locate support walls
      right(y_slot_at.x)
      back(x_slot_at.y)
      tag("remove")
      cuboid([
        struct_val(prof, "width") + baseplate_chamfer,
        struct_val(prof, "height") + baseplate_chamfer,
        baseplate_thickness], chamfer=baseplate_chamfer, edges="Z",
        anchor=FRONT + LEFT + TOP) {
      }

      // tag("keep")
      // back(x_slot_at.y)
      // right(struct_val(prof, "width")/2)
      // left(support_width)
      // #support_wall(baseplate_thickness, hei/2, anchor=FRONT + BOTTOM, orient=DOWN); // XXX

    }

  }

}

else if (mode == 101) {
  filter_panel(orient=FRONT);
}

else if (mode == 102) {
  prof = rail_profile();
  color("red") down(.2) polygon(struct_val(prof, "basic_path"));
  color("blue") down(.1) polygon(struct_val(prof, "cut_path"));
  color("yellow") polygon(struct_val(prof, "smooth_path"));
}

else if (mode == 103) {
  n = interlock_ngon;

  bar = interlock_profile(tolerance=0);
  profile = interlock_profile(tolerance=tolerance, sharp=true);
  insert = interlock_profile(tolerance=tolerance, open=true, sharp=true);
  cutaway = cutaway_shape(
    norm([size.x, size.y])/2 - interlock_arc_r,
    size.z,
    insert);

  color("blue")
  polygon(profile);

  up(0.1) color("red")
  polygon(bar);

  down(0.1) color("yellow")
  polygon(insert);

  down(0.2) color("green")
  polygon(cutaway);
}

else if (mode == 100) {

  pivot_pin()
  {
  // position(TOP) #sphere(1);
  %show_anchors(std=false);
  // zrot(-45)
  // #cube([ feature, 2*$parent_size.y, 2*$parent_size.z ], center=true);
  %cube($parent_size, center=true);
  }

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
