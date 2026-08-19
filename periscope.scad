include <BOSL2/std.scad>;

/* [Part Selection] */

// Which part to model.
mode = 0; // [0:Periscope, 100:Dev]

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

/* [Arm] */

// Hex shaft size, flat-to-flat.
hex_size = 7;

// Overall arm height, from the bend's base plane up to the shaft tip.
arm_height = 80;

// L-bend centerline radius.
bend_radius = 10;

/* [Retaining Disk] */

// Retaining disk diameter.
disk_diameter = 10;

// Retaining disk thickness.
disk_thickness = 2;

// Height of the disk's underside above the bend's base plane.
disk_height = 25;

/* [Scope End] */

// Length of the hex-to-cylinder flare.
scope_taper = 30;

// Outer diameter of the flared scope cylinder.
scope_diameter = 24;

// Rounding radius of the turret's top elbow. TODO unmodelled
scope_bend_radius = 8;

/// dispatch / integration

module __customizer_limit__() {}

// Circumscribed (corner-to-corner) diameter of the hex shaft, since hex_size is
// the flat-to-flat measure.
hex_od = hex_size / cos(30);

total_arm_height = arm_height - bend_radius;

// --- 2D Profiles ---
module hex_profile() {
    circle(r = hex_od/2, $fn = 6);
}

module round_profile(d = scope_diameter) {
    circle(d = d);
}

module periscope_hex_wrench() {
    
    // 1. Long Arm (hex)
    translate([0, 0, bend_radius])   
    linear_extrude(height = total_arm_height)
    hex_profile();
    
    // 2. Disk   
    translate([0, 0, disk_height])
    linear_extrude(height = disk_thickness)
    round_profile(disk_diameter);
    

    // 2. Main L-Bend (Hex)
    translate([bend_radius, 0, bend_radius])
    rotate([90, 0, 0])
    rotate_extrude(angle = 90)
    translate([-bend_radius, 0, 0])
    hex_profile();

    // 3. Tapered Transition (Hex -> Wider Cylinder)
    translate([bend_radius, 0, 0])
    rotate([0, 90, 0])
    hull() {
        linear_extrude(height = 1) hex_profile();
        translate([0, 0, scope_taper])
        linear_extrude(height = 1) round_profile();
    }

}

//@make -o periscope.stl -D mode=0

module main() {

  // Periscope
  if (mode == 0) {
    periscope_hex_wrench();
  }

  // Dev
  else if (mode == 100) {
    dev();
  }

}

module dev() {
  %periscope_hex_wrench();
}

main();
