// Parametric stencil type setting system

include <BOSL2/std.scad>

use <fonts/Aero Matics Stencil Regular.ttf>
use <fonts/Stencilia-A.ttf>
use <fonts/Stencilia-Bold.ttf>

mode = "test kit"; // ["test kit", "frame", "tile", "set upper", "set lower", "set punct", "set numbers"]

// What glyph to draw for mode="tile"
glyph = "X";

// Frame width tile count for mode="frame"
frame_width = 10;

/* [Frame] */

// Frame padding around the tile tray cutout.
frame_padding = [25, 25, 100];

// Fit tolerance of tiles in the frame.
tolerance = 0.1;

/* [Tile and Font Specifics] */

font = "Stencilia\\-A:style=Regular";

// Font size coutning up from baseline; needs to be smaller than tile_size.y if you need to fit baseline descenders.
font_size = 10;

// Tile size in x/y; currently it's difficul / manual to generate properly kerned varibale width tiles, since OpenSCAD textmetrics() is not yet a thing.
tile_size = [10, 16];

// Thickness of tile, and also their diagonal shift amount.
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

module glyph_tile_row(glyphs, anchor = CENTER, orient = UP, spin = 0) {
  xcopies(n=len(glyphs), spacing=tile_size.x + 3*tile_thickness)
    glyph_tile(glyphs[$idx], anchor = anchor, orient = orient, spin = spin);
}

module glyph_tile_rows(glyphss, anchor = CENTER, orient = UP, spin = 0) {
  ycopies(n=len(glyphss), spacing=tile_size.y + 3*tile_thickness)
    glyph_tile_row(glyphss[len(glyphss) - $idx - 1], anchor = anchor, orient = orient, spin = spin);
}

module tile_frame(
  size,
  w,
  pad = [16, 16, 64],
  anchor = CENTER, orient = UP, spin = 0) {

  n = default(w, floor((default(size.x, tile_size.x*2) - pad.x*2) / tile_size.x));

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

      win_size = box - shift;
      tray_h = h + tol;
      win_h = sz.z - tray_h;

      tag("window")
      attach(TOP, BOTTOM, overlap=win_h + $eps)
        prismoid(
          size1=win_size,
          size2=win_size + [pad.x, pad.y]/2,
          h=win_h + 2*$eps,
          center=true
        );

      tag("tray")
      right(tile_thickness)
      right(pad.x/2)
      attach(BOTTOM, TOP, overlap=tray_h)
        prismoid(
          size1=size1 + [2*tol + pad.x + $eps, 3*tol],
          size2=size2 + [2*tol + pad.x + $eps, 3*tol],
          h=tray_h + $eps,
          shift=shift + [tol, 0], anchor=CENTER);

    }

    children();
  }
}

if (mode == "test kit") {
  // back_half(s=1000)
  // right_half(s=1000)
  tile_frame(
    w=3,
    pad=[
      frame_padding.x/2,
      frame_padding.y/2,
      frame_padding.z/4,
    ],
    anchor=$preview ? BOTTOM : TOP,
    orient=$preview ? UP : DOWN);

  fwd(3*tile_size.y)
    glyph_tile_rows([
      ["A", "B", "C"],
      ["1", "2", "3"],
      [" "]
    ], anchor=BOTTOM);
}

else if (mode == "frame") {
  // right_half(s=1000)
  // back_half(s=1000)
  tile_frame(
    w=frame_width,
    pad=frame_padding,
    anchor=BOTTOM);
}

else if (mode == "tile") {
  glyph_tile(glyph, anchor=BOTTOM);
}

else if (mode == "set upper") {
  glyph_tile_rows([
    ["A", "B", "C", "D", "E", "F"],
    ["G", "H", "I", "J", "K", "L"],
    ["M", "N", "O", "P", "Q", "R"],
    ["S", "T", "U", "V", "W", "X"],
    ["Y", "Z", " "],
  ]);
}

else if (mode == "set lower") {
  glyph_tile_rows([
    ["a", "b", "c", "d", "e", "f"],
    ["g", "h", "i", "j", "k", "l"],
    ["m", "n", "o", "p", "q", "r"],
    ["s", "t", "u", "v", "w", "x"],
    ["y", "z", " "],
  ]);
}

else if (mode == "set punct") {
  glyph_tile_rows([
    [
      ",", ".",
      "!", "@",
      "#", "$",
      "%", "&",
      "*",
    ],

    [
      "?", "/",
      // "\\", FIXME
      "|",
      "-", "_",
      "+", "=",
      "~", "`",
    ],

    [
      ";", ":",
      "'", "\"",
      " ",
    ],

    [
      "<", ">",
      "[", "]",
      "[", "]",
      "{", "}",
      "(", ")",
    ],
  ]);
}

else if (mode == "set numbers") {
  glyph_tile_rows([
    ["1", "2", "3", "4", "5"],
    ["6", "7", "8", "9", "0"],
    ["."],
  ]);
}
