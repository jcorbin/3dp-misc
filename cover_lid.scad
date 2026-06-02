$fn = 200; // Smooths out the circles

// Convert inches to mm
inch = 25.4;

// Ring Dimensions
ring_outer_d = 28.5 * inch;
ring_offset  = 0.3 * inch;
ring_inner_d = ring_outer_d - (2 * ring_offset); // Offset on both sides
ring_height  = 0.75 * inch;

// Circle (Cap) Dimensions
circle_d      = ring_outer_d + (4 * inch);
circle_height = 0.75 * inch;

color ([0.5, 0.0, 0.8]) {
// 1. The Bottom Ring
difference() {
    cylinder(h = ring_height, d = ring_outer_d, center = false);
    // Subtract the inner core to make it a ring
    translate([0, 0, -1]) // Slight overlap to ensure a clean cut
        cylinder(h = ring_height + 2, d = ring_inner_d, center = false);
}


// 2. The Top Solid Circle (Stacked on top of the ring)

translate([0, 0, ring_height])
    cylinder(h = circle_height, d = circle_d, center = false);
}
