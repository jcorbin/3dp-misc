include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>;
include <BOSL2/screws.scad>;
include <BOSL2/walls.scad>;

/***

# TODO

- feature: front usb-c sockets
- feature: power button placement; other front panel features?
- feature: usb ports from headers
- feature: wifi antenna placement
- feature: audio header usage
- feature: cable retention features in the front-void
- feature: psu rear hold-down

# second assembly test notes

- [X] fixed psu cutout xflip... was a stupid shell integration problem, the
  cutout pattern itself was fine
- [X] decremented io shield window Y fudge by 2.5
- [X] added wifi antenna mount posts
- [ ] print quality: front-right corner warped up
  - design in mouse ears?
  - at least add slicer ears with next print

# first assembly test notes

- [X] increased mainboard under-clearance from 8 to 12
- [X] increased psu gap from 5 to 6
- ... increased X&Y inner margin from 1 to 2
- ... increased wall to 3
- ... made psu cutout support flat head with thick engough wall
- [X] deleted bottom pus mount hole, since it interferes with inlet when
  flat-headed
- [X] increase inner Y+ margin and added tolerance to io shield window

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
chamfer = 1.5;

// Generic rounding for anonymous edges.
rounding = 1.5;

// General wall thickness between voids
wall = 3.0;

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

// Show support walls in preview, otherwise only active in production renders.
$support_preview = false;

/* [Interior Constraints] */

shell_inner_margin = [
  [2, 2 + 46],
  [2, 10],
  [1, 1]
];

mainboard_clearance = [ 12, 83 ];

mainboard_offest = [ 0, -1, 0 ];

mainboard_mount_hole_d = 3.96;

mainboard_post_hole_d = 3.8;

mainboard_post_foot = 2;

mainboard_post_chamfer = 1;

mainboard_hole_chamfer = 1;

mainboard_hole_depth_delta = -1;

psu_gap = 6;

psu_mount_screw = "M3";

/// dispatch / integration

module main() {
  if (mode == 0) {
    assembly();
  }
  else if (mode == 100) {
    dev();
  }
  else if (mode == 101) {
    test_brackets();
  }
}

module assembly() {
  // TODO both shell halves

  // TODO frame() intermediate as a fit test

  shell() {

    let (
      mainboard_size = struct_val(compute(), "bounds"),
      psu_size = struct_val(power_supply(), "size"),
      psu_gap = 4, // XXX dupe
    )

    attach_part("mainboard")
      attach(BOTTOM, BOTTOM)
      up(mainboard_clearance[0])
      down(4.5) // io shield underhang
        compute();
        // %cube(_attach_geom_size($parent_geom), center=true);

    attach_part("power_supply")
      attach(BOTTOM, LEFT)
        power_supply();
        // %cube(_attach_geom_size($parent_geom), center=true);

    // TODO screws
    // TODO wires
    // TODO button
  }
}

module dev() {
  // // battery_pack(orient=DOWN)
  // compute()
  // power_supply()
  // compute_io_bracket(1)
  // power_supply_bracket()
  // antenna_mount()
  shell()
  // assembly()
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

module restore_part(part) {
  req_children($children);
  $parent_geom = part[1];
  $anchor_inside = part[2];
  T = part[3];
  $parent_parts = [];
  multmatrix(T)
    children();
}

module test_brackets() {

  // ydistribute(
  //   spacing = 5,
  //   sizes = [
  //     struct_val(compute_io_bracket(), "size").y,
  //     struct_val(power_supply_bracket(), "size").y
  //   ],
  // )

  let (
    w = wall,
    h = wall,
  )
  {
    compute_io_bracket(size=w, height=h);
    power_supply_bracket(size=w, height=h);
  }

}

module shell(anchor = CENTER, spin = 0, orient = UP) {

  split_at = 10;

  mainboard = compute();
  mainboard_size = struct_val(mainboard, "size");
  mainboard_bounds = mainboard_size + [0, 0, sum(mainboard_clearance)];

  psu_size = struct_val(power_supply(), "size");

