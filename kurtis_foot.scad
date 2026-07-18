// Rounded square mounting plate with four holes and a domed center post
// OpenSCAD units are millimeters.

inch = 25.4;

// Plate
plate_width   = 2.25 * inch;
plate_depth   = 2.25 * inch;
plate_height  = 0.25 * inch;
corner_radius = 0.125 * inch;  // Slightly rounded corners

// Mounting holes
hole_diameter = 0.375 * inch;
hole_spacing  = 1.25 * inch;
edge_offset   = (plate_width - hole_spacing) / 2;

// Center post
post_diameter = 1 * inch;
post_radius   = post_diameter / 2;
post_height   = 1.50 * inch;   // Straight cylindrical section

// Spherical dome cap
dome_height = 0.25 * inch;

$fn = 128;

// Rounded rectangular prism, positioned from [0,0,0]
module rounded_plate(width, depth, height, radius) {
    hull() {
        for (x = [radius, width - radius])
            for (y = [radius, depth - radius])
                translate([x, y, 0])
                    cylinder(h = height, r = radius);
    }
}

// Dome whose flat base begins at z = 0
module spherical_dome(base_radius, cap_height) {
    sphere_radius =
        (base_radius * base_radius + cap_height * cap_height)
        / (2 * cap_height);

    sphere_center_z = cap_height - sphere_radius;

    intersection() {
        translate([0, 0, sphere_center_z])
            sphere(r = sphere_radius);

        translate([
            -base_radius - 1,
            -base_radius - 1,
            0
        ])
            cube([
                2 * base_radius + 2,
                2 * base_radius + 2,
                cap_height + 1
            ]);
    }
}

difference() {
    union() {
        // Rounded mounting plate
        rounded_plate(
            plate_width,
            plate_depth,
            plate_height,
            corner_radius
        );

        // Centered straight cylinder
        translate([
            plate_width / 2,
            plate_depth / 2,
            plate_height
        ])
            cylinder(
                h = post_height,
                d = post_diameter
            );

        // Centered spherical dome cap
        translate([
            plate_width / 2,
            plate_depth / 2,
            plate_height + post_height
        ])
            spherical_dome(post_radius, dome_height);
    }

    // Four vertical through-holes in the plate
    for (x = [edge_offset, edge_offset + hole_spacing])
        for (y = [edge_offset, edge_offset + hole_spacing])
            translate([x, y, -0.5])
                cylinder(
                    h = plate_height + 1.0,
                    d = hole_diameter
                );
}
