include <BOSL2/std.scad>
include <BOSL2/structs.scad>
include <BOSL2/walls.scad>

/* [Thermostate Module] */

// Size of the module body, X/Y main housing, not face frame/lip.
module_size = [45.2, 26, 32];

module_housing_depth = 15;

// Depth of surrounding face lip.
module_lip = 1.5;

// Depth of compression bumps on +/- Y faces.
module_grip = 1.9;

// Tolerance to add around hole.
module_tol = 0.2;

wire_hole_d = 8;

/* [Power Module] */

// Measured size of the USB-C power module PCB.
power_pcb_size = [10.8, 16.25, 1.5];

// Measured size of the power module USB-C female socket itself.
power_socket_size = [9, 6.8, 3.2];

// Edge rounding of the power module USB-C female socket.
power_socket_rounding = 1;

// How far the USB-C socket hangs out past the power module PCB edge.
power_socket_overhang = 1.6;

// How much of solder pad / wiring "porch" to allow at the back of the USB-C power module.
power_module_porch = 14;

// Diagonal cutting factor behind the USB-C power module to allow easy installation.
power_module_cut = 3;

// Fit tolerance for the USB-C power module.
power_module_tolerance = 0.2;

// Edge chamfering for the power module wiring channel.
power_channel_chamfer = 1;

// Fit tolerance for the fixation plug that will fill the power module wiring channel after installation.
power_channel_plug_tolerance = 0;

// Offset power channel from back of power module PCB; this helps the channel to miss the wrap wall channel, but needs to be low enough to still keep the USB-C socket pressed forward vs insertion.
power_channel_backset = 0.4;

// Notch in the back of the channel plug, allowing it to flex and be removed by a tool (like pliers).
channel_plug_notch_size = [ 5, 3 ];

/* [Designed Supports] */

// Interface gap between support and supported part.
support_gap = 0.2;

// Bridging gap between supports.
support_every = 15;

// Thickness of support walls and internal struts.
support_width = 0.8;

// Thickness of footer support walls that run parallel to and underneath floating external walls.
support_wall_width = 2.4;

// Enable to show support walls in preview, otherwise only active in production renders.
$support_preview = false;

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustment value for cutouts
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

body_margin = [20, 15];

body_chamfer = 5;

backstage = 35;

backstage_chamfer = 5;

module_backstage_overlap = module_size.z - module_housing_depth;

body_size = [
  module_size.x + 2*module_lip + 2*body_margin.x,
  module_size.z + backstage - module_backstage_overlap,
  module_size.y + 2*module_lip + 2*body_margin.y
];

hole_size = module_size + 2*scalar_vec3(module_tol) + [
  0,
  module_grip,
  0
];

backstage_size = [
  hole_size.x + 2*backstage_chamfer,
  hole_size.y + 2*backstage_chamfer,
  backstage
];

power_module_lift = 1.5;

power_channel_size = [
  power_pcb_size[0] + 2*power_channel_chamfer,
  sqrt(power_pcb_size[1]^2/2) +
  sqrt(power_pcb_size[2]^2/2) +
  2*power_channel_chamfer,
  (body_size.z - hole_size.y)/2 - power_module_lift + $eps
];

// power port particulars
ppp = power_port_details();

function power_port_details(
  tolerance = power_module_tolerance,
  gap = power_channel_backset
) = let (
  mod_size = power_module_size(tolerance),

  chan_size = power_channel_size,

  size = [
    chan_size.x,
    mod_size.y + gap + chan_size.y,
    power_channel_size.z
  ]
) [
  ["size", size],
  ["mod_size", mod_size],
  ["chan_size", chan_size],

  ["mod_offset", [
    0,
    (size.y - mod_size.y)/2 - gap - chan_size.y,
    (mod_size.z - size.z)/2
  ]],

  ["chan_offset", [
    0,
    size.y/2 - chan_size.y/2,
    -size.z/2 + tolerance,
  ]],

  ["cut_size", [
    mod_size.x,
    1.5*power_module_cut + 2*tolerance,
    4*power_module_cut + 2*tolerance
  ]],

  ["fill_size", [
    mod_size.x,
    gap + power_channel_chamfer + 2*$eps,
    mod_size.z
  ]]
];

