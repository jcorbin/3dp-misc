include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>

use <grid2.scad>

/* [Body dimension] */

// Platform size in grid units.
platform_size = [ 2, 1 ];

// Height of blending/taper hull from grid platform to pillar.
body_taper = 14;

// Height of vertical pillar after taper before sphere cap.
body_lift = 21;

/* [Charing Puck] */

// Charging puck cylinder size: x=diameter, y=height.
puck_size = [ 28, 5 ];

// Charging puck holder inset size; thru hole diameter will be puck diameter reduce by 2 * this value.
puck_inset = [ 5, 25 ];

// Cable slot exit channel size at bottom of puck mount hole.
cableslot_size = [ 7, 14, 30 ];

/* [Backstage Wire Management] */

// Wire exit tunnel diameter, bored thru the rear grid locations.
wire_bore = [ 18, 18 ];

// Wire exit bore count.
wire_bore_n = 2;

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
  height = gh + body_lift + body_taper + 21;


  size = [size1.x, size1.y, height];

  body_info = grid_body(size1, h=gh);
  h4 = struct_val(body_info, "h4");
  body_size = struct_val(body_info, "size");

  main_d = body_size.y;
  face_d = sqrt(2*(main_d/2)^2);

  attachable(anchor, spin, orient,
    size=size,
    anchors=[
      named_anchor("mount",
        [0, -size.y/2, size.z/2]
          + BACK * main_d/2
          + FWD * main_d/4
          + DOWN * main_d/4
        , FWD+UP),
    ]
  ) {

    down(height/2)
    up(fh)
    union() {

      grid_copies(spacing=42, n=platform_size)
      up($eps)
        grid_foot(h=$eps, anchor=TOP);

      conv_hull()
      grid_body(size1, h=gh, anchor=BOTTOM) {
        attach(TOP, BOTTOM)
          cyl(d=main_d, h=body_taper);
        attach(TOP, BOTTOM)
        xcopies(spacing=42)
          cyl(d=21, h=body_taper);
      }

      down($eps)
      up(h4 + body_taper)
      conv_hull()
      {
        cyl(d=main_d, h=body_lift + 2*$eps, anchor=BOTTOM);
        xcopies(spacing=42)
          cyl(d=21, h=body_lift + 2*$eps, anchor=BOTTOM);
      }

      up(h4 + body_taper + body_lift)
      conv_hull()
      difference() {
        top_half() {
          sphere(d=main_d);
          xcopies(spacing=42)
            sphere(d=21);
        }

        fwd(main_d/2)
        xrot(45)
        up(50)
          cube(100, center=true);

      }

    }

    children();
  }
}

// body()
// {
//   %show_anchors();
//   #cube($parent_size, center=true);
// }

diff() body() {

  // puck mount
  attach("mount", BOTTOM, overlap=puck_size.y)
    tag("remove")
    cyl(d=puck_size.x, h=puck_size.y+$eps) {
      attach(BOTTOM, TOP, overlap=$eps)
        cyl(d=puck_size.x - 2*puck_inset.x, h=puck_inset.y+$eps);
      // cable channel in puck hole
      zrot(-45)
      back(puck_inset.x+1)
      up($eps)
      position(FRONT+TOP)
        cuboid(
          [
            cableslot_size.x,
            cableslot_size.z + $eps,
            cableslot_size.y+puck_inset.x+1
          ],
          rounding=cableslot_size.x/3, edges=[
            [0, 0, 0, 0], // yz -- +- -+ ++
            [0, 0, 1, 1], // xz
            [0, 0, 0, 0], // xy
          ],
          anchor=BOTTOM+BACK,
          orient=FRONT
        );
    }

  // bore holes to tunnel riser
  tag("remove")
  // #down(42)
    up(14 + wire_bore.y)
    attach(BOTTOM, TOP)
      down($eps)
      cuboid(
        [42 + wire_bore.x, wire_bore.x, 14+$eps],
        rounding=wire_bore.x/2,
        // edges="Z",
        edges=[
          [0, 0, 1, 1], // yz -- +- -+ ++
          [0, 0, 0, 0], // xz
          [1, 1, 1, 1], // xy
        ],
        anchor=BOTTOM+LEFT
      )
        xcopies(spacing=42, n=2)
        attach(BOTTOM, TOP, overlap=$eps)
          cyl(d=wire_bore.x, h=wire_bore.y + $eps, anchor=BOTTOM);

}
