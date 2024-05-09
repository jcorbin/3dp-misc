// Edge protector / fixer for filament rolls in something like a Bambu AMS.

include <BOSL2/std.scad>

/* [Global] */

// Enables preview cutaway.
cutaway = true;

/* [Edge Geometry] */

width = 16;

thickness = 1;

lip_thickness = 0.6;

/* [Roll Particulars] */

roll_tolerance = 0.1;

roll_od = 195;

roll_wall = 2.9;

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustment value for cutouts
$eps = 0.01;

module __customizer_limit__() {}

fit_od = roll_od + 2*roll_tolerance;
fit_h = roll_wall + 2*roll_tolerance;

wall_id = fit_od;
wall_od = wall_id + 2*thickness;
wall_h = fit_h + thickness + lip_thickness;

lip_od = wall_id;
lip_id = lip_od - 2*lip_thickness;
lip_h = lip_thickness;

face_od = wall_od;
face_id = face_od - 2*width;
face_h = thickness;

preview_cutaway() {
  tag("wall") tube(od=wall_od, id=wall_id, h=wall_h) {

    tag("face")
    position(BOTTOM)
      tube(od=face_od, id=face_id, h=face_h);

    tag("lip")
    down(lip_h/2)
    position(TOP)
      tube(od=lip_od + 2*$eps, id=lip_id, h=lip_h);

  }
}

%tag("roll") preview_cutaway() cyl(d=roll_od, h=roll_wall);

module preview_cutaway(dir=BACK, at=0, r=[0, 0, 0], s=wall_od*2.1) {
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

