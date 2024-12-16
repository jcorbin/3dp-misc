include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>

use <grid2.scad>

/* [Gridfinity Platform] */

// Platform size in grid units.
platform_size = [ 2, 2 ];

/* [Front Face] */

// Phone holder tray size: xy should roughly match phone dimensions, z sets tactile rim depth.
tray_size = [ 59, 120, 7 ];

// Set back tray face from front edge by this amount
tray_back = 12;

// When setting the tray back, create a lip at the block front edge.
tray_lip = [ 1.2, 3.5 ];

// Angle at which the phone holder tray is stood up from the xy plane.
tray_angle = 65;

// How far up the phone tray to place the puck mount; proportion of tray_size.y space.
tray_mount_loc = 0.75;

/* [Charing Puck] */

// Charging puck cylinder size: x=diameter, y=height.
puck_size = [ 56, 5 ];

// Charging puck holder inset size; thru hole diameter will be puck diameter reduce by 2 * this value.
puck_inset = 5;

// Cable slot exit channel size at bottom of puck mount hole.
cableslot_size = [ 5, 12 ];

/* [Backstage Wire Management] */

// Wire exit tunnel diameter, bored thru the rear grid locations.
wire_bore_d = 20;

// Wire exit bore count.
wire_bore_n = 2;

// Wire management back stage width in grid units.
wire_stage_width = 1;

// Wire management back stage depth.
wire_stage_depth = 40;

/* [Dummy Phone] */

// Size of dummy phone for fit modeling.
phone_dummy = [ 71.5, 149.5, 9 ];

phone_dummy_camera = [ 40, 40, 4 ];

phone_dummy_camera_inset = 4;

// Translation along the tray face vector, relative to "on magnet mount".
phone_dummy_move = 0; // -42 will make it sit in the tray lip

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
  fh = struct_val(grid_foot(), "height");
  height = gh + sin(tray_angle) * tray_size.y;

  grid_front_top = [0, -size1.y/2 + tray_back, -height/2 + gh];
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

      grid_body(size1, h=gh, anchor=BOTTOM) {
        body_info = grid_body(size1, h=gh);
        body_size = struct_val(body_info, "size");
        base_size = body_size - [ 0, tray_back, 0 ];
        body_round = struct_val(body_info, "rounding");

        // grid space bounding box check aid
        // %down(fh) position(BOTTOM) cuboid([
        //   body_size.x,
        //   body_size.y,
        //   7 * 21
        // ], rounding=body_round, edges="Z", anchor=BOTTOM);

        conv_hull()
        back(tray_back/2)
        cuboid(base_size, rounding=body_round, edges="Z")
          position(FRONT+TOP)
          top_half(s=max(tray_size)*2)
          xrot(tray_angle)
            cuboid(tray_size, rounding=tray_size.x/2, edges=[
              [0, 0, 0, 0], // yz -- +- -+ ++
              [0, 0, 0, 0], // xz
              [0, 0, 1, 1], // xy
            ], anchor=FRONT+TOP);

        if (tray_back > 0 && tray_lip.x * tray_lip.y > 0) {
          lip_size = [ base_size.x, body_size.y, tray_lip.y ];
          lip_oround = body_round;

          lip_isize = lip_size - [ 2*tray_lip.x, 2*tray_lip.x, 0 ];
          lip_iround = lip_oround - tray_lip.x;

          attach(TOP, BOTTOM)
          tag_scope("lip")
          diff()
          cuboid(lip_size, rounding=lip_oround, edges="Z")
            tag("remove")
            attach(TOP, BOTTOM, overlap=lip_isize.z+$eps)
              cuboid(lip_isize + [0, 0, 2*$eps], rounding=lip_iround, edges="Z");

        }

      }

      grid_copies(spacing=42, n=platform_size)
      up($eps)
        grid_foot(h=$eps, anchor=TOP);

    }

    children();
  }
}

module dummy(anchor = CENTER, spin = 0, orient = UP) {
  size = phone_dummy + [ 0, 0, phone_dummy_camera.z ];

  if (size.x*size.y*size.z > 0) {
    case_bottom = [ 0, 0, phone_dummy_camera.z/2 - phone_dummy.z/2 ];

    attachable(anchor, spin, orient,
      size=size,
      anchors=[
        named_anchor("mount", case_bottom, DOWN),
      ]) {

      up(size.z/2)
      down(phone_dummy.z/2)
      cuboid(phone_dummy, rounding=12, edges="Z")

        left(phone_dummy_camera_inset)
        left(phone_dummy_camera.x/2)
        right(phone_dummy.x/2)

        back(phone_dummy_camera_inset)
        back(phone_dummy_camera.y/2)
        fwd(phone_dummy.y/2)

        attach(BOTTOM, TOP, overlap=$eps)
        cuboid(phone_dummy_camera + [0, 0, $eps], rounding=12, edges="Z");

      children();
    }
  }
}

diff() body() {

  // dummy phone
  face_up = apply(xrot(-(90-tray_angle)), UP);
  move(face_up * phone_dummy_move)
  attach("face_mount", "mount")
    %dummy(spin=180);

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
  fh = struct_val(grid_foot(), "height");
  bh = fh + sin(tray_angle) * tray_size.y * tray_mount_loc - puck_size.x/2;

  tag("remove")
  back( 42 * (platform_size.y-1)/2 )
  down(fh)
  position(BOTTOM) {
    // bore holes to tunnel riser
    down($eps)
    down(fh)
    xcopies(spacing=42, n=wire_bore_n)
      cyl(d=wire_bore_d, h=bh/2+2*$eps, anchor=BOTTOM);

    stage_gw = max(1, wire_stage_width);
    stage_w = 42*stage_gw + wire_bore_d;
    stage_r = wire_bore_d/2;
    stage_taper_to = stage_r*2;
    stage_fudge = 10;
    rr = stage_r*.95;

    // backstage area
    back(stage_fudge)
    up(bh/2 + $eps)
      prismoid(
        size1=[stage_w, wire_stage_depth],
        size2=[stage_w, stage_taper_to],
        h=bh,
        shift=[0, wire_stage_depth - stage_taper_to ],
        rounding=stage_r,
        anchor=BOTTOM)
          attach(BOTTOM, TOP, overlap=$eps)
            cuboid([stage_w, wire_stage_depth, 7 + $eps],
            rounding=stage_r, edges=[
              [0, 0, 0, 0], // yz -- +- -+ ++
              [0, 0, 0, 0], // xz
              [1, 1, 0, 0], // xy
            ])
              fwd(rr-1)
              edge_mask("X", except=[FRONT, TOP])
                rounding_edge_mask(l=stage_w, r=rr, spin=-90);

  }

}

// {
//   // position(TOP) #sphere(1);
//   %show_anchors();
//   #cube($parent_size, center=true);
// }
