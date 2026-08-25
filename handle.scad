include <BOSL2/std.scad>;
include <BOSL2/screws.scad>;

/***

# What this is

A grab handle, and the plate that backs it.

The handle is a swept arch standing on two feet.
Each foot carries a captive nut in a side-entry trap, and a bolt comes up from
behind the panel, through the plate, through the panel, and into that nut.
The plate is the washer for that joint -- it is what stops two M4s pulling
through whatever the handle is bolted to.

It was drawn for a Corsi-Rosenthal box; see corsi_jig.scad, whose plate_w is
the same 200 that thru_size carries, and the parts packed alongside it.

Axes:
- X runs along the span
- Y front-to-back through the grip
- Z up out of the panel

Every part is drawn in the assembled frame, which is the frame to design
in and the wrong one to export from -- see the dispatch section for what each
part mode turns onto its bed.

# TODO

- feature: grip features under the span. handle() has the anchor for them and
  nothing attached to it.
- feature: a head recess in the plate, so the bolt head sits in it rather than
  on it. See bolt_holes().
- feature: animate explode.

*/

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Part Parameters] */

// Generic chamfer, for bed interface and for edges a hand runs over.
chamfer = 1.5;

/* [Mount Screws & Nuts] */

// Mount screw and nut type; supports both metric like "M4" and UTS like "#8-32".
mount_screw_spec = "M4";

// Preview screw length; does not impact final model.
mount_screw_length = 20;

// Preview screw head; does not impact final model.
mount_screw_head = "button";

// Preview screw drive; does not impact final model.
mount_screw_drive = "hex";

// Screw shaft tolerance: bore hole diameter add.
mount_screw_tol = 0.5;

// Nut insert socket tolerance: X is face-to-face add, Y is thickness add.
mount_nut_tol = [ 0.2, 0.1 ];

/* [Handle Body Specs] */

// Handle cross section size: X is front-to-back, Y is top-to-bottom of the span section.
handle_size = [ 34, 21 ];

// Handle cross section chamfers: top-back, top-front, bottom-front, bottom-back
handle_chamfer = [ 3, 3, 5, 5 ];

// Interior span of handle; i.e. how wide is the underside/grip.
handle_span = 100;

// Height of central handle outline; outer/inner edges are +/- half profile height; overall height will actually be this + handle_size.y
handle_height = 30;

// Vertial lift before angular turn.
handle_lift = 15;

// Turning angle from top span to each vertical foot.
handle_ang = 45;

/* [Mount Plate Specs] */

// Mount plate thickness.
plate_thickness = 5;

// Mount plate Z-corner chamfer.
plate_chamfer = 5;

// How far the plate stands proud of the handle's feet, all round.
plate_margin = plate_chamfer;

/* [Panel] */

// Size of the preview mockup board that the handle bolts through.
thru_size = [ 500, 200, 5 ];

/* [Part Selection] */

// Which part to model
mode = 0; // [0:Assembly, 1:Handle, 2:Plate, 100:Cross Section, 101:Outline Path, 102:Nut Insert Test, 103:Nut Insert Negative]

// Section cutaway in preview mode.
preview_cut = true;

// How far apart to hold the assembly's parts in mode 0.
explode = 10;

module __customizer_limit__() {}

/// handle body
//
// The arch is one path_sweep: a cross section carried along an outline that
// goes up, turns handle_ang, runs across, turns back and comes down.
//
// The outline is drawn in XY and stood up by xrot(90), so:
// - the profile's own X is the section's thickness along the path
// - and its Y is the width across the grip
// Which is why handle_size reads [across, through] and the two get swapped
// everywhere below.

handle_profile = rot(-90, p=rect(size=handle_size, chamfer=handle_chamfer));

handle_int_ang = 90 - handle_ang;
handle_diag_h = (handle_height - handle_lift);
handle_diag = handle_diag_h / sin(handle_int_ang);
handle_shift = handle_diag_h / tan(handle_int_ang);
handle_width = handle_span + 2*handle_shift;

handle_outline = turtle([
  "left", 90,
  "move", 2*handle_lift,
  "right", handle_ang,
  "move", handle_diag,
  "right", 90-handle_ang,

  "move", handle_span,

  "right", 90-handle_ang,
  "move", handle_diag,
  "right", handle_ang,
  "move", 2*handle_lift,
], state=-[handle_width, handle_height]/2 - [0, handle_lift]);

