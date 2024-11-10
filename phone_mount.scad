include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>

use <grid2.scad>

// Platform size in grid units.
platform_size = [ 2, 2 ];

// Charging puck cylinder size: x=diameter, y=height.
puck_size = [ 56, 5 ];

// Charging puck holder inset size; thru hole diameter will be puck diameter reduce by 2 * this value.
puck_inset = 5;

// Cable slot exit channel size at bottom of puck mount hole.
cableslot_size = [ 5, 12 ];

// Phone holder tray size: xy should roughly match phone dimensions, z sets tactile rim depth.
tray_size = [ 69, 150, 7 ];

// Angle at which the phone holder tray is stood up from the xy plane.
tray_angle = 70;

// How far up the phone tray to place the puck mount; proportion of tray_size.y space.
tray_mount_loc = 0.75;

// Wire exit tunnel diameter, bored thru the rear grid locations.
wire_bore_d = 20;

// Wire exit bore count.
wire_bore_n = 2;

// Wire management back stage width in grid units.
wire_stage_width = 1;

// Wire management back stage depth.
wire_stage_depth = 40;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

module body(anchor = CENTER, spin = 0, orient = UP) {
  size1 = 42*platform_size;
  gh = 7;
  fh = struct_val(grid_foot(), "profile_height");
  height = gh + sin(tray_angle) * tray_size.y;

  grid_front_top = [0, -size1.y/2, -height/2 + gh];
  face_tangent = apply(xrot(-(90-tray_angle)), FRONT);
  face_up = apply(xrot(-(90-tray_angle)), UP);

  attachable(anchor, spin, orient,
    size=[size1.x, size1.y, height],
    anchors=[
      named_anchor("root", grid_front_top, face_tangent),
      named_anchor("face_mount",
        move(face_up * tray_size.y * tray_mount_loc, grid_front_top),
        face_tangent),
    ]
  ) {

    down(height/2)
    up(fh)
    union() {

      conv_hull()
      grid_body(size1, h=gh, anchor=BOTTOM) {
        position(FRONT+TOP)
        top_half(s=max(tray_size)*2)
        xrot(tray_angle)
        cuboid(tray_size, rounding=tray_size.x/3, edges=[
          [0, 0, 0, 0], // yz -- +- -+ ++
          [0, 0, 0, 0], // xz
          [0, 0, 1, 1], // xy
        ], anchor=FRONT+TOP);
      }

      grid_copies(spacing=42, n=platform_size)
      up($eps)
        grid_foot(h=$eps, anchor=TOP);

    }

    children();
  }
}

diff() body() {

  // puck mount
  attach("face_mount", BOTTOM, overlap=puck_size.y)
    tag("remove")
    cyl(d=puck_size.x, h=puck_size.y+$eps) {
      attach(BOTTOM, TOP, overlap=$eps)
        cyl(d=puck_size.x - 2*puck_inset, h=84+$eps);

      // cable channel in puck hole
      attach(FRONT, TOP, overlap=puck_inset+1)
        cuboid(
          [
            cableslot_size.x,
            42*platform_size.y*2,
            cableslot_size.y+puck_inset+1
          ],
          rounding=cableslot_size.x/3, edges=[
          [0, 0, 0, 0], // yz -- +- -+ ++
          [1, 1, 0, 1], // xz
          [0, 0, 0, 1], // xy
        ]);
    }

    // cable management
    fh = struct_val(grid_foot(), "profile_height");
    bh = fh + sin(tray_angle) * tray_size.y * tray_mount_loc - puck_size.x/2;

    tag("remove")
    back( 42 * (platform_size.y-1)/2 )
    down(fh)
    position(BOTTOM) {
      // bore holes to tunnel riser
      down($eps)
      down(fh)
      xcopies(spacing=42, n=wire_bore_n)
        cyl(d=wire_bore_d, h=bh+2*$eps, anchor=BOTTOM);

      stage_w = max(1, wire_stage_width);

      // backstage area
      back(10)
      up(bh/2 + $eps)
        cuboid(
          [42*stage_w + wire_bore_d, wire_stage_depth, 2*bh],
          rounding=wire_bore_d/2, edges="Z",
          anchor=BOTTOM);
    }

}

// {
//   // position(TOP) #sphere(1);
//   %show_anchors();
//   #cube($parent_size, center=true);
// }
