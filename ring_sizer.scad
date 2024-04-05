// Parametric finger size gauge (measuring ring).

// Remixed from <https://www.thingiverse.com/thing:2463427>
// Copyright (C) 2017 Miroslav Hradílek
// Copyright (C) 2024 Joshua T Corbin

// This program is  free software:  you can redistribute it and/or modify it
// under  the terms  of the  GNU General Public License  as published by the
// Free Software Foundation, version 3 of the License.
//
// This program  is  distributed  in the hope  that it will  be useful,  but
// WITHOUT  ANY WARRANTY;  without  even the implied  warranty of MERCHANTA-
// BILITY  or  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
// License for more details.
//
// You should have received a copy of the  GNU General Public License  along
// with this program. If not, see <http://www.gnu.org/licenses/>.

include <BOSL2/std.scad>

//@make -o ring_sizer/us_3.stl -p ring_sizer.json -P us_3
//@make -o ring_sizer/us_3_5.stl -p ring_sizer.json -P us_3_5
//@make -o ring_sizer/us_4.stl -p ring_sizer.json -P us_4
//@make -o ring_sizer/us_4_5.stl -p ring_sizer.json -P us_4_5
//@make -o ring_sizer/us_5.stl -p ring_sizer.json -P us_5
//@make -o ring_sizer/us_5_5.stl -p ring_sizer.json -P us_5_5
//@make -o ring_sizer/us_6.stl -p ring_sizer.json -P us_6
//@make -o ring_sizer/us_6_5.stl -p ring_sizer.json -P us_6_5
//@make -o ring_sizer/us_7.stl -p ring_sizer.json -P us_7
//@make -o ring_sizer/us_7_5.stl -p ring_sizer.json -P us_7_5
//@make -o ring_sizer/us_8.stl -p ring_sizer.json -P us_8
//@make -o ring_sizer/us_8_5.stl -p ring_sizer.json -P us_8_5
//@make -o ring_sizer/us_9.stl -p ring_sizer.json -P us_9
//@make -o ring_sizer/us_9_5.stl -p ring_sizer.json -P us_9_5
//@make -o ring_sizer/us_10.stl -p ring_sizer.json -P us_10
//@make -o ring_sizer/us_10_5.stl -p ring_sizer.json -P us_10_5
//@make -o ring_sizer/us_11.stl -p ring_sizer.json -P us_11
//@make -o ring_sizer/us_11_5.stl -p ring_sizer.json -P us_11_5
//@make -o ring_sizer/us_12.stl -p ring_sizer.json -P us_12
//@make -o ring_sizer/us_12_5.stl -p ring_sizer.json -P us_12_5
//@make -o ring_sizer/us_13.stl -p ring_sizer.json -P us_13
//@make -o ring_sizer/us_13_5.stl -p ring_sizer.json -P us_13_5

/* [Ring Size] */

ring_id = 14;
label = "?";
label_text_size = 4;

/* [Body Parameters] */

wall_width = 3;
thickness = 5;
ring_chamfer = 1;
hole_d = 5;

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustement value for cutouts
$eps = 0.01;

base_od = ring_id + 2 * wall_width;

tab_thickness = thickness * 0.6;
tab_chamfer = thickness * 0.15;

module base() {   
  hull() {
    circle(d=base_od);
    right(base_od) circle(d=base_od/2);
  }
}

module hole(d, h, chamfer=0) {
  if (chamfer > 0) {
    attachable(d = d, h = h) {
      cyl(h = h - 2*chamfer + 2*$eps, d = d, center = true) {
        attach(BOTTOM, TOP, overlap=$eps)
          cyl(h = chamfer + $eps, d1 = d + 2*chamfer, d2 = d, center = true);
        attach(TOP, BOTTOM, overlap=$eps)
          cyl(h = chamfer + $eps, d1 = d, d2 = d + 2*chamfer, center = true);
      }

      children();
    }
  }

  else {
    cyl(h = h, d = d, center = true) children();
  }
}

module body() {
  union() {
    linear_extrude(height = tab_thickness) base();
    up(thickness/2)
      cyl(d = base_od, h = thickness, chamfer2 = ring_chamfer);
  }
}

module part() {
  difference() {
    body();

    up(thickness/2)
      hole(h=thickness + 2*$eps, d=ring_id, chamfer=ring_chamfer);

    up(tab_thickness/2)
    right(base_od)
      hole(h = tab_thickness + 2*$eps, d = hole_d, chamfer = tab_chamfer);

    right(base_od*0.675)
    up(thickness*0.4)
    zrot(90)
    linear_extrude(height = thickness*0.2 + $eps)
      text(font=":style=Bold", size=label_text_size, halign="center", valign="center", label);
  }
}

part();