// What the arch stands in, and what squares its ends off.
// The sweep reaches this box on all six faces,
// so anything sizing itself to the handle can read it here
// rather than going back to the outline -- see plate_size().
handle_body_size = [
  handle_width + handle_size.y,
  handle_size.x,
  handle_height + handle_size.y
];

module handle_body(
  anchor = CENTER,
  spin = 0,
  orient = UP,
) {
  attachable(anchor, spin, orient, size=handle_body_size,
    anchors = let (
      H = handle_body_size.z,
      foot_xat = handle_span/2 + handle_shift
    ) [
      named_anchor("under", [0, 0, H/2 - handle_size.y], DOWN),
      named_anchor("foot_left", [-foot_xat, 0, -H/2], DOWN),
      named_anchor("foot_right", [foot_xat, 0, -H/2], DOWN),
    ]
  ) {
    xrot(90)
    intersection() {
      path_sweep(handle_profile, handle_outline);
      cuboid([ handle_body_size.x, handle_body_size.z, handle_body_size.y ]);
    }

    children();
  }
}

module handle(
  anchor = CENTER,
  spin = 0,
  orient = UP,
) {
  handle_bolt_depth = 20;
  nut_offset = 5;

  nut_at = handle_body_size.x - handle_size.y;
  nut_depth = handle_bolt_depth/2 - nut_offset;

  attachable(anchor, spin, orient, size=handle_body_size, anchors=[
    named_anchor("left_nut",  [-nut_at/2, 0, -handle_body_size.z/2 + nut_depth], DOWN),
    named_anchor("right_nut", [ nut_at/2, 0, -handle_body_size.z/2 + nut_depth], DOWN),
  ]) {
    tag_scope("handle")
    diff()
    handle_body(orient=UP) {

      // Each trap is spun to face outward,
      // so its nut goes in from the end of the handle
      // rather than through the grip.
      tag("remove")
      attach("foot_left", BOTTOM, spin=-90, overlap=handle_bolt_depth)
        nut_insert(mount_screw_spec, handle_bolt_depth + $eps, nut_offset=nut_offset, entry=handle_size.y/2);

      tag("remove")
      attach("foot_right", BOTTOM, spin=90, overlap=handle_bolt_depth)
        nut_insert(mount_screw_spec, handle_bolt_depth + $eps, nut_offset=nut_offset, entry=handle_size.y/2);

      // attach("under") TODO grip features
    }

    children();
  }
}

/// mount plate

// Where the bolts land, and how big a hole each one wants.
//
// The spacing is the feet's own, derived rather than set:
// - handle_body_size.x is the box the arch stands in
// - taking a section thickness off it lands on the centerline of each foot
//
// The plate, the panel and the handle all read this,
// so none of them can disagree about a hole.
function bolt_holes() = let (
  bolt_at = handle_body_size.x - handle_size.y,
  bore_d = struct_val(screw_info(mount_screw_spec), "diameter") + mount_screw_tol
) [
  [ "at", bolt_at ],
  [ "diameter", bore_d ],
];

// The bores themselves, as a negative for whoever calls it difference.
// It does not tag itself: the tag has to be applied at the call
// site, inside the scope of the diff() that is meant to see it.
//
// center adds a third hole in the middle, which is not a fastener and has
// nothing passing through it. It is a sight line for whoever installs the
// thing: the plate goes on the back of the panel, where its own edges line up
// with nothing, and a center hole lets it be registered against a mark on the
// panel instead of measured 65mm in from an edge that may not be square to
// anything.
module bolt_holes(
  h,
  center = false,
  anchor = CENTER,
  spin = 0,
  orient = UP,
) {
  info = bolt_holes();
  bore_d = struct_val(info, "diameter");
  bolt_at = struct_val(info, "at");

  attachable(anchor, spin, orient, size=[ bolt_at + bore_d, bore_d, h ]) {
    up($eps) {
      xcopies(spacing=bolt_at)
        cyl(d=bore_d, h=h + 2*$eps);

      if (center)
        cyl(d=bore_d, h=h + 2*$eps);
    }

    // TODO head socket recess wen

    children();
  }
}

