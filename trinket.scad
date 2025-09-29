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

  boards = [
    compute(),
    battery_pack(),
    keyboard(),
  ];                 

  ycopies(spacing=cumsum([
    for (board = boards)
    struct_val(board, "bounds").y
  ])) pcba(boards[$idx]);

  // TODO case
  // TODO keyboard
  // TODO screen
  // TODO wires?
  // TODO ancillary port extenders?

}

module dev() {

  assembly()
  // keyboard()
  // battery_pack()
  // compute()
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

keyboard_layout = [
  [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" ],
  [ "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" ],
  [ "A", "S", "D", "F", "G", "H", "J", "K", "L", "Back" ],
  [ "Z", "X", "C", "V", "B", "N", "M", "Semi", "Quote", "Enter" ],
  [
    "Fn_1", "Shift", "Alt",
    "Com",
    [
      ["name", "Space"],
      ["size", 2],
    ],
    "Dot",
    "Cmd", "Ctrl", "Fn_2"
  ],
];

// TODO key membrane mockup / matching keyframe
// membrane corner rounding looks like 6
// membrane contacter is like D:4.2
// membrane depth is like 2.7

function keyboard() = let (

  width = 105,
  height = 53,
  // thick = 0.4, // 0.8,
  thick = 0.8,

  r1 = 6,
  r2 = 10,
  wing = [1.6, 23],
  wing_at = 5.0,
  rem_h = height-wing_at-wing.y-r1-r2,

  plate_shape = turtle([
    "move", width-r2-r2-r2,

    "arcleft", r2, 90,

    "move", wing_at,
    "right", 90,
    "move", wing.x,
    "left", 90,
    "move", wing.y,
    "left", 90,
    "move", wing.x,
    "right", 90,
    "move", rem_h,

    "arcleft", r1, 90,

    "move", width-r1-r1,

    "arcleft", r1, 90,

    "move", rem_h,
    "right", 90,
    "move", wing.x,
    "left", 90,
    "move", wing.y,
    "left", 90,
    "move", wing.x,
    "right", 90,
    "move", wing_at,

    "arcleft", r2, 90,
  ]),

) pcba(
  shape = plate_shape,
  height = thick,
  components = [

    // mount holes
    ["edge_hole_0", [
      ["tag", "remove"],
      ["position", BACK],
      ["region", union([
        circle(d=4),
        back(1.5, rect([4, 2.5]))
      ])],
      ["offset", [-46, -1.75, 0]],
    ]],
    ["edge_hole_1", [
      ["tag", "remove"],
      ["position", BACK],
      ["region", union([
        circle(d=4),
        back(1.5, rect([4, 2.5]))
      ])],
      ["offset", [46, -1.75, 0]],
    ]],
    ["edge_hole_2", [
      ["tag", "remove"],
      ["position", FRONT],
      ["region", union([
        circle(d=4),
        fwd(1.5, rect([4, 2.5]))
      ])],
      ["offset", [-42, 1, 0]],
    ]],
    ["edge_hole_1", [
      ["tag", "remove"],
      ["position", FRONT],
      ["region", union([
        circle(d=4),
        fwd(1.5, rect([4, 2.5]))
      ])],
      ["offset", [42, 1, 0]],
    ]],

    // center index holes
    ["mid_hole_0", [
      ["tag", "remove"],
      ["position", CENTER],
      ["d", 2.5],
      ["offset", [-10.5, -5, 0]],
    ]],
    ["mid_hole_1", [
      ["tag", "remove"],
      ["position", CENTER],
      ["d", 2.5],
      ["offset", [11, -5, 0]],
    ]],
    ["mid_hole_2", [
      ["tag", "remove"],
      ["position", CENTER],
      ["d", 2.5],
      ["offset", [-10.5, 15, 0]],
    ]],

    // keypads
    let (
      grid_offset = [6, 8, 0],
      pad_size = [ 5.5, 0.1 ], // D, H
      pad_spacing = [10.5, 9.2],
      layout = keyboard_layout,
      row_yloc = postsum([for (row = layout) 1]),
    )
    each [
      for (row = idx(layout))
      let (
        row_data = [
          for (key = layout[row])
          is_string(key) ? [["name", key]] : key
        ],
        row_xloc = postsum([
          for (info = row_data)
          struct_val(info, "size", 1)
        ])
      )
      for (col = idx(row_data))
      let (
        info = row_data[col],
        key_name = struct_val(info, "name"),
      )
      assert(is_string(key_name), "must have key name")
      let (
        key_size = struct_val(info, "size", 1),
        key_loc = [row_xloc[col] + (key_size - 1)/2, row_yloc[row]],
        key_offset = v_mul(pad_spacing, key_loc),
        key_d = pad_size.x,
        key_shape = key_size == 1
          ? ["d", key_d]
          : ["region", rect(
              [pad_spacing.x * (key_size-1) + 2*key_d, key_d],
              rounding=key_d/2)],
      )
      [str("keypad_", key_name), [
        key_shape,
        ["h", pad_size.y],
        ["color", "#999999"],
        ["position", TOP+BACK+LEFT],
        ["offset", v_mul([1, -1], grid_offset + key_offset)],
      ]],
    ],

    ["led_1", [
      ["size", [2.3, 1.5, 0.6]],
      ["color", "#6699ee"],
      ["position", BACK+TOP],
      ["offset", [22, -2, 0]],
    ]],
    ["led_2", [
      ["size", [2.3, 1.5, 0.6]],
      ["color", "#6699ee"],
      ["position", BACK+TOP],
      ["offset", [28, -2, 0]],
    ]],

    ["button_pair", [
      ["d", 4.2],
      ["h", 0.5],
      ["color", "#dddddd"],
      ["position", BACK+TOP],
      ["offset", [35.75, -2.25, 0]],
    ]],

    ["batt_vcc", [
      ["d", 1.5],
      ["h", 0.5],
      ["color", "#ff3333"],
      ["position", BOTTOM+LEFT],
      ["anchor", TOP+LEFT],
      ["offset", [1, 6, 0]],
    ]],
    ["batt_gnd", [
      ["d", 1.5],
      ["h", 0.5],
      ["color", "#333333"],
      ["position", BOTTOM+LEFT],
      ["anchor", TOP+LEFT],
      ["offset", [1, 3, 0]],
    ]],

    ["cutaway_switch", [
      ["tag", "remove"],
      ["position", BACK],
      ["region", rect([23, 0.8+$eps])],
      ["anchor", BACK],
      ["offset", [-9, $eps, 0]],
    ]],
    ["cutaway_socket_adj", [
      ["tag", "remove"],
      ["position", BACK],
      ["region", rect([6.3, 0.8+$eps])],
      ["anchor", BACK],
      ["offset", [-33, $eps, 0]],
    ]],

    ["switch", [
      ["color", "#dddddd"],
      ["size", [6, 2.8, 1.5]],
      ["position", BOTTOM+BACK],
      ["anchor", TOP+BACK],
      ["offset", [-9, -0.8, 0]],
    ]],

    ["usb-c", [
      ["color", "#dddddd"],
      ["size", [8.9, 6.9, 3.2]],
      ["position", BOTTOM+BACK],
      ["anchor", TOP+BACK],
      ["offset", [-25.2, 2.8, 0]],
    ]],
  ],
);

module keyboard(anchor = CENTER, spin = 0, orient = UP) {
  pcba(keyboard()) children();
}

function battery_pack() = pcba(
  size = [100, 48.25, 1.5],
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

  components = concat([
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

    // 5v pads
    [for (i = [0 : 1 : 3])
      [str("5v_", i), [
        ["size", [5.35, 3, 0.1]],
        ["color", "#999933"],
        ["position", BOTTOM+FRONT+LEFT],
        ["anchor", TOP+FRONT+LEFT],
        ["offset", [24.5 + 12.5 * i, 0, 0]],
      ]] ],

    // 3v pads
    [for (i = [0 : 1 : 3])
      [str("3v_", i), [
        ["size", [5.35, 3, 0.1]],
        ["color", "#339999"],
        ["position", BOTTOM+BACK+RIGHT],
        ["anchor", TOP+BACK+RIGHT],
        ["offset", [-30 - 12.5 * i, 0, 0]],
      ]] ],

  ));

module battery_pack(anchor = CENTER, spin = 0, orient = UP) {
  pcba(battery_pack()) children();
}

function compute() = pcba(
  size = [65, 30, 1.4], // spec, spec, measured
  rounding = 3, // measured
  mount_hole_d = 2.75, // measured
  mount_hole_offset = 3.5, // spec
  mount_hole_spacing = [29*2, 23], // spec
  components = [
    ["header", [
      ["size", [50.6, 5, 8.5]], // measured
      ["color", "#222222"],
      ["position", BACK + TOP],
      ["anchor", BACK + BOTTOM],
      ["offset", [0, -0.9, 0]], // measured
    ]],

    ["header_thru", [
      ["size", [50.6, 5, 2.0]], // measured
      ["color", "#aaaaaa"],
      ["position", BACK + BOTTOM],
      ["anchor", BACK + TOP],
      ["offset", [0, -0.9, 0]], // measured
    ]],

    ["hdmi", [
      ["size", [11.75, 8.2, 3.4]], // measured
      ["color", "#aaaaaa"],
      ["position", FRONT + TOP + LEFT],
      ["anchor", FRONT + BOTTOM],
      ["offset", [12.4, -0.75, 0]], // spec, measured
    ]],

    ["usb_1", [
      ["size", [8, 5.7, 3.4]], // measured
      ["color", "#aaaaaa"],
      ["position", FRONT + TOP + LEFT],
      ["anchor", FRONT + BOTTOM],
      ["offset", [41.4, -1.00, 0]], // spec, measured
    ]],

    ["usb_2", [
      ["size", [8, 5.7, 3.4]], // measured
      ["color", "#aaaaaa"],
      ["position", FRONT + TOP + LEFT],
      ["anchor", FRONT + BOTTOM],
      ["offset", [54, -1.00, 0]], // spec, measured
    ]],

    ["csi2", [ 
      ["size", [17.05, 4.05, 1]], // measured
      ["color", "#dddddd"],
      ["position", RIGHT + TOP],
      ["anchor", BOTTOM + FRONT],
      ["spin", 90],
      ["offset", [0.80, 0, 0]], // measured
    ]],

    ["sdslot", [
      ["size", [12, 11.5, 1.5]], // measured
      ["color", "#aaaaaa"],
      ["position", LEFT + TOP + BACK],
      ["anchor", BOTTOM + BACK],
      ["spin", 90],
      ["offset", [1.8, -13, 0]], // measured
    ]],

    ["core", [
      ["size", [15, 15, 1]], // measured
      ["color", "#222222"],
      ["position", TOP + LEFT + FRONT],
      ["anchor", BOTTOM + LEFT + FRONT],
      ["offset", [20, 6.4, 0]], // measured
    ]],

    ["wifi", [
      ["size", [12.1, 12.1, 1]], // measured
      ["color", "#aaaaaa"],
      ["position", TOP + RIGHT + FRONT],
      ["anchor", BOTTOM + RIGHT + FRONT],
      ["offset", [-15.3, 7.7, 0]], // measured
    ]],

  ]);

module compute(anchor = CENTER, spin = 0, orient = UP) {
  pcba(compute()) children();
}

// TODO function pcb_part( ... ) info builder / normalizer

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

// simplified part shape used for bounds, clearance, etc.
function pcb_part_shape(info, pcb_h) = let(
  size = pcb_part_size(info, pcb_h),
  nom = struct_val(info, "tag", "keep"),
)
  assert(is_vector(size, 3), str("\npcb component must define size."))
  cube(
    size,
    anchor = struct_val(info, "anchor", nom == "remove" ? CENTER : BOTTOM),
    orient = struct_val(info, "orient", UP),
    spin = struct_val(info, "spin", 0),
  );

// actual part shape for removal (holes) or mockup.
module pcb_part(info, pcb_h, anchor = undef, spin = 0, orient = UP) {
  reg = struct_val(info, "region");
  d = struct_val(info, "d");
  h = struct_val(info, "h");

  // TODO standardized named parts like connectors

  nom = struct_val(info, "tag", "keep");
  ank = struct_val(info, "anchor", nom == "remove" ? CENTER : BOTTOM);
  height = default(h, pcb_h + (nom == "remove" ? 2*$eps : 0));

  tag(nom)
  color_this(struct_val(info, "color", "default"))

  if (is_def(reg)) {
    linear_sweep(
      reg, height,
      anchor=ank,
      orient=struct_val(info, "orient", orient),
      spin=struct_val(info, "spin", spin),
    ) children();
  } else if (is_def(d)) {
    cyl(d=d, h=height,
      anchor=ank,
      orient=struct_val(info, "orient", orient),
      spin=struct_val(info, "spin", spin),
    ) children();
  } else {
    cuboid(
      pcb_part_size(info, pcb_h),
      anchor=ank,
      orient=struct_val(info, "orient", orient),
      spin=struct_val(info, "spin", spin),
    ) children();
  }

}

function pcba(
  size, rounding, // simple rectangle, maybe rounded
  // -- or -- 
  shape, height, // extruded path or region

  components,

  // TODO obsolete into components
  mount_hole_d = 0,
  mount_hole_offset = 0,
  mount_hole_spacing = undef,
) =

  assert(
    is_def(size) ||
    is_def(height) && is_def(shape),
    "\nMust define either size (cube) or shape + height")
  assert(
    is_undef(size) || is_vector(size, 3),
    "\n'size' must be a 3-vector.")
  assert(
    is_undef(shape) || is_path(shape) || is_region(path),
    "\n'shape' must be a path or region.")
  let (
    // TODO recenter
    pcb_shape = is_undef(shape)
      ? rect([size.x, size.y], rounding)
      : let (
        bnd = pointlist_bounds(is_region(shape) ? flatten(shape) : shape),
        mid = (bnd[0] + bnd[1])/2,
      ) move(-mid, shape),
   
    pcb_size = let (
      bnd = pointlist_bounds(is_region(pcb_shape) ? flatten(pcb_shape) : pcb_shape),
      sz = bnd[1] - bnd[0],
    ) is_undef(size) ? [ sz.x, sz.y, height ] : size,

    part_shapes = concat([
      linear_sweep(pcb_shape, pcb_size.z, center=true),
    ], [
      for (comp = components)
      let (
        name = comp[0],
        info = comp[1],
        tag = struct_val(info, "tag", "keep"),
      )
      if (tag != "remove")
      let (
        pos = struct_val(info, "position", TOP),
        xlate = struct_val(info, "offset", [0, 0, 0]),
        place = v_mul(pos, pcb_size/2) + xlate,
      )
      move(place, pcb_part_shape(info, pcb_size.z))
    ]),

    all_bounds = pointlist_bounds(flatten([ for (shape = part_shapes) shape[0] ])),
    bounds = all_bounds[1] - all_bounds[0],
    pcb_xlate = -(all_bounds[1] + all_bounds[0])/2,

    // TODO obsolete with hole components
    hole_offset = scalar_vec2(mount_hole_offset),
    hole_spacing = default(mount_hole_spacing, [pcb_size.x, pcb_size.y] - 2*hole_offset),
  ) [
    ["bounds", bounds],

    ["size", pcb_size],
    ["shape", pcb_shape],

    ["pcb_xlate", pcb_xlate],

    ["mount_hole_d", mount_hole_d],
    ["mount_hole_offset", hole_offset],
    ["mount_hole_spacing", hole_spacing],

    ["components", components],
    ["part_shapes", part_shapes],

    // TODO deprecated
    ["part_bounds", [ for (shape = part_shapes) shape[0] ] ],

  ];

// TODO function pcb_profile(info) -> path

module pcb_plate(info, anchor = CENTER, spin = 0, orient = UP) {
  size = struct_val(info, "size");
  shape = struct_val(info, "shape");
  attachable(anchor, spin, orient, size=size) {
    color_this(struct_val("info", "color", "green"))
    linear_sweep(shape, size.z, center=true);

    children();
  }
}

module pcba(info, anchor = CENTER, spin = 0, orient = UP) {
  bounds = struct_val(info, "bounds");
  mount_hole_d = struct_val(info, "mount_hole_d");
  pcb_size = struct_val(info, "size");
  pcb_xlate = struct_val(info, "pcb_xlate");

  part_anchors = [
    for (comp = struct_val(info, "components"))
    let (
      name = comp[0],
      cinfo = comp[1],
      pos = struct_val(cinfo, "position", TOP),
      xlate = struct_val(cinfo, "offset", [0, 0, 0]),
      size = pcb_part_size(cinfo, pcb_size.z),

      loc1 = v_mul(pos, pcb_size/2) + pcb_xlate,
      loc = loc1 + xlate + UP*size.z/2,

      orient = struct_val(cinfo, "orient", UP),
    )
    named_anchor(name, loc, orient)];

  // TODO if we naturalize mount holes into negative parts below, then
  // anchors here should also generalize for any hole/negative part?
  mount_anchors = mount_hole_d ? flatten([
    let(
      pts = grid_copies(spacing=struct_val(info, "mount_hole_spacing"), p=pcb_xlate),
    )
    for (i = idx(pts))
    [
      named_anchor(str("mount_hole_", i), pts[i], UP),
      named_anchor(str("mount_up_",   i), pts[i] + UP*pcb_size.z/2, UP),
      named_anchor(str("mount_down_", i), pts[i] + DOWN*pcb_size.z/2, DOWN),
    ]
  ]) : [];

  attachable(anchor, spin, orient, size=bounds,
    anchors=concat(part_anchors, mount_anchors),
  ) {
    diff() translate(pcb_xlate) pcb_plate(info) {

      // TODO can we naturalize mount holes into ["tag", "remove"] parts with d & h?
      if (mount_hole_d)
      tag("remove")
      grid_copies(spacing=struct_val(info, "mount_hole_spacing"))
        cyl(d=mount_hole_d, h=pcb_size.z + 2*$eps);

      for (comp = struct_val(info, "components")) {
        cinfo = comp[1];
        position(struct_val(cinfo, "position", TOP))
        translate(struct_val(cinfo, "offset", [0, 0, 0]))
          pcb_part(cinfo, pcb_size.z);
      }
    }
    children();
  }
}

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