  // bottom half maths ; TODO top half
  psu_room = psu_gap + psu_size.z;
  inner_size
    = sum(transpose(shell_inner_margin))
    + mainboard_bounds 
    + [0, psu_room, 0]
    - [0, 0, split_at];

  outer_size = inner_size + v_mul([2, 2, 1], scalar_vec3(wall));

  mainboard_part = define_part("mainboard",
    attach_geom(size=mainboard_bounds),
    T=
      move(mainboard_offest)*
      back((psu_size.z + psu_gap)/2)
      *down((inner_size.z - mainboard_bounds.z - wall)/2)
      *left((inner_size.x - mainboard_size.x)/2),
    inside=true);

  psu_part = define_part("power_supply",
    attach_geom(size=[
      psu_size.y,
      psu_size.z,
      psu_size.x,
    ]),
    T=
      fwd((mainboard_size.y + psu_gap)/2)
      *down((inner_size.z - psu_size.x - wall)/2)
      *left((inner_size.x - psu_size.y)/2),
    inside=true);

  parts = [
    define_part("inner",
      attach_geom(size=inner_size)),
    mainboard_part,
    psu_part,
  ];

  attachable(anchor, spin, orient, size=outer_size, parts=parts) {

    // back_half(s=2*max(outer_size))
    // left_half(s=2*max(outer_size))

    diff() cuboid(
      outer_size,
      chamfer=wall, edges=[
        [1, 1, 0, 0], // yz -- +- -+ ++
        [1, 1, 0, 0], // xz
        [1, 1, 1, 1], // xy
      ])
    {

      // TODO chamfer or round the Z corners separately / more
      // TODO or make this a clever-er path sweep ( profile around perimiter )

      // hollow and/or wall knock-downs
      tag("remove")
      attach(TOP, BOTTOM, overlap=inner_size.z)
      cuboid(
        inner_size + [0, 0, 2*$eps],
        chamfer=wall, edges=[
          [1, 1, 0, 0], // yz -- +- -+ ++
          [1, 1, 0, 0], // xz
          [1, 1, 1, 1], // xy
        ]) {

          // knock-down side-walls
          kd_size = [
            inner_size.x - 2*wall,
            wall,
            inner_size.z - wall
          ];
          up(wall/2)
          attach([FRONT, BACK], FRONT, overlap=$eps)
          cuboid(kd_size + [0, 2*$eps, $eps], chamfer=kd_size.z*2/5, edges=[
            [0, 0, 0, 0], // yz -- +- -+ ++
            [1, 1, 1, 1], // xz
            [0, 0, 0, 0], // xy
          ]);

        }

      // front panel buttons
      tag("remove")
      attach(RIGHT, TOP, overlap=wall+$eps) {
        xdistribute(sizes=[19, 14], spacing=wall) {
          cyl(d=16, h=wall+2*$eps);
          cyl(d=12, h=wall+2*$eps);
        }
      }

      // io shield window
      restore_part(mainboard_part)
      attach(LEFT, BOTTOM)
        right(1.2 + 2 + 3) // TODO un-fudge
        fwd(15.5) // TODO un-fudge
        down(1.5*wall)
        compute_io_cutout(2*wall)
        support_wall(
          l=$parent_size.x,
          h=$parent_size.y,
          width=wall,
          // orient=LEFT, spin=90
          orient=FWD, spin=90
        );

      // psu window
      restore_part(psu_part)
      attach(LEFT, TOP, overlap=wall + $eps)
        zrot(-90)
        power_supply_cutout(wall + 2*$eps) {

          attach_part("inlet") {
            // XXX need part size bounds... this is hack
            sz = $parent_geom[1];
            support_wall(l=sz.y - 4*tolerance, h=sz.x, width=sz.z, orient=LEFT);
          }

          psu_size = struct_val(power_supply(), "size");

          attach(BOTTOM, TOP, overlap=$eps)
          tag("remove")
          cuboid(size=[
            psu_size.x,
            psu_size.z + 2*wall,
            wall
          ],
          chamfer=wall, edges=[
            [0, 0, 0, 0], // yz -- +- -+ ++
            [0, 0, 0, 0], // xz
            [1, 0, 1, 0], // xy
          ]);

        }

      mount_holes = let (
        components = struct_val(mainboard, "components"),
      ) [
        for (i=[0:3])
        struct_val(components, str("mount_hole_", i))
      ];

      // mainboard mount posts
      restore_part(mainboard_part)
      let (
        post_h = mainboard_clearance[0],
        hole_h = post_h + mainboard_hole_depth_delta,
      ) for (hole = mount_holes) {
        d=struct_val(hole, "d") + 2*wall;
        fwd(2) // XXX fudge
        up(post_h/2)
        down(mainboard_bounds.z/2)
        position(struct_val(hole, "position"))
        translate(struct_val(hole, "offset"))
        tag("keep")
        tag_scope("mount_post")
          diff() cyl(
            h=post_h,
            d1=d+2*mainboard_post_foot,
            d2=d,
            chamfer1=-mainboard_post_chamfer)
            tag("remove")
            attach(TOP, BOTTOM, overlap=hole_h)
            cyl(
              h=hole_h+$eps,
              d=mainboard_post_hole_d,
              chamfer2=-mainboard_hole_chamfer);
      }

      // // cutout floor
      // restore_part(mainboard_part) {
      //   path = round_corners(
      //     xflip(offset([
      //       for (h = mount_holes)
      //       struct_val(h, "offset")
      //     ], r=-4)),
      //     method="smooth", joint=12,
      //   );
      //   // tag("remove")
      //   right(8) // XXX fudge
      //   fwd(4) // XXX fudge
      //   attach(BOTTOM, TOP, overlap=wall+$eps)
      //     !linear_sweep(path, 200);
      // }

      // antenna mount posts
      tag("keep")
      back(35)
      ycopies(n=2, spacing=60)
      left(3*wall)
      up(wall - $eps)
      position(BOTTOM+RIGHT)
        antenna_mount(foot_h=$eps, anchor=BOTTOM+FWD, spin=90);

      // TODO fan duct port in top half

      // TODO ribs
      // TODO hinges
      // TODO latches

    }

    children();
  }
}

module antenna_mount(
  foot_h = 1,
  anchor = CENTER, spin = 0, orient = UP,
) {
  clearance = 8;
  pitch = 44;
  post_chamfer = 1;

  hole_d = 2.8;
  post_d = hole_d + 2*wall;

  post_h = clearance;
  hole_h = post_h + $eps;

  // TODO very similar to the mainboard mount posts?

  size = [
    post_d + 2*post_chamfer + pitch,
    post_d + 2*post_chamfer,
    post_h
  ];

  attachable(anchor, spin, orient, size=size) {

    foot_size = [
        size.x,
        size.y,
        foot_h];

    down(foot_h/2)
    down(post_h/2)
    cuboid(foot_size, rounding=foot_size.y/2, edges="Z")
    xcopies(spacing=pitch, n=2)
      attach(TOP, BOTTOM, overlap=$eps)
      tag_scope("antenna_mount")
      diff()
      cyl(d=post_d, h=post_h+$eps, chamfer1=-post_chamfer)
      tag("remove")
      attach(TOP, BOTTOM, overlap=hole_h)
      cyl(d=hole_d, h=hole_h + $eps, chamfer2=-post_chamfer);

    children();
  }
}

function power_supply() = [
  ["size", [ 81.5, 150, 40.5 ]],
  ["rounding", 1],

  ["porch", [18, 10]],

  ["mount", [
    ["screw_spec", psu_mount_screw],
    ["hole_tolerance", "normal"],
    ["thread_tolerance", "2B"],
    ["hole_depth" , 10],
    ["hole_at", [
      [76,   4.1 ],
      [76,   36.1],
      [15.2, 37  ],
      // fairly redundant, plus flat head can interfere with inlet
      // [ 5.4, 35.9],
    ]],
  ]],

  ["fan_port", [
    ["at", [51.25, 20.25]],
    ["size", [37.5, 5]],
    ["hex", 10],
    ["hex_spacing", 10.2],
  ]],

  ["inlet", [
    ["at", [15.2, 17]],
    ["size", [24, 31.5, 20]],
    ["rounding", 1],
    ["extend", 3],
  ]],
];

function power_supply_bracket(
  size = wall,
  height = wall,
) = let (
  w = scalar_vec2(size),
  info = power_supply(),
  psu_size = struct_val(info, "size"),

  size = [
    psu_size.x + 2 * w.x,
    psu_size.z + 2 * w.y,
    height
  ],
) [
  ["wall", w],
  ["size", size],
];

module power_supply_bracket(
  size = wall,
  height = wall,
  anchor = CENTER, spin = 0, orient = UP,
) {
  info = power_supply_bracket(size, height);
  w = struct_val(info, "wall");
  size = struct_val(info, "size");
  attachable(anchor, spin, orient, size=size) {
    diff()
    cuboid(size, rounding=min(w), edges="Z")
      power_supply_cutout(height + 2*$eps)
        attach_part("inlet") {
          // XXX need part size bounds... this is hack
          sz = $parent_geom[1];
          support_wall(l=sz.y - 4*tolerance, h=sz.x, width=sz.z, orient=LEFT);
        }

    children();
  }
}

module power_supply_cutout(
  height,
  anchor = CENTER, spin = 0, orient = UP,
) {
  info = power_supply();
  psu_size = struct_val(info, "size");
  size = [
    psu_size.x, // TODO trim
    psu_size.z, // TODO trim
    height
  ];

  inlet = struct_val(info, "inlet");
  inlet_size = let (
    sz = struct_val(inlet, "size"),
  ) [sz.x, sz.y, height] + [2*tolerance, 2*tolerance, 0];
  inlet_at = struct_val(inlet, "at");

  frame_at = left(psu_size.x/2) * fwd(psu_size.z/2);
  inlet_part = define_part("inlet",
    attach_geom(size=inlet_size),
    T=frame_at * move(inlet_at),
    inside=true);

  default_tag("remove")
  attachable(anchor, spin, orient,
    size=size,
    parts=[
      inlet_part
    ],
  ) {
    left(psu_size.x/2)
    fwd(psu_size.z/2)
    union()
    {

      // mount holes
      let (
        mount = struct_val(info, "mount"),
        at = struct_val(mount, "hole_at"),
        tol = struct_val(mount, "hole_tolerance"),
        screw = struct_val(mount, "screw_spec"),
        head = height > 2.4 ? "flat" : "none", // TODO fairly coupled to #6-32 particulars
      )
      down($eps)
      move_copies(at)
        screw_hole(screw, head=head, tolerance=tol, length=height + 2*$eps);

      // fan grill
      let ( 
        fan_port = struct_val(info, "fan_port"),
        size = struct_val(fan_port, "size"),
      )
      down($eps)
        translate(struct_val(fan_port, "at"))
        teardrop(d=size.x, h=height + 2*$eps, orient=RIGHT, spin=90);
        // cyl(d=size.x, h=height + 2*$eps);

      // C14 inlet
      down($eps)
      translate(inlet_at)
        cuboid(inlet_size + [0, 0, 2*$eps], rounding=4*tolerance, edges="Z");

    }
    children();
  }
}

module power_supply(anchor = CENTER, spin = 0, orient = UP) {
  info = power_supply();
  size = struct_val(info, "size");
  wall = 1;