// The plate's outside size, taken off the box the arch stands in rather than
// set: handle_body_size is exactly the feet's footprint in XY, since the sweep
// reaches it on every face. See plate_margin.
function plate_size() = [
  handle_body_size.x + 2*plate_margin,
  handle_body_size.y + 2*plate_margin,
  plate_thickness,
];

module plate(
  anchor = CENTER,
  spin = 0,
  orient = UP,
) {
  size = plate_size();

  attachable(anchor, spin, orient, size=size, anchors=let (
    bolt_at = struct_val(bolt_holes(), "at")
  ) [
    named_anchor("left_bolt",  [-bolt_at/2, 0, -size.z/2], DOWN),
    named_anchor("right_bolt", [ bolt_at/2, 0, -size.z/2], DOWN),
  ]) {
    diff()
    cuboid(size, chamfer=plate_chamfer, edges="Z")
      tag("remove")
      attach(TOP, BOTTOM, overlap=size.z + $eps)
      bolt_holes(size.z, center=true);

    // TODO ribs?

    children();
  }
}

/// nut inserts

// The negative that makes a captive nut trap:
// - a shaft bore all the way through
// - a hexagonal pocket part way up it
// - a slot out one side for the nut to go in through
//
// Container counterbore hole compensations: a slicer trick made via a stack of
// prismoid and cuboids on top of the pocket.
module nut_insert(
  spec,
  h,
  nut_offset = 0,
  entry = 0,
  retain = 0/* 0.4*/,
  bore_tol = mount_screw_tol,
  nut_tol = mount_nut_tol,
  decompose = false,
  anchor = CENTER,
  spin = 0,
  orient = UP,
) {
  N = nut_info(spec);
  BD = struct_val(N, "diameter");
  W = struct_val(N, "width") + nut_tol.x;
  T = struct_val(N, "thickness");
  ND = W/cos(30);

  // TODO assert h > T

  layer = 0.2;
  hd = BD + bore_tol;
  nh = T + nut_tol.y;

  attachable(anchor, spin, orient, size=[ND, W, h]) {
    union() {
      // shaft hole
      color_if(decompose, "#00990088")
      cyl(d=hd, h=h);

      up(nut_offset) {

        // nut holder
        color_if(decompose, "#00009988", just=true)
        cyl(d=ND, h=nh, $fn=6)

          // slicer fixup/trick for nut/shaft ceiling transition
          color_if(decompose, "#ff000088")
          attach(TOP, FRONT, overlap=$eps)
          prismoid(
            size1=[entry > 0 ? ND : hd, layer+$eps],
            size2=[BD, layer+$eps], h=W)

            attach(BACK, BOTTOM, overlap=$eps)
            cuboid([hd, W, layer+$eps])

            attach(TOP, BOTTOM, overlap=$eps)
            cuboid([hd, hd, layer+$eps]);

        // nut access
        if (entry > 0) {
          color_if(decompose, "#ff990088", just=true)
          tag_scope("hole_nut_access")
          diff() cuboid([ND, max(W/2, entry), nh], anchor=BACK)
            // retention bumps
            if (retain > 0) {
              rd = 2*retain + bore_tol;
              tag("remove")
              color_if(decompose, "#ff990088")
                fwd(rd)
                xcopies(spacing=[-ND/2, ND/2])
                position(BACK)
                cyl(d=rd, h=nh);
            }
        }
      }

    }

    children();
  }
}

/// fit tests

// A slice of the foot with one trap in it: the same nut_insert() through the
// same section, in a few grams rather than a whole handle.
module nut_insert_test(
  anchor = CENTER,
  spin = 0,
  orient = UP,
) {
  attachable(anchor, spin, orient, size=[
    handle_size.y,
    handle_size.x,
    10
  ]) {
    zrot(180)
    diff()
    path_sweep(handle_profile, [
      [0, 0, -5],
      [0, 0, 5],
    ])
      tag("remove")
      attach(TOP, BOTTOM, spin=-90, overlap=10+$eps)
        nut_insert(mount_screw_spec, 10 + 2*$eps, entry=11);

    children();
  }
}

/// helpers

module color_if(when, name, just=false) {
  if (!when) children();
  else if (just) color_this(name) children();
  else color(name) children();
}