module power_port(
  tolerance = power_module_tolerance,
  gap = power_channel_backset,
  lip_chamfer = 0,
  anchor = CENTER, spin = 0, orient = UP
) {
  deets = power_port_details(tolerance, gap);
  mod_offset = struct_val(deets, "mod_offset");
  chan_offset = struct_val(deets, "chan_offset");

  attachable(anchor, spin, orient, size=struct_val(deets, "size"),
    anchors=[
      named_anchor("channel", chan_offset),
      named_anchor("module", mod_offset),
    ]) {

    translate(mod_offset)
    power_module(profile=true, tolerance=tolerance) {

      // front lip back-chamfer
      if (lip_chamfer > $eps) {
        lcw = power_socket_size.x + 2*tolerance;
        lcs = sqrt(2) * lip_chamfer;
        back(sqrt(2) * lcs/2)
        attach("pcb_front_top", BACK+TOP)
          cube([lcw, lcs, lcs], center=true);
      }

      // channel -- vertical shaft, plug goes here
      chan_size = struct_val(deets, "chan_size");
      back(gap)
      position(BACK+BOTTOM)
        cuboid(chan_size, anchor=FRONT+BOTTOM, chamfer=power_channel_chamfer, edges="Z");

      // backfill -- between the channel and back of power module (over any backset)
      fill_size = struct_val(deets, "fill_size");
      position(BACK+BOTTOM)
      fwd($eps)
      cube(fill_size, anchor=FRONT+BOTTOM);

      // diagonal cut -- allows pcb entry and wire egress from rear of pcb
      cut_size = struct_val(deets, "cut_size");
      csdg = sqrt(cut_size.y^2 + (cut_size.z - power_module_cut)^2)/2;
      nudge = power_module_cut/2 - 2*tolerance;
      fwd(csdg + nudge)
      up(csdg - nudge)
      position(BACK+BOTTOM)
        left(cut_size.x/2)
        xrot(-45) cube(cut_size);

    }

    children();
  }
}

function power_module_size(tolerance=0) = [
  max(power_pcb_size.x, power_socket_size.x) + 2*tolerance,
  power_pcb_size.y + 2*tolerance + power_socket_overhang + 2*tolerance,
  power_pcb_size.z + 2*tolerance + power_socket_size.z + 2*tolerance
];

module power_module(tolerance=0, profile=false, anchor = CENTER, spin = 0, orient = UP) {
  socket_length = (profile ? power_pcb_size.y + power_socket_overhang : power_socket_size.y);
  socket_overlap = socket_length - power_socket_overhang;
  pcb_height = profile
    ? power_pcb_size.z + power_socket_size.z/2
    : power_pcb_size.z;

  pcb_size = [power_pcb_size.x, power_pcb_size.y, pcb_height] + scalar_vec3(2*tolerance);

  socket_size = [power_socket_size.x, socket_length, power_socket_size.z] + scalar_vec3(2*tolerance);

  size = power_module_size(tolerance);

  pcb_front_anchor = [
    0,
    (-pcb_size.y + power_socket_overhang)/2 + tolerance,
    -size.z/2
  ];

  attachable(anchor, spin, orient,
    size = size,
    anchors = [
      named_anchor("pcb_front_bottom", pcb_front_anchor, FRONT),
      named_anchor("pcb_front_top", pcb_front_anchor + [0, 0, power_pcb_size.z + 2*tolerance], FRONT)
    ]
  ) {

    down(size.z/2 - tolerance)
    up(pcb_height/2)
    back(power_socket_overhang/2 + tolerance)
    cuboid(pcb_size) {

      down($eps)
      back(socket_overlap)
      down(profile ? power_socket_size.z/2 : 0)
      position(FRONT+TOP)
      cuboid(socket_size + [0, 0, $eps],
        anchor=BACK+BOTTOM,
        rounding=power_socket_rounding + tolerance, edges="Y");

      if (profile && power_module_porch > 0) {
        fwd(power_module_porch + 2*tolerance)
        position(BACK+BOTTOM)
          cube([
            power_pcb_size.x + 2*tolerance,
            power_module_porch + 2*tolerance,
            size.z
          ], anchor=FRONT+BOTTOM);
      }

    }

    children();
  }
}

function channel_plug_size(tolerance = power_channel_plug_tolerance) = [
  power_channel_size.x - 2*tolerance,
  power_channel_size.y - 4*power_module_tolerance - 2*tolerance,
];

