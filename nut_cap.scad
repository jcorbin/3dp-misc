include <BOSL2/std.scad>

od = 18;

h = 6;

nut_od = 8;

nut_h = 2.9;

nut_tol = 0.2;

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustment value for cutouts
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

function scalar_vec2(v, dflt) =
  is_undef(v)? undef :
  is_list(v)? [for (i=[0:1]) default(v[i], default(dflt, 0))] :
  !is_undef(dflt)? [v,dflt] : [v,v];

module dome(
  d, h, exh = 0,
  style = "algined",
  anchor = CENTER, spin = 0, orient = UP) {
  r = d/2;

  // x^2 + y^2 + z^2 = sr^2
  // sr = h + g

  // x^2 + y^2 = r^2 { when z=g }
  // r^2 + g^2 = (h + g)^2
  // g^2 + r^2 = h^2 + 2*h*g + g^2
  // r^2 - h^2 = 2*h*g
  // (r^2 - h^2)/(2*h) = g
  g = (r^2 - h^2)/(2*h);
  sr = h + g;

  attachable(anchor, spin, orient, r=r, h=h) {
    down(h/2)
    top_half()
    down(g)
      spheroid(r=sr, style=style);

    children();
  }
}

diff() dome(od, h, style="icosa") {
  nd = nut_od + 2*nut_tol;
  nh = nut_h + nut_tol;

  attach(BOTTOM, TOP, overlap=nh)
  tag("remove") cyl(d=nd, h=nh + $eps, $fn=6);
}
