include <BOSL2/std.scad>;
include <BOSL2/metric_screws.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

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

module handle_body(anchor = CENTER, spin = 0, orient = UP) {
  W = handle_width + handle_size.y;
  H = handle_height + handle_size.y;
  T = handle_size.x;

  foot_xat = handle_span/2 + handle_shift;

  attachable(anchor, spin, orient, size=[W, T, H],
    anchors = [
      named_anchor("under", [0, 0, H/2 - handle_size.y], DOWN),
      named_anchor("foot_left", [-foot_xat, 0, -H/2], DOWN),
      named_anchor("foot_right", [foot_xat, 0, -H/2], DOWN),
    ]
  ) {
    xrot(90)
    intersection() {
      path_sweep(handle_profile, handle_outline);
      cuboid([ W, H, T ]);
    }

    children();
  }
}

// module nut_insert(spec, h, entry = 0, retain = 0.5, tol = 0.5, decompose = false, anchor = CENTER, spin = 0, orient = UP) {
//   N = nut_info(spec);
//   size = struct_val(N, "diameter");
//   W = struct_val(N, "width");
//   T = struct_val(N, "thickness");
//   D = W/cos(30);
//
//   // TODO assert h > T
//
//   layer = 0.2;
//   nh = T + 2*tol;
//   hr = size + tol;
//
//   attachable(anchor, spin, orient, size=[D, W, h]) {
//     union() {
//       // shaft hole
//       cyl(d=hr, h=h);
//
//       // nut holder
//       cyl(d=D, h=nh, $fn=6);
//
//       // nut access
//       tag_scope("hole_nut_access")
//       diff() cuboid([D, max(W/2, entry), nh], anchor=BACK)
//         // retention bumps
//         if (retain > 0) {
//           rd = 2*retain + tol;
//           tag("remove")
//             fwd(rd)
//             xcopies(spacing=[-D/2, D/2])
//             position(BACK)
//             cyl(d=rd, h=nh);
//         }
//
//       // slicer fixup/trick for nut/shaft ceiling transition
//       up(nh/2) {
//         prismoid(
//           size1=[hr, layer],
//           size2=[D, layer],
//           h=W, orient=FRONT, anchor=CENTER+FRONT);
//
//         up(layer)
//           cuboid([hr, hr, layer], anchor=BOTTOM);
//       }
//     }
//
//     children();
//   }
// }

// color("blue") stroke(handle_outline, closed=false, width=1);
// color("green") stroke(handle_profile, closed=true, width=1);

// nut_insert(size=4, h=10, entry=7, decompose=true)
handle_body(/*anchor=BOTTOM+LEFT+BACK*/)
{
  // position(TOP) #sphere(1);
  // %show_anchors();
  // #cube($parent_size, center=true);
}

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

// module XXX(anchor = CENTER, spin = 0, orient = UP) {
//   size = [XXX.x, XXX.z, XXX.y];
//   attachable(anchor, spin, orient, size=size) {
//     XXX();
//     children();
//   }
// }