module channel_plug(
  h,
  tolerance = power_channel_plug_tolerance,
  anchor = CENTER, spin = 0, orient = UP
) {
  size = point3d(channel_plug_size(), h);
  notch_wall = 2*power_channel_chamfer;
  channel_size = [
    size.x/2,
    size.y - channel_plug_notch_size.y - notch_wall,
    size.z
  ];
  notch_size = [
    channel_plug_notch_size.x,
    channel_plug_notch_size.y,
    size.z
  ];

  attachable(anchor, spin, orient, size = size) {
    diff(remove="channel notch") cuboid(
      size,
      chamfer=power_channel_chamfer - tolerance,
      edges="Z")
    {
      tag("channel")
      attach(FRONT, BACK, overlap=channel_size.y) cuboid(
        channel_size + [0, $eps, 2*$eps],
        chamfer=power_channel_chamfer - tolerance,
        edges=[
          [0, 0, 0, 0], // yz -- +- -+ ++
          [0, 0, 0, 0], // xz
          [0, 0, 1, 1], // xy
        ]);

      tag("notch")
      attach(BACK, FRONT, overlap=notch_size.y) cuboid(
        notch_size + [0, $eps, 2*$eps],
        chamfer=power_channel_chamfer - tolerance,
        edges=[
          [0, 0, 0, 0], // yz -- +- -+ ++
          [0, 0, 0, 0], // xz
          [1, 1, 0, 0], // xy
        ]);
    }

    children();
  }
}

module if_support() {
  if (!$preview || $support_preview) {
    children();
  }
}

module support_wall(
  h, l,
  gap = support_gap,
  width = support_width,
  anchor = CENTER, spin = 0, orient = UP
) {
  wid = scalar_vec2(width);
  if_support()
  tag("support")
  attachable(anchor, spin, orient, size=[wid.x, l, h]) {
    sparse_wall(
      h=h - 2*gap,
      l=l - 2*gap,
      thick=wid.x,
      strut=wid.y);

    children();
  }
}

function scalar_vec2(v, dflt) =
  is_undef(v)? undef :
  is_list(v)? [for (i=[0:1]) default(v[i], default(dflt, 0))] :
  !is_undef(dflt)? [v,dflt] : [v,v];

module body(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=body_size) {

    diff(remove="mount backstage power_module wire_hole", keep="support") cuboid(
      body_size,
      chamfer = body_chamfer,
      edges = [
        [0, 0, 1, 1], // yz -- +- -+ ++
        [0, 0, 1, 1], // xz
        [1, 1, 1, 1], // xy
      ]
    ) {

      tag("mount")
        attach(FRONT, BOTTOM, overlap=hole_size.z + $eps)
        cuboid(hole_size + [0, 0, 2*$eps])

          tag("backstage")

            attach(BOTTOM, TOP, overlap = module_backstage_overlap)
            cuboid(backstage_size,
              chamfer = backstage_chamfer,
              edges = [
                [0, 0, 1, 1], // yz -- +- -+ ++
                [0, 0, 1, 1], // xz
                [0, 0, 0, 0], // xy
              ])

                attach(BOTTOM, TOP, overlap = backstage_chamfer)
                cuboid([
                  backstage_size.x + 2*backstage_chamfer,
                  backstage_size.y + 2*backstage_chamfer,
                  backstage_chamfer + $eps
                ],
                  chamfer = backstage_chamfer,
                  edges = [
                    [0, 0, 1, 1], // yz -- +- -+ ++
                    [0, 0, 1, 1], // xz
                    [0, 0, 0, 0], // xy
                  ]);

      tag("power_module")
      up(power_module_lift)
      back(body_size.y/2 - struct_val(ppp, "size").x / 2 - body_chamfer - 1)
      left(struct_val(ppp, "size").y - $eps)
      attach(RIGHT+BOTTOM, BACK+BOTTOM)
      xrot(-90)
        power_port();

      wire_hole_h = (body_size.x - backstage_size.x)/2;

      tag("wire_hole")
        down(hole_size.y/2 - wire_hole_d/2 - 0.4)
        back((body_size.y - 2*body_chamfer)/2 - wire_hole_d/2 - 0.4)
        attach([RIGHT, LEFT], BOTTOM, overlap = wire_hole_h + $eps)
        cyl(d=wire_hole_d, h=wire_hole_h + 2*$eps)

          force_tag("support")
          attach(BOTTOM, FRONT, overlap=wire_hole_h + $eps)
          zrot(90)
            support_wall(h=wire_hole_d, l=wire_hole_h);

    }

    children();
  }
}

if ($preview) {
  body();
} else {
  body(anchor=FRONT, orient=FRONT);
  back(body_size.y/2 + 25)
  channel_plug(power_channel_size.z, anchor=BOTTOM);
}
