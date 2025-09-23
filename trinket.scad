include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>;
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
chamfer = 0.5;

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
  // TODO case
  // TODO power supply / batteries / etc
  // TODO compute
  // TODO keyboard
  // TODO screen
  // TODO wires?
  // TODO ancillary port extenders?
}

module dev() {
  // compute()
  batery_pack()
  {
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

module batery_pack(anchor = CENTER, spin = 0, orient = UP) {

  pcba(
    size = [
      100,
      48.25,
      1.5,
    ],
    rounding = 5,
    mount_hole_d = 2.75,

    // y spacing
    //   30.4 ~ 35.9
    //   35.9 - 30.4 = 5.5
    //   5.5 / 2 = 2.75
    //   35.9 - 2.75 = 33.15
    //   30.4 + 2.75 = 33.15
    // y offset measures like 7.4
    //   48.25 - 7.4*2 = 33.45 which is only off 33.15 by .3
    //   48.25 - 7.5*2 = 33.25 -- seems more likely then
    // x spacing measures as 1.5 left and 1.2 right ... with usb-a left
    mount_hole_offset = [
      1.5 + 2.75/2,
      7.5 + 2.75/2
    ],

  concat([

    ["holder", [
      ["size", [76.75, 42.5, 15.25]],
      ["color", "#222222"],
      ["position", TOP+RIGHT],
      ["anchor", BOTTOM+RIGHT],
      ["offset", [-5.75, 0, 0]],
    ]],

    ["usb-a", [
      ["size", [10.2, 13.33, 6.5]],
      ["color", "#aaaaaa"],
      ["position", TOP+LEFT],
      ["anchor", BOTTOM+LEFT],
      ["offset", [-0.8, 0, 0]],
    ]],

    ["usb-c", [
      ["size", [8.9, 7.4, 3.0]],
      ["color", "#aaaaaa"],
      ["position", BOTTOM+RIGHT+FRONT],
      ["anchor", TOP+RIGHT+FRONT],
      ["offset", [-7.5, 0, 0]],
    ]],

    ["usb-a-mini", [
      ["size", [7.5, 5.5, 2.2]],
      ["color", "#aaaaaa"],
      ["position", BOTTOM+RIGHT+FRONT],
      ["anchor", TOP+RIGHT+FRONT],
      ["offset", [-20.6, 0, 0]],
    ]],

    ["button", [
      ["size", [7.4, 6.45, 4.2]],
      ["color", "#aaaaaa"],
      ["position", TOP+LEFT+FRONT],
      ["anchor", BOTTOM+LEFT+FRONT],
      ["offset", [8.5, 0, 0]],
    ]],

    ["switch", [
      ["size", [9, 3.45, 3.41]],
      ["color", "#aaaaaa"],
      ["position", TOP+LEFT+BACK],
      ["anchor", BOTTOM+LEFT+BACK],
      ["offset", [8.4, 0, 0]],
    ]],

    ["switch_thru", [
      ["size", [9, 0.5, 2.24]],
      ["color", "#aaaaaa"],
      ["position", BOTTOM+LEFT+BACK],
      ["anchor", TOP+LEFT+BACK],
      ["offset", [8.4, -2.3, 0]],
    ]],

    ["bulkeh", [
      ["size", [6.6, 6.6, 4.7]],
      ["color", "#888888"],
      ["position", BOTTOM],
      ["anchor", TOP],
      ["offset", [0, 0, 0]],
    ]],

    ["LEDs", [
      ["size", [16.8, 3.2, 0.6]],
      ["color", "#cc3333"],
      ["position", BOTTOM+FRONT+LEFT],
      ["anchor", TOP+FRONT+LEFT],
      ["offset", [23, 7.5, 0]],
    ]],
  ],

    [for (i = [0 : 1 : 3])
      [str("5v_", i), [
        ["size", [5.35, 3, 0.1]],
        ["color", "#999933"],
        ["position", BOTTOM+FRONT+LEFT],
        ["anchor", TOP+FRONT+LEFT],
        ["offset", [24.5 + 12.5 * i, 0, 0]],
      ]] ],

    [for (i = [0 : 1 : 3])
      [str("3v_", i), [
        ["size", [5.35, 3, 0.1]],
        ["color", "#339999"],
        ["position", BOTTOM+BACK+RIGHT],
        ["anchor", TOP+BACK+RIGHT],
        ["offset", [-30 - 12.5 * i, 0, 0]],
      ]] ],

  )) children();
}

module compute(anchor = CENTER, spin = 0, orient = UP) {
  // TODO generalize beyond rpi-zero
  // TODO hoist parameters
  // TODO get specs for or just measure elevations
  // TODO mount screw spec

  // height notes:
  // - total alu case stack is 13.66
  // - alu case bottom clearance is 1.4 ( +1.45 for pin header )
  // - alu case top clearance is 4.5

  // TODO
  // pcb_clearance = [
  //   1.80, // down: the 40-pin header solder joints ; measured
  //   // 3.35, // up: the mini hdmi port ; measured
  //   8.40, // up: the 40-pin header ; measured
  // ];

  pcb_size = [
    65, 30, // spec
    1.4     // measured
  ];
  pcb_rounding = 3; // measured

  pcba(pcb_size, pcb_rounding,
    mount_hole_d = 2.75, // measured
    mount_hole_offset = 3.5, // spec
    mount_hole_spacing = [ 29*2, 23 ], // spec

  [

    ["header", [
      ["size", [50.6, 5, 8.5]], // measured
      ["color", "#222222"],
      ["position", BACK + TOP],
      ["anchor", BACK + BOTTOM],
      ["offset", [
        0,
        -0.9, // measured setback
        0
      ]],
    ]],

    ["header_thru", [
      ["size", [50.6, 5, 2.0]], // measured
      ["color", "#aaaaaa"],
      ["position", BACK + BOTTOM],
      ["anchor", BACK + TOP],
      ["offset", [
        0,
        -0.9, // measured setback
        0
      ]],
    ]],

    ["hdmi", [
      ["size", [11.75, 8.2, 3.4]], // measured
      ["color", "#aaaaaa"],
      ["position", FRONT + TOP],
      ["anchor", FRONT + BOTTOM],
      ["offset", [
        12.4 - pcb_size.x/2, // spec from left edge
        -0.75, // measured extent
        0
      ]],
    ]],

    ["usb_1", [
      ["size", [8, 5.7, 3.4]], // measured
      ["color", "#aaaaaa"],
      ["position", FRONT + TOP],
      ["anchor", FRONT + BOTTOM],
      ["offset", [
        41.4 - pcb_size.x/2, // spec from left edge
        -1.00, // measured extent
        0
      ]],
    ]],

    ["usb_2", [
      ["size", [8, 5.7, 3.4]], // measured
      ["color", "#aaaaaa"],
      ["position", FRONT + TOP],
      ["anchor", FRONT + BOTTOM],
      ["offset", [
        54 - pcb_size.x/2, // spec from left edge
        -1.00, // measured extent
        0
      ]],
    ]],

    ["csi2", [ 
      ["size", [17.05, 4.05, 1]], // measured
      ["color", "#dddddd"],
      ["position", RIGHT + TOP],
      ["anchor", BOTTOM + FRONT],
      ["spin", 90],
      ["offset", [
        0.80, // measured extent
        0,
        0
      ]],
    ]],

    ["sdslot", [
      ["size", [12, 11.5, 1.5]], // measured
      ["color", "#aaaaaa"],
      ["position", LEFT + TOP],
      ["anchor", BOTTOM + BACK],
      ["spin", 90],
      ["offset", [
          1.8, // measure inset
          pcb_size.y/2 // from pcb back-edge
          - 6 // component center / back edge ( aka size.x/2 )
          - 7, // measured offset
          0
      ]],
    ]],

    ["core", [
      ["size", [15, 15, 1]], // measured
      ["color", "#222222"],
      ["position", TOP],
      ["anchor", BOTTOM],
      ["offset", [
        15/2 - pcb_size.x/2 + 20, // measured
        15/2 - pcb_size.y/2 + 6.4, // measured
        0
      ]],
    ]],

    ["wifi", [
      ["size", [12.1, 12.1, 1]], // measured
      ["color", "#aaaaaa"],
      ["position", TOP],
      ["anchor", BOTTOM],
      ["offset", [
        pcb_size.x/2 - 12.1/2 - 15.3, // measured
        12.1/2 - pcb_size.y/2 + 7.7, // measured
        0
      ]],
    ]],

  ]) children();
}

function pcba(
  size, rounding, components,
  mount_hole_d = 0,
  mount_hole_offset = 0,
  mount_hole_spacing = undef,
) = let (

  hole_offset = scalar_vec2(mount_hole_offset),
  hole_spacing = default(mount_hole_spacing, [size.x, size.y] - 2*hole_offset),

  part_bounds = concat([
    for (comp = components)
    let (
      name = comp[0],
      info = comp[1],
      pos = struct_val(info, "position", TOP),
      xlate = struct_val(info, "offset", [0, 0, 0]),
    )
    move(
      v_mul(pos, size/2) + xlate,
      cube(
        size = struct_val(info, "size"),
        anchor = struct_val(info, "anchor", BOTTOM),
        orient = struct_val(info, "orient", UP),
        spin = struct_val(info, "spin", 0),
      )[0]
    )
  ], [
    cube(size, center=true)[0],
    // TODO clearance(s)
  ]),

  part_points = [for (pt = flatten(part_bounds)) pt],
  extent_x = minmax([for (pt = part_points) pt.x]),
  extent_y = minmax([for (pt = part_points) pt.y]),
  extent_z = minmax([for (pt = part_points) pt.z]),
  extent_lo = [extent_x[0], extent_y[0], extent_z[0]],
  extent_hi = [extent_x[1], extent_y[1], extent_z[1]],
  bounds = extent_hi - extent_lo,
  pcb_xlate = -(extent_hi + extent_lo)/2,
) [
  ["size", bounds],

  ["pcb_size", size],
  ["pcb_rounding", rounding],
  ["pcb_xlate", pcb_xlate],

  ["mount_hole_d", mount_hole_d],
  ["mount_hole_offset", hole_offset],
  ["mount_hole_spacing", hole_spacing],

  ["components", components],
  ["part_bounds", part_bounds],
];

module pcba(
  size, rounding, components,
  mount_hole_d = 0,
  mount_hole_offset = 0,
  mount_hole_spacing = undef,
  pcb_color = "green",
  anchor = CENTER, spin = 0, orient = UP,
) {
  info = pcba(
    size, rounding, components,
    mount_hole_d = mount_hole_d,
    mount_hole_offset = mount_hole_offset,
    mount_hole_spacing = mount_hole_spacing,
  );
  size = struct_val(info, "size");
  mount_hole_d = struct_val(info, "mount_hole_d");
  pcb_size = struct_val(info, "pcb_size");
  pcb_xlate = struct_val(info, "pcb_xlate");

  part_anchors = [
    for (comp = components)
    let (
      name = comp[0],
      info = comp[1],
      pos = struct_val(info, "position", TOP),
      xlate = struct_val(info, "offset", [0, 0, 0]),
      size = struct_val(info, "size"),
      anchor = struct_val(info, "anchor", BOTTOM),
      orient = struct_val(info, "orient", UP),
      spin = struct_val(info, "spin", 0),
    )
    named_anchor(
      name,
      v_mul(pos, pcb_size/2)
      + xlate
      + pcb_xlate
      + UP*size.z/2,
      orient)];

    mount_anchors = mount_hole_d ? flatten([
      let(
        pts = grid_copies(spacing=struct_val(info, "mount_hole_spacing"), p=pcb_xlate),
      )
      for (i = idx(pts))
      [
        named_anchor(str("mount_hole_", i), pts[i], UP),
        named_anchor(str("mount_up_", i), pts[i] + UP*pcb_size.z/2, UP),
        named_anchor(str("mount_down_", i), pts[i] + DOWN*pcb_size.z/2, DOWN),
      ]
    ]) : [];

  attachable(anchor, spin, orient, size=size, anchors=concat(
    part_anchors,
    mount_anchors,
  )) {
    diff()
    translate(pcb_xlate)
    color_this(pcb_color)
    cuboid(pcb_size, rounding=struct_val(info, "pcb_rounding"), edges="Z")
    {

      if (mount_hole_d)
      tag("remove")
      grid_copies(spacing=struct_val(info, "mount_hole_spacing"))
        cyl(d=mount_hole_d, h=pcb_size.z + 2*$eps);

      tag("keep")
      for (comp = components) {
        name = comp[0];
        info = comp[1];
        pos = struct_val(info, "position", TOP);
        xlate = struct_val(info, "offset", [0, 0, 0]);

        position(pos)
        translate(xlate)
        // TODO dispatch "shape" if defined
        color_this(struct_val(info, "color", "default"))
        cuboid(
          struct_val(info, "size"),
          anchor=struct_val(info, "anchor", BOTTOM),
          orient=struct_val(info, "orient", UP),
          spin=struct_val(info, "spin", 0),
        );

      }
    }
    children();
  }
}

function minmax(xs) = [min(xs), max(xs)];

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
