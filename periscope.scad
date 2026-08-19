
/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

/* [Part-iculars] */

// --- Parameters ---
hex_size        = 7;     // Flat-to-flat distance (mm)
long_arm        = 80;    // Main handle length (mm)
bend_radius     = 10;    // L-bend radius (mm)
disk_thickness  = 2;     // Thickness of retaining disk
disk_r          = 5;    // Radius of retaining disk

// Periscope End Dimensions
scope_trans_len = 30;    // Length of hex-to-cylinder transition (mm)
scope_dia       = 24;    // Outer diameter of expanded cylinder (mm)
scope_height    = 25;    // Height of vertical periscope turret (mm)
scope_bend_r    = 8;     // Radius of top elbow curve (mm)

disk_to_bend = 25;

/// dispatch / integration

module __customizer_limit__() {}

total_arm_height = long_arm - bend_radius;

// Convert flat-to-flat size to outer corner radius
r_outer = (hex_size / 2) / cos(30);

// --- 2D Profiles ---
module hex_profile() {
    circle(r = r_outer, $fn = 6);
}

module round_profile(d = scope_dia) {
    circle(d = d);
}

// --- Main Assembly ---
module periscope_hex_wrench() {
    
    // 1. Long Arm (hex)
    translate([0, 0, bend_radius])   
    linear_extrude(height = total_arm_height)
    hex_profile();
    
    // 2. Disk   
    translate([0, 0, disk_to_bend])
    linear_extrude(height = disk_thickness)
    round_profile(disk_r*2);
    

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
        translate([0, 0, scope_trans_len])
        linear_extrude(height = 1) round_profile();
    }

}

periscope_hex_wrench();