  attachable(anchor, spin, orient, size=size) {
    recolor("#994422") // NOTE not actual color, but for contrast
    tag_scope("power_supply")
    diff()
    cuboid(size, rounding=struct_val(info, "rounding")) {
      // hollow
      tag("remove")
        cuboid(size - scalar_vec3(wall)*2, rounding=struct_val(info, "rounding"));

      // back porch for modular connectors
      let (
        porch = struct_val(info, "porch"),
        h = size.z - porch.y,
      )
      tag("remove")
        down(h)
        fwd(porch.x)
        position(BACK+TOP)
        left($eps)
        cuboid(
          [
            size.x + 2*$eps,
            porch.x + $eps,
            h + $eps
          ],
          anchor=FRONT+BOTTOM,
          rounding=3, edges=[
            [1, 0, 0, 0], // yz -- +- -+ ++
            [0, 0, 0, 0], // xz
            [0, 0, 0, 0], // xy
          ],
        );

      // front face features
      down(size.z/2)
      left(size.x/2)
      attach(FRONT, BOTTOM) {

        // mount holes
        let (
          mount = struct_val(info, "mount"),
          mount_depth = struct_val(mount, "hole_depth"),
        )
        down(mount_depth)
        move_copies(struct_val(mount, "hole_at"))
          screw_hole(
            struct_val(mount, "screw_spec"),
            tolerance=struct_val(mount, "hole_tolerance"),
            length=mount_depth + $eps);

        // fan grill
        let ( 
          fan_port = struct_val(info, "fan_port"),
          size = struct_val(fan_port, "size"),
        )
        tag("remove")
        down(size.y)
          translate(struct_val(fan_port, "at"))
          intersection() {
            grid_copies(
              size=size.x,
              spacing=struct_val(fan_port, "hex_spacing"),
              stagger=true)
              zrot(30) cyl(d=struct_val(fan_port, "hex"), h=size.y+$eps, $fn=6);
            cyl(d=size.x, h=size.y+$eps);
          }

        // C14 inlet
        tag("keep")
        let (
          inlet = struct_val(info, "inlet"),
          size = struct_val(inlet, "size"),
        )
        down(size.z - struct_val(inlet, "extend"))
        recolor("#222222")
        translate(struct_val(inlet, "at"))
          cuboid(size, rounding=struct_val(inlet, "rounding"), edges="Z");

      }

    }

    children();
  }
}

function compute() = let (
  pcb_size = [170, 170],
) pcba(
  shape = rect(size=pcb_size, rounding=4),
  height = 1.6,
  components = [

    each [
      let (
        locs = [
          [33.02, -6.17],
          [165, -6.17],
          [165, -163.65],
          [10.16, -163.65],
        ],
      )
      for (i = idx(locs))
      [str("mount_hole_", i), [
        ["tag", "remove"],
        ["d", mainboard_mount_hole_d],
        ["position", BACK+LEFT],
        ["offset", locs[i]],
        // ["attach", DOWN],
      ]]
    ],

    ["heatsink", [
      ["size", [129, 129, 48.88]],
      ["color", "#666666"],
      ["position", BACK + LEFT + TOP],
      ["anchor", BACK + LEFT + BOTTOM],
      ["offset", [18.54, -9.84, 0]],
      ["attach", UP],
    ]],

    ["io_shield_base", [
      ["size", [0.2, 163, 49]],
      ["color", "#222222"],
      ["position", BACK + LEFT + TOP],
      ["anchor", BACK + LEFT + BOTTOM],
      ["offset", [-0.2, 4, -(1.6 + 4.5)]],
    ]],

    ["io_shield", [
      ["size", [1, 159, 45]],
      ["color", "#444444"],
      ["position", BACK + LEFT + TOP],
      ["anchor", BACK + LEFT + BOTTOM],
      ["offset", [-1.2, 2, -(1.6 + 2.5)]],
      ["attach", LEFT],
    ]],
  ]);

function compute_io_bracket(
  size = wall,
  height = wall,
) = let (
  w = scalar_vec2(size),
  mainboard = compute(),
  io_shield = struct_val(struct_val(mainboard, "components"), "io_shield"),
  io_size = struct_val(io_shield, "size"),
  size = [
    io_size.y + 2 * w.x,
    io_size.z + 2 * w.y,
    height
  ],
) [
  ["wall", w],
  ["size", size],
];

module compute_io_bracket(
  size = wall,
  height = wall,
  anchor = CENTER, spin = 0, orient = UP,
) {
  info = compute_io_bracket(size, height);
  w = struct_val(info, "wall");
  size = struct_val(info, "size");
  attachable(anchor, spin, orient, size=size) {
    diff()
    cuboid(size, rounding=min(w), edges="Z")
      compute_io_cutout(height + 2*$eps);
    children();
  }
}

module compute_io_cutout(
  height,
  tol = tolerance,
  anchor = CENTER, spin = 0, orient = UP,
) {
  mainboard = compute();
  io_shield = struct_val(struct_val(mainboard, "components"), "io_shield");
  io_size = struct_val(io_shield, "size");
  size = [
    io_size.y + 2*tol,
    io_size.z + 2*tol,
    height];
  default_tag("remove")
  attachable(anchor, spin, orient, size=size) {
    cuboid(size); // TODO chamfer corners?
    children();
  }
}

module compute(anchor = CENTER, spin = 0, orient = UP) {
  pcba(compute(), anchor=anchor, spin=spin, orient=orient) children();
}

// TODO function pcb_part( ... ) info builder / normalizer

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
  height = default(h, pcb_h + (nom == "remove" ? 4*$eps : 0));

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

function pcba(shape, height, components) =
  assert(
    is_path(shape) || is_region(path),
    "shape must be a path or region.")
  let (
    // TODO recenter
    pcb_shape = let (
      bnd = pointlist_bounds(is_region(shape) ? flatten(shape) : shape),
      mid = (bnd[0] + bnd[1])/2,
    ) move(-mid, shape),

    pcb_size = let (
      bnd = pointlist_bounds(is_region(pcb_shape) ? flatten(pcb_shape) : pcb_shape),
      sz = bnd[1] - bnd[0],
    ) [ sz.x, sz.y, height ],

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

    bounds = pointlist_bounds(flatten([ for (shape = part_shapes) shape[0] ])),
  ) [
    ["bounds", bounds[1] - bounds[0]],
    ["size", pcb_size],
    ["shape", pcb_shape],
    ["pcb_xlate", -(bounds[1] + bounds[0])/2],
    ["components", components],
    ["part_shapes", part_shapes],
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

module pcba(info, null = false, anchor = CENTER, spin = 0, orient = UP) {
  bounds = struct_val(info, "bounds");
  pcb_size = struct_val(info, "size");
  pcb_xlate = struct_val(info, "pcb_xlate");
  attachable(anchor, spin, orient, size=bounds, anchors=[
    for (comp = struct_val(info, "components"))
    let (
      name = comp[0],
      cinfo = comp[1],
      attach = struct_val(cinfo, "attach"),
    )
    if (is_def(attach))
    let (
      nom = struct_val(cinfo, "tag", "keep"),
      pos = struct_val(cinfo, "position", nom == "remove" ? CENTER : TOP),
      ank = struct_val(cinfo, "anchor", nom == "remove" ? CENTER : BOTTOM),
      spin = struct_val(cinfo, "spin", 0),
      xlate = struct_val(cinfo, "offset", [0, 0, 0]),
      size = pcb_part_size(cinfo, pcb_size.z),
      sz = zrot(spin, size),
      loc = pcb_xlate + v_mul(pos, pcb_size/2) + xlate - v_mul(ank, sz/2),
      po = loc + v_mul(attach, sz/2),
      at = struct_val(cinfo, "attach_orient", attach),
    ) named_anchor(name, po, at)
  ]) {
    if (null) {
      union() {}
    } else {
      diff() translate(pcb_xlate) pcb_plate(info) {
        for (comp = struct_val(info, "components")) {
          cinfo = comp[1];
          nom = struct_val(cinfo, "tag", "keep");
          pos = struct_val(cinfo, "position", nom == "remove" ? CENTER : TOP);
          ank = struct_val(cinfo, "anchor", nom == "remove" ? CENTER : BOTTOM);
          // TODO takeover passing spin & orient here
          position(pos)
          translate(struct_val(cinfo, "offset", [0, 0, 0]))
            pcb_part(cinfo, pcb_size.z, anchor=ank);
        }
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

module preview_cut(v=BACK, s=10000) {
  if ($preview && preview_cut)
    half_of(v=v, s=s) children();
  else
    children();
}

main();
