include <BOSL2/std.scad>;
include <BOSL2/screws.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Part Selection] */

// Which part to model
mode = 0; // [0:Assembly, 1:Handle, 2:Plate, 100:Cross Section, 101:Outline Path, 102:Nut Insert Test, 103:Nut Insert Negative]

// Enables preview cutaway for some parts.
cutaway = true;

// Mounting screw and nut spec.
screw_spec = "M4";

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

// Turning angle from top span to each vertical foot
handle_ang = 45;

/* [Mount Plate Specs] */

// Mount plate thickness.
plate_thickness = 5;

// Mount plate Z-corner chamfer.
plate_chamfer = 5;

// Mount plate additional width/height beyond handle footprint.
plate_margin = [ 10, 10 ];

/// dispatch / integration

module __customizer_limit__() {}

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

handle_body_size = [
  handle_width + handle_size.y,
  handle_size.x,
  handle_height + handle_size.y
];

module handle_body(anchor = CENTER, spin = 0, orient = UP) {
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

module color_if(when, name, just=false) {
  if (!when) children();
  else if (just) color_this(name) children();
  else color(name) children();
}

module nut_insert(spec, h, nut_offset=0, entry = 0, retain = 0/* 0.4*/, bore_tol = 0.5, nut_tol = 0.2, decompose = false, anchor = CENTER, spin = 0, orient = UP) {
  N = nut_info(spec);
  BD = struct_val(N, "diameter");
  W = struct_val(N, "width");
  T = struct_val(N, "thickness");
  ND = W/cos(30);

  // TODO assert h > T

  layer = 0.2;
  hr = BD + bore_tol;
  nh = T + nut_tol;

  attachable(anchor, spin, orient, size=[ND, W, h]) {
    union() {
      // shaft hole
      color_if(decompose, "#00990088")
      cyl(d=hr, h=h);

      up(nut_offset) {

        // nut holder
        color_if(decompose, "#00009988", just=true)
        cyl(d=ND, h=nh, $fn=6)

          // slicer fixup/trick for nut/shaft ceiling transition
          color_if(decompose, "#ff000088")
          attach(TOP, FRONT, overlap=$eps)
          prismoid(
            size1=[entry > 0 ? ND : hr, layer+$eps],
            size2=[BD, layer+$eps], h=W)

            attach(BACK, BOTTOM, overlap=$eps)
            cuboid([hr, W, layer+$eps])

            attach(TOP, BOTTOM, overlap=$eps)
            cuboid([hr, hr, layer+$eps]);

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

module handle(anchor = CENTER, spin = 0, orient = UP) {
  handle_bolt_depth = 20;
  nut_offset = 5;

  nut_at = handle_body_size.x - handle_size.y;
  nut_depth = handle_bolt_depth/2 - nut_offset;

  attachable(anchor, spin, orient, size=handle_body_size, anchors=[
    named_anchor("left_nut",  [-nut_at/2, 0, -handle_body_size.z/2 + nut_depth], DOWN),
    named_anchor("right_nut", [ nut_at/2, 0, -handle_body_size.z/2 + nut_depth], DOWN),
  ]) {
    diff()
    handle_body(orient=UP) {

      tag("remove")
      attach("foot_left", BOTTOM, spin=-90, overlap=handle_bolt_depth)
        nut_insert(screw_spec, handle_bolt_depth + $eps, nut_offset=nut_offset, entry=handle_size.y/2);

      tag("remove")
      attach("foot_right", BOTTOM, spin=90, overlap=handle_bolt_depth)
        nut_insert(screw_spec, handle_bolt_depth + $eps, nut_offset=nut_offset, entry=handle_size.y/2);

      // attach("under") TODO grip features
    }

    children();
  }
}

module plate(anchor = CENTER, spin = 0, orient = UP) {
  size = [
    handle_body_size.x + 2*plate_margin.x,
    handle_body_size.y + 2*plate_margin.y,
    plate_thickness
  ];

  S = screw_info(screw_spec);
  bore_d = struct_val(S, "diameter");

  bolt_at = handle_body_size.x - handle_size.y;

  attachable(anchor, spin, orient, size=size, anchors=[
    named_anchor("left_bolt",  [-bolt_at/2, 0, -size.z/2], DOWN),
    named_anchor("right_bolt", [ bolt_at/2, 0, -size.z/2], DOWN),
  ]) {
    // TODO ribs?
    diff()
    cuboid(size, chamfer=plate_chamfer, edges="Z") {

      // bolt holes
      tag("remove")
      xcopies(spacing=bolt_at)
        cyl(d=bore_d, h=2*size.z);

      // TODO bolt head socket

      // tag("remove")
      // attach("foot_left", BOTTOM, spin=-90, overlap=10)
      //   nut_insert(screw_spec, 10 + $eps, entry=11);

      // tag("remove")
      // attach("foot_right", BOTTOM, spin=90, overlap=10)
      //   nut_insert(screw_spec, 10 + $eps, entry=11);

    }

    children();
  }
}

module nut_insert_test(anchor = CENTER, spin = 0, orient = UP) {
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
        nut_insert(screw_spec, 10 + 2*$eps, entry=11);

    children();
  }
}

module preview_cutaway(dir=BACK, at=0, r=[0, 0, 0], s=max(handle_body_size)*2.1) {
  if (cutaway && $preview) {
    difference() {
      rotate(r)
      children();
      translate(dir*(at - s/2))
        cube(s, center=true);
    }
  } else {
    children();
  }
}

// Assembly
if (mode == 0) {
  explode = 20; // TODO animate

  preview_cutaway(s=1000)
  color_this("#0000aaff")
  plate() {

    up(explode)
    attach(TOP, BOTTOM)
    color_this("#333333ff")
    cuboid([400, 200, 5])

      attach(TOP, BOTTOM, overlap=-explode)
      color_this("#00aa00ff")
      handle() {

        right(explode)
        attach("left_nut", CENTER)
          color("red") nut(screw_spec);

        left(explode)
        attach("right_nut", CENTER)
          color("red") nut(screw_spec);

      }

    screw_length = 14;
    screw_head = "socket";
    screw_drive = "hex";

    attach([ "left_bolt", "right_bolt" ], BOTTOM, overlap=screw_length)
      up(explode)
      color("red") screw(screw_spec, head=screw_head, drive=screw_drive, length=screw_length);
  }

  // TODO nuts
  // TODO bolts
}

// Handle
//@make -o handle.stl -D mode=1
else if (mode == 1) {
  preview_cutaway()
  handle(orient = $preview ? UP : DOWN);
}

// Plate
//@make -o handle_plate.stl -D mode=2
else if (mode == 2) {
  preview_cutaway()
  plate();
}

// Cross Section
else if (mode == 100) {
  stroke(handle_profile, closed=true, width=1);
}

// Outline Path
else if (mode == 101) {
  stroke(handle_outline, closed=false, width=1);
}

// Nut Insert Test
//@make -o handle_nut_test.stl -D mode=102
else if (mode == 102) {
  preview_cutaway() nut_insert_test();
}

// Nut Insert Negative
else if (mode == 103) {
  nut_insert(screw_spec, h=10, entry=5, decompose=true);
}

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

