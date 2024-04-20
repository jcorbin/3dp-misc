// Parametric stencil type setting system

include <BOSL2/std.scad>

use <fonts/Aero Matics Stencil Regular.ttf>
use <fonts/Stencilia-A.ttf>
use <fonts/Stencilia-Bold.ttf>

/* [Glyph Tile] */

glyph = "3";

font = "Stencilia\\-A:style=Regular";

tile_size = [10, 16];

font_size = 10;

tile_thickness = 2;

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustment value for cutouts
$eps = 0.01;

/// implementation

module glyph_tile(glyph, w=1, anchor = CENTER, orient = UP, spin = 0) {
  size = v_mul(tile_size, [w, 1]);
  size1 = tile_size + [tile_thickness, 0];
  size2 = tile_size + [tile_thickness, 2*tile_thickness];
  shift = [tile_thickness, 0];
  h = tile_thickness;

  attachable(
    size=point3d(size1, h), size2=size2, h=h, shift=shift,
    anchor = anchor, orient = orient, spin = spin) {
    diff(remove="glyph")
    prismoid(size1=size1, size2=size2, h=h, shift=shift, center=true) {
      fwd(font_size*0.45)
      right(tile_thickness/2)
      position(CENTER)
      tag("glyph") text3d(glyph,
        h = tile_thickness + 2*$eps,
        font = font,
        size = font_size,
        center = true,
        atype = "baseline"
      );
    }

    children();
  }
}

module glyph_tile_row(glyphs) {
  xcopies(n=len(glyphs), spacing=tile_size.x + 3*tile_thickness)
    glyph_tile(glyphs[$idx]);
}

module glyph_tile_rows(glyphss) {
  ycopies(n=len(glyphss), spacing=tile_size.y + 3*tile_thickness)
    glyph_tile_row(glyphss[$idx]);
}

tolerance = 0.1;

module tile_frame(
  size,
  w,
  anchor = CENTER, orient = UP, spin = 0) {

  pad = [16, 16, 64];

  n = default(w, floor((size.x - pad.x*2) / tile_size.x));

  box = v_mul(tile_size, [n, 1]);
  size1 = box + [tile_thickness, 0];
  size2 = box + [tile_thickness, 2*tile_thickness];
  h = tile_thickness;

  tol = 2*tolerance;
  shift = [tile_thickness, 0];

  sz = default(size, point3d(size2 + shift, h) + pad);

  attachable(size=sz, anchor = anchor, orient = orient, spin = spin) {

    diff(remove="window tray")
    cuboid(size=sz, chamfer=tile_thickness/2, edges=[
      [0, 0, 1, 1], // yz -- +- -+ ++
      [0, 0, 1, 1], // xz
      [0, 0, 1, 1], // xy
    ]) {

      tag("window")
      translate(shift/2)
        prismoid(
          size1=box - shift,
          size2=[
            sz.x - pad.x,
            sz.y - pad.y
          ],
          // size2=box - shift + [pad.x, pad.y],
          h=sz.z+2*$eps,
          center=true
        );

      tag("tray")
        down((sz.z - h - tol)/2 + $eps)
        left(tile_thickness)
        right(pad.x)
        prismoid(
          size1=size1 + [tol + pad.x + $eps, 3*tol],
          size2=size2 + [tol + pad.x + $eps, tol],
          h=h + tol + $eps,
          shift=shift + [tol, 0], anchor=CENTER);

    }

    children();
  }
}

// right_half(s=1000)
// back_half(s=1000)
tile_frame(
  size=[200, 80, 80],
  // w=10,
  anchor=BOTTOM);

/*

// back_half(s=1000)
tile_frame(w=2, anchor=BOTTOM);

right(tile_size.x*3)
glyph_tile("1", anchor=BOTTOM);

left(tile_size.x*3)
glyph_tile("2", anchor=BOTTOM);
*/

/*

glyph_tile_rows([
  ["A", "B", "C", "D"],
  ["1", "2", "3", "4"],
  ["b", "p", "q", "g"],
]);

*/
