include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>

use <grid2.scad>

/* [Body dimension] */

// Platform size in grid units.
platform_size = [ 2, 2 ];

// Height of blending/taper hull from grid platform to pillar.
body_taper = 14;

// Height of vertical pillar after taper before sphere cap.
body_lift = 28;

// Chamfer between lift cylinder and platform taper.
body_chamfer = 1.5;

// Diameter of the primary spherical mount.
main_d = 41.5;

// Diameter of the ancilllary shoulder spheres.
shoulder_d = 21;

// Offset between left and right shoulder sphere centers.
shoulder_spacing = 42;

/* [Charing Puck] */

// Charging puck cylinder size: x=diameter, y=height.
puck_size = [ 28, 5 ];

// Charging puck holder inset size; thru hole diameter will be puck diameter reduce by 2 * this value.
puck_inset = [ 5, 28 ];

// Cable slot exit channel size at bottom of puck mount hole.
cableslot_size = [ 7, 14, 37 ];

/* [Backstage Wire Management] */

// Wire exit tunnel diameter, bored thru the rear grid locations.
wire_bore = [ 18, 14 ];

// Wire exit bore count.
wire_bore_n = 2;

// Wire bore placement, necessary when platform_size.y is even, should be a 21-multiple; can be 0 for a 2x1 platform, maybe also if you're doing odd things like a 2x3 platform.
bore_at = 21;

// Enable wire bore development cutaway.
bore_cutaway = $preview;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

function mount_profile(extra=0) = let (
  main = circle(d=main_d + 2*extra),
  shoulder = circle(d=shoulder_d + 2*extra),
  shoulder_off = shoulder_spacing/2,
  pts = concat(
    main,
    left(shoulder_off, p=shoulder),
    right(shoulder_off, p=shoulder)
  ),
  ix = hull2d_path(pts)
) [for (i = ix) pts[i]];

module mount(anchor = CENTER, spin = 0, orient = UP) {
  size = [
    shoulder_spacing + shoulder_d,
    main_d,
    main_d/2
  ];
  attachable(anchor, spin, orient, size=size) {
    down(main_d/4)
    difference() {

      conv_hull() top_half() {
        sphere(d=main_d);
        xcopies(spacing=shoulder_spacing, n=2)
          sphere(d=shoulder_d);
      }

      fwd(main_d/2)
      xrot(45)
      up(50)
        cube(100, center=true);
    }

    children();
  }
}

module mount_lift(anchor = CENTER, spin = 0, orient = UP) {
  size = [
    shoulder_spacing + shoulder_d + body_chamfer*2,
    main_d + body_chamfer *2,
    body_lift + main_d/2
  ];

  attachable(anchor, spin, orient, size=size) {

    down(main_d/4)
    down(body_lift/2)
    offset_sweep(
      mount_profile(),
      height=body_lift + $eps,
      bottom=os_mask(
        mask2d_ogee(["step", [body_chamfer, body_chamfer]], excess=$eps),
        out=true)
    ) attach(TOP, BOTTOM) mount();

    children();
  }
}

module main(anchor = CENTER, spin = 0, orient = UP, alone = false) {
  size1 = 42*platform_size;
  gh = 7;
  fh = struct_val(grid_foot(), "height");

  body_info = grid_body(size1, h=gh);
  h4 = struct_val(body_info, "h4");
  body_size = struct_val(body_info, "size");
  face_d = sqrt(2*(main_d/2)^2);
  setback = (body_size.y - main_d)/2;

  height = gh + body_lift + body_taper + main_d/2;

  size = [size1.x, size1.y, height];

  attachable(anchor, spin, orient,
    size=size,
    anchors=[
      named_anchor("mount",
        [0, -size.y/2, size.z/2]
          + BACK * setback
          + BACK * main_d/2
          + FWD * main_d/4
          + DOWN * main_d/4
        , FWD+UP),
    ]
  ) {

    trans_if(bore_cutaway && !alone)
    cut_if(bore_cutaway && !alone)
    down(height/2)
    up(fh/2)
    union() {

      // grid interface
      grid_copies(spacing=42, n=platform_size)
      up($eps)
        grid_foot(h=$eps, anchor=TOP);

      // taper from grid platfrom to mount profile
      up(fh/2)
      conv_hull()
      grid_body(size1, h=gh, anchor=BOTTOM) {
        attach(TOP, BOTTOM)
          linear_sweep(mount_profile(extra=body_chamfer), h=body_taper);
      }

      up(fh/2)
      down($eps)
      up(h4 + body_taper)
        mount_lift(anchor=BOTTOM);

    }

    children();
  }
}

module cut_if(wen) {
  if (wen) right_half(s=500) children();
  else children();
}

module trans_if(wen) {
  if (wen) %children();
  else children();
}

module debug_if(wen) {
  if (wen) #children();
  else children();
}

// main(alone=true)
// {
//   %show_anchors();
//   #cube($parent_size, center=true);
// }

diff() main() debug_if(bore_cutaway) {

  // puck mount
  tag("remove")
  attach("mount", BOTTOM, overlap=puck_size.y)
    cyl(d=puck_size.x, h=puck_size.y+$eps);

  tunnel_to = body_taper + 7;
  cavity_at = body_taper + 14;
  cavity_size = [42 + wire_bore.x, wire_bore.x, 35];
  clip_inset = cavity_size.y/2 - 3; // mmmm fudge

  // puck inset center bore
  tag("remove")
  front_half(y=clip_inset)
  attach("mount", TOP, overlap=puck_size.y + puck_inset.y - $eps)
    cyl(d=puck_size.x - 2*puck_inset.x, h=puck_inset.y + $eps);

  slot_rot = -22.5;

  slot_size = [
    cableslot_size.x,
    cableslot_size.y+puck_inset.x+1,
    cableslot_size.z + $eps
  ];

  // cable channel in puck hole
  tag("remove")
  front_half(y=clip_inset)
    attach("mount", TOP, overlap=cableslot_size.z)
    zrot(-55)
    fwd((puck_size.x - slot_size.y)/2)
    fwd(slot_size.y/2)
    xrot(slot_rot, cp=[0, 0, slot_size.z/2])
      cuboid(slot_size, rounding=cableslot_size.x/3, edges=[
        [0, 0, 0, 0], // yz -- +- -+ ++
        [0, 0, 0, 0], // xz
        [1, 1, 0, 0], // xy
      ]);

  // interior horizontal cavity
  tag("remove")
    up(cavity_at)
    attach(BOTTOM, TOP, overlap=cavity_size.z/2)
      cuboid(
        cavity_size,
        rounding=cavity_size.y/2, edges=[
          [0, 0, 1, 1], // yz -- +- -+ ++
          [0, 0, 0, 0], // xz
          [1, 1, 1, 1], // xy
        ]);

  if (bore_at != 0) {
    travel_y = tunnel_to - wire_bore.y/4;
    travel_x = -bore_at;
    travel_len = sqrt(travel_y^2 + travel_x^2);
    travel_deg = atan2(travel_y, -travel_x);

    // travel from interior cavity to bore holes
    tag("remove")
    xcopies(spacing=42, n=2)
      up(tunnel_to)
      attach(BOTTOM, TOP)
      xrot(-90+travel_deg)
        cyl(d=wire_bore.y, h=travel_len);
  }

  // bore holes to tunnel riser
  tag("remove")
  xcopies(spacing=42, n=2)
    back(bore_at)
    attach(BOTTOM, TOP, overlap=wire_bore.y)
      cyl(d=wire_bore.x, h=wire_bore.y + $eps, anchor=BOTTOM, rounding2=wire_bore.x/2);

}
