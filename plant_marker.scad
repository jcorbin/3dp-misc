// Parametric plant marker stake.

// Inspired by https://www.thingiverse.com/thing:4820275, but remade using BOSL2, not directly derived from.

include <BOSL2/std.scad>

use <fonts/Aero Matics Stencil Regular.ttf>
use <fonts/Stencilia-A.ttf>
use <fonts/Stencilia-Bold.ttf>

/* [Parameters] */

text_size = 14;

shaft_chamfer = 4;

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustement value for cutouts
$eps = 0.01;

module marker(
  label,
  thickness = 2.5,
  text_depth = 0,
  body_length = 150,
  font = "Stencilia\\-A:style=Regular",
  font_size = text_size,
  font_spacing = 1.1,
  taper = [48, 10],
  chamfer = shaft_chamfer,
  anchor=LEFT, orient=UP, spin=0) {
  // TODO would be nice to use textmetrics() someday to provide default/min body length

  shaft_width = font_size + 2*chamfer;
  shaft_size = [body_length, shaft_width, thickness];
  text_h = text_depth == 0 ? thickness : text_depth;

  attachable(
    size=shaft_size + [taper.x + taper.y/2, 0, 0],
    anchor=anchor, orient=orient, spin=spin) {
    left(taper.y/4)
    left(taper.x/2)
    diff() conv_hull("remove") {

      cuboid(shaft_size,
        chamfer=chamfer, edges=[
          [0, 0, 0, 0], // yz -- +- -+ ++
          [0, 0, 0, 0], // xz
          [1, 0, 1, 0], // xy
        ])

        position(LEFT)
        tag("remove")
        up(text_h < thickness ? thickness - text_h*3/2 : 0)
        right(chamfer)
          text3d(
            text=label,
            h=text_h + $eps + (text_h == thickness ? $eps : 0),
            font=font,
            size=font_size,
            spacing=font_spacing,
            atype="ycenter"
          );

      right(body_length/2)
      right(taper.x)
        cyl(d=taper.y, h=thickness);

    };

    children();
  }
}

ydistribute(spacing=2 + text_size + 2*shaft_chamfer) {

  marker("Basil", body_length=55);
  marker("Pepper", body_length=75);
  marker("Tomato", body_length=80);
  // TODO ... etc as needed

}
