include <BOSL2/std.scad>;
include <BOSL2/metric_screws.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [XXX] */

// Fan body width; typically 120 or 140.
fan_width = 120;

// Fan mount screw size, typically an M4.
hole_size = 4;

// Fan mount screw hole spacing in X and Y; X is typically 105 or 125, and Y is nominally 15, but 16 provides a bit more tolerance between fan bodies
hole_spacing = [ 105, 16 ];

// Additional material width beyond hole placement.
margin = 4;

module color_if(when, name) {
  if (when) color(name) children();
  else children();
}

module hole(size, h, entry = 0, tol = 0.5, decompose = false, anchor = CENTER, spin = 0, orient = UP) {
  D = get_metric_nut_size(size);
  T = get_metric_nut_thickness(size);
  dc = D/cos(30);
  // TODO assert h > T

  layer = 0.2;
  nh = T + 2*tol;
  hr = size + tol;
  retain = tol + 0.5;

  attachable(anchor, spin, orient, size=[dc, D, h]) {
    union() {

      // bore hole
      color_if(decompose, "green")
      cyl(d=hr, h=h);

      // nut holder
      color_if(decompose, "#00009988")
      cyl(d=dc, h=nh, $fn=6);

      // nut access
      color_if(decompose, "#ff990088")
      tag_scope("hole_nut_access")
      diff() cuboid([dc, max(D/2, entry), nh], anchor=BACK)
        // retention bumps
        tag("remove")
          color_if(decompose, "#ff00ff00")
          fwd(2*retain)
          xcopies(spacing=[-dc/2, dc/2])
          position(BACK)
          cyl(d=2*retain, h=nh);

      // slicer fixup/trick for nut/bore ceiling transition
      color_if(decompose, "#ff000088")
      up(nh/2) {
        prismoid(
          size1=[hr, layer],
          size2=[dc, layer],
          h=D, orient=FRONT, anchor=CENTER+FRONT);

        up(layer)
          cuboid([hr, hr, layer], anchor=BOTTOM);
      }
    }

    children();
  }
}

module bar(tol=0.5, chamfer=0.5, anchor = CENTER, spin = 0, orient = UP) {
  length = hole_spacing.y + hole_size + 2*margin;
  size = [fan_width, length, 6];

  attachable(anchor, spin, orient, size=size) {
    diff()
    cuboid(size, chamfer=chamfer) {
      tag("remove")
      move_copies(let (
        hx = hole_spacing.x/2,
        hy = hole_spacing.y/2,
      ) [
        [-hx, -hy, 0],
        [-hx,  hy, 0],
        [ hx, -hy, 0],
        [ hx,  hy, 0],
      ]) hole(size=hole_size, h=10, entry=20, spin = 180*$idx);
    }

    children();
  }
}

// hole(size=4, h=10, entry=7, decompose=true)
bar()
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