// Section away half the model in preview.
module preview_cut(v = BACK, s = 10000) {
  if (preview_cut && $preview) {
    half_of(v=v, s=s) {
      // The union() matters: half_of() differences every child past the first
      // out of the first one, so handing it a list of siblings would cut them
      // against each other.
      union() children();
    }
  } else {
    children();
  }
}

/// dispatch / integration

//@make -o handle.stl -D mode=1
//@make -o handle_plate.stl -D mode=2
//@make -o handle_nut_test.stl -D mode=102

// Every part is drawn where it sits in the assembly, which is the frame that
// lets the plate take its bolt spacing off the handle's feet, and not a frame
// any of it prints in.
//
// An STL carries no intent -- whatever orientation it lands in is the one the
// slicer opens with -- so each part mode below hands its part the orient= that
// turns it onto its bed.
//
// What decides each:
//
// - **handle**: DOWN, crown on the bed
//   - upright it would stand on two 21 x 34 feet and carries a 100mm span
//     between them
//   - inverted it lies on the flat top of that span, which is the widest
//     continuous face on the part, and the feet are what is left in the air
//   - either way the legs are handle_ang off vertical and nothing overhangs
//     worse than that
//   - The preview keeps it upright: orientation is an export concern, and
//     standing it on its head in the GUI only makes it harder to read against
//     the assembly
//
// - **plate**: UP, and it does not matter which way up
//   - the plate is a slab with the same chamfer on both faces.
//
// - Modes 100 and 101 take none of this. They are 2D diagnostics of the
//   section and of the path it sweeps, drawn as strokes
// - Mode and 103 is the nut trap's negative on its own with its parts colored
//   apart.
module main() {
  if (mode == 0) {
    assembly();
  }

  else if (mode == 1) {
    preview_cut() handle(orient = $preview ? UP : DOWN);
  }

  else if (mode == 2) {
    preview_cut() plate();
  }

  else if (mode == 100) {
    stroke(handle_profile, closed=true, width=1);
  }

  else if (mode == 101) {
    stroke(handle_outline, closed=false, width=1);
  }

  else if (mode == 102) {
    preview_cut() nut_insert_test();
  }

  else if (mode == 103) {
    nut_insert(mount_screw_spec, h=10, entry=5, decompose=true);
  }
}

// Plate, panel, handle, and the hardware between them, held apart by explode.
module assembly() {
  preview_cut()
  color_this("#0000aaff") plate() {

    up(explode/2)
    attach(TOP, BOTTOM)
    color_this("#333333ff") diff() cuboid(thru_size) {

      tag("remove")
      attach(TOP, BOTTOM, overlap=thru_size.z + $eps)
        bolt_holes(thru_size.z);

      tag("keep")
      attach(TOP, BOTTOM, overlap=-explode/2)
      color_this("#00aa00ff") handle()
        // The nuts back out along their traps' own axis, which runs across the
        // grip, and stop at the face they went in through.
        let (
          nut_travel = (handle_size.x - struct_val(nut_info(mount_screw_spec), "width"))/2,
          nut_xplo = min(nut_travel, 2*explode)
        )
          attach([ "left_nut", "right_nut" ], CENTER)
          translate([ $idx % 2 == 0 ? -1 : 1, 0, 0 ] * nut_xplo)
          color("red") nut(mount_screw_spec);

    }

    attach([ "left_bolt", "right_bolt" ], BOTTOM, overlap=mount_screw_length)
      up(min(mount_screw_length, 2*explode))
      color("red") screw(mount_screw_spec, head=mount_screw_head, drive=mount_screw_drive, length=mount_screw_length);
  }
}

main();

// XXX module dev assist
// {
//   // position(TOP) #sphere(1);
//   // %show_anchors();
//   // #cube($parent_size, center=true);
// }

// module XXX(anchor = CENTER, spin = 0, orient = UP) {
//   size = [XXX.x, XXX.z, XXX.y];
//   attachable(anchor, spin, orient, size=size) {
//     // XXX geometry; e.g. import to remix/rework
//     // down(size.z/2)
//     // back(size.y/2)
//     // left(size.x/2)
//     //   import("XXX.stl");
//     children();
//   }
// }
