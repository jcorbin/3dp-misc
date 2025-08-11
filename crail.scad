include <BOSL2/std.scad>;

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
wall = 3 * feature;

/* [Rail Options] */

rail_outer_rounding = 20;

rail_wall = 4*wall;

/* [Part Selection] */

// TODO full assembly mode

mode = 10; // [0:Assembly, 10:Test Rail]

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

// TODO factor out 2d rail profile
// - should enable bottom edge chamfer
// - should enable draft angle or lip chamfer/round on filter slot
// - should enable smooth rounding method

module rail(h, anchor = CENTER, spin = 0, orient = UP) {

  size = [ rail_width, rail_width, h ];

  attachable(anchor, spin, orient, size=size, anchors=[

    // TODO "filter_slot_N" ; TODO unify with slot nudging below

    // named_anchor("under", [0, 0, H/2 - handle_size.y], DOWN),
    // named_anchor("foot_left", [-foot_xat, 0, -H/2], DOWN),
    // named_anchor("foot_right", [foot_xat, 0, -H/2], DOWN),

    // TODO "thru_hole_N

  ]) {

    // TODO all of diff children can flatten into 2d profile
    diff() cuboid(size) {
      // rounded outer corner
      tag("remove") edge_mask(edges = [
        [0, 0, 0, 0], // yz -- +- -+ ++
        [0, 0, 0, 0], // xz
        [1, 0, 0, 0], // xy
      ]) rounding_edge_mask(l=h+2*$eps, r=rail_outer_rounding);

      // chamfer inner corner as a fillet between filter slots
      tag("remove") edge_mask(edges = [
        [0, 0, 0, 0], // yz -- +- -+ ++
        [0, 0, 0, 0], // xz
        [0, 0, 0, 1], // xy
      ]) chamfer_edge_mask(l=h+2*$eps, chamfer = rail_fillet);

      // generic chamfer on other 2 Z edges
      tag("remove") edge_mask(edges = [
        [0, 0, 0, 0], // yz -- +- -+ ++
        [0, 0, 0, 0], // xz
        [0, 1, 1, 0], // xy
      ]) chamfer_edge_mask(l=h+2*$eps, chamfer = chamfer);

      // filter slots
      tag("remove") {
        position(BACK+LEFT)
        right(rail_wall)
        back($eps)
          cuboid([filter_slot.x, filter_slot.y+$eps, h + 2*$eps], anchor=BACK+LEFT);
        position(FRONT+RIGHT)
        back(rail_wall)
        right($eps)
          cuboid([filter_slot.y+$eps, filter_slot.x, h + 2*$eps], anchor=FRONT+RIGHT);
      }
    }

    // TODO interlock

    // TODO outside attachment system, e.g. thru holes for zip-ties/cord/etc

    children();
  }
}

// TODO filter grip bumps

// TODO fan holder / grip

// TODO wire management afforance

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

  rail(25);

  // TODO attach buddies to named anchor points
  // filter_panel(orient=FRONT, anchor=LEFT);
  // filter_panel(orient=RIGHT, anchor=FRONT);

}

// preview_cut()

// anchnut(
//   d=mode == 1 ? 40 : undef,
//   orient=$preview ? UP : DOWN
// );

// {
//   // position(TOP) #sphere(1);
//   %show_anchors();
//   #cube($parent_size, center=true);
// }

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
