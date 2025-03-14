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
mode = 0; // [0:Handle, 100:Cross Section, 101:Outline Path, 102:Nut Insert Test, 103:Nut Insert Negative]

// Enables preview cutaway for some parts.
cutaway = true;

/* [Handle Body Specs] */

// Handle cross section size: X is front-to-back, Y is top-to-bottom of the span section.
handle_size = [ 34, 21 ];

// Handle cross section chamfers: top-back, top-front, bottom-front, bottom-back
handle_chamfer = [ 3, 3, 5, 5 ];

// Interior span of handle; i.e. how wide is the underside/grip.
handle_span = 100;

// Height of central handle outline; outer/inner edges are +/- half profile height.
handle_height = 30;

// Vertial lift before angular turn.
handle_lift = 15;

// Turning angle from top span to each vertical foot
handle_ang = 45;

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

module nut_insert(spec, h, entry = 0, retain = 0/* 0.4*/, tol = 0.5, decompose = false, anchor = CENTER, spin = 0, orient = UP) {
  N = nut_info(spec);
  size = struct_val(N, "diameter");
  W = struct_val(N, "width");
  T = struct_val(N, "thickness");
  D = W/cos(30);

  // TODO assert h > T

  layer = 0.2;
  hr = size + tol;

  attachable(anchor, spin, orient, size=[D, W, h]) {
    union() {
      // shaft hole
      color_if(decompose, "#00990088")
      cyl(d=hr, h=h);

      up(decompose ? 10 : 0)

      // nut holder
      color_if(decompose, "#00009988", just=true)
      cyl(d=D, h=T, $fn=6)

        // slicer fixup/trick for nut/shaft ceiling transition
        color_if(decompose, "#ff000088")
        attach(TOP, FRONT, overlap=$eps)
        prismoid(
          size1=[entry > 0 ? D : hr, layer+$eps],
          size2=[size, layer+$eps], h=W)

          attach(BACK, BOTTOM, overlap=$eps)
          cuboid([hr, W, layer+$eps])

          attach(TOP, BOTTOM, overlap=$eps)
          cuboid([hr, hr, layer+$eps]);

      // nut access
      if (entry > 0) {
        color_if(decompose, "#ff990088", just=true)
        tag_scope("hole_nut_access")
        diff() cuboid([D, max(W/2, entry), T], anchor=BACK)
          // retention bumps
          if (retain > 0) {
            rd = 2*retain + tol;
            tag("remove")
            color_if(decompose, "#ff990088")
              fwd(rd)
              xcopies(spacing=[-D/2, D/2])
              position(BACK)
              cyl(d=rd, h=T);
          }
      }

    }

    children();
  }
}

module handle(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=handle_body_size) {
    diff()
    handle_body(orient=DOWN) {

      tag("remove")
      attach("foot_left", BOTTOM, spin=-90, overlap=10)
        nut_insert("M4", 10 + $eps, entry=11);

      tag("remove")
      attach("foot_right", BOTTOM, spin=90, overlap=10)
        nut_insert("M4", 10 + $eps, entry=11);

      // attach("under") TODO grip features
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
        nut_insert("M4", 10 + 2*$eps, entry=11);

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

// Handle
//@make -o handle.stl -D mode=0
if (mode == 0) {
  handle();
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
  nut_insert("M4", h=10, entry=5, decompose=true);
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

