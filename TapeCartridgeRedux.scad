/* [Dimensions] */
// The interior diameter of the tape roll.
TapeInner = 77;
// The full or current diameter of the tape roll.
TapeOuter= 95;
// The depth of the tape roll.
TapeDepth = 25.2;

/* [Hidden] */
$fn=40;
Overlap = 0.01;
Clearance = 0.4;
LayerHeight = 0.2;

    Scale = 0.5;

    TapeInnerAdj = TapeInner/2 * Scale;
    TapeOuterAdj = TapeOuter/2 * Scale;

    TapeDepthAdj = TapeDepth * Scale;
    TapeWidthAdj = TapeOuterAdj - TapeInnerAdj;

    Thickness = TapeDepthAdj/10;
    BandWidth = TapeOuterAdj*0.75;

    Ingress = TapeDepthAdj/8;
    IngressSplit = 0.5;
    IngressAngle = 45;

    SpringThickness = TapeDepth/20;


// Tool -------------
module Tape(Full = true, Profile = false) {
    intersection() {
        difference() {
            cylinder(TapeDepthAdj, r = Full ? TapeOuterAdj : TapeInnerAdj + TapeWidthAdj/8, center=true);
            cylinder(TapeDepthAdj + Overlap, r=TapeInnerAdj, center=true);
        }

        Bound = (TapeOuterAdj + Overlap)*2;
        cube([Bound, Profile ? 1 : Bound, TapeDepthAdj + Overlap], center=true);
    }

    color("blue")
    rotate([90,0,0])
    translate([TapeInnerAdj-Clearance-Ingress, TapeDepthAdj/2 - Ingress])
    #square(Ingress);
}
// #Tape(Full = true, Profile = true);

module PointViz(Points) {
    for(i = [0 : 1 : len(Points)-1]) {
        translate(Points[i])
        color("green")
        circle(Scale);
    }
}
// -------------


CoreOuter = TapeOuterAdj + Clearance + Overlap;
CoreInner = TapeInnerAdj - Clearance;

Ceiling = TapeDepthAdj/2 + Clearance;
Floor = TapeDepthAdj/2 - Ingress;
Height = Ceiling + Thickness;

    // This is what arcX (travelX?) must be roughly patter to.
    // as we squash the button, it becomes near horizontal at which point release state sohuld be achieve.
    Travel = 2*Ingress; 

    // While it would be nice to have the spring travel based on our entire arc, printing needs bridges, so necessarily we need a straight component that encompasses our travel.
    SpringHeight = Ceiling + SpringThickness;
    Radius = SpringHeight-SpringThickness/2; 
    Angle = asin(Travel/Radius);

    ArcY = sin(Angle)*Radius;
    TravelX = tan(Angle)*ArcY;
    ArcX = cos(Angle)*Radius;
    TravelY = tan(Angle)*ArcX;

    echo("The dist:", sin(Angle)*(Thickness/2));

    SpringHalfWidth = Radius + TravelX - (Radius - ArcX);
    SpringEnd = CoreOuter + SpringHalfWidth*2;
    End = SpringEnd + Thickness;


module Band(BoundingBox = false) {
    // Add curved supports... later?
    module Profile_Core() {
        Points = [
            [0, Height],
            [0, Floor],
            [CoreInner - Ingress/2 , Floor],
            [CoreInner, Floor + Ingress/2],
            [CoreInner, Ceiling],
            [CoreOuter, Ceiling],
            [CoreOuter, Height]
        ];

        // PointViz(Points);
        polygon(Points);
    }

    module Profile_Spring() {

        module Spring_Half() {
            translate([-SpringHalfWidth, 0]) {
                difference() {
                    // circle quadrant + overlap
                    intersection() {
                        circle(Radius + SpringThickness/2);
                        translate([-Overlap,-Overlap])
                        square(Radius*2);
                    }
                    // bore circle
                    circle(Radius-SpringThickness/2);

                    rotate(Angle)
                    translate([0,-Radius*2])
                    square(Radius*2);
                }
            }
        }

        module Spring_Bar() {
            rotate(Angle)
            square([SpringThickness, sqrt(pow(2*TravelX,2)+pow(2*ArcY,2))+2*Overlap], center=true);
        }

        module Spring_End() {
            translate([SpringHalfWidth - Overlap, - Height])
            square([Thickness, Height*2]);
        }

        translate([CoreOuter + SpringHalfWidth - Overlap,0])
        union() {
            Spring_Half();
            rotate(180)
            Spring_Half();
            Spring_Bar();
            Spring_End();
        }
    }

    module Profile_Cowl() {
        CowlLength = 2*SpringHalfWidth;
        CowlRatio = 0.3;
        CowlAngle = 65;
        Gap = CowlLength/8;
        UpperLength = CowlLength*CowlRatio - Gap;
        LowerLength = CowlLength*(1-CowlRatio) - Gap;

        function CowlPoints(Length) = [
            [0,0],
            [Length, 0],
            [Length + tan(CowlAngle)*Thickness, Thickness],
            [0,Thickness]
        ];

        translate([CoreOuter, Height - Thickness])
        difference() {
            polygon(CowlPoints(LowerLength));

            translate([CowlLength/16, -Radius + Thickness/2])
            circle(Radius);
        }

        translate([CoreOuter + 2*SpringHalfWidth - Overlap - UpperLength, - Height])
        difference() {
            translate([UpperLength,0])
            mirror([1,0])
            polygon(CowlPoints(UpperLength));

            translate([UpperLength-CowlLength/16, Radius + Thickness/2])
            circle(Radius);
        }
    }

    module Profile_Full(){
        // rotate([90,0,0])
        union() {
            Profile_Core();
            Profile_Spring();
            Profile_Cowl();
        }
    }

    module HalfSwept() {
        // Intersection seems to make more visual error that is annoying.
            // It's bad either way.
        difference() {
            rotate_extrude()
            Profile_Full();

            translate([-End, BandWidth/2,-Height*2]) 
            cube([End*2, SpringEnd, Height*4]);

            translate([-End, - BandWidth/2 - SpringEnd, -Height*2]) 
            cube([End*2, SpringEnd, Height*4]);
        }
    }

    module Slices() {
        Freq = 4;
        Clear = 0.5;
        SliceWidth = (BandWidth / (2*Freq));
        d = SliceWidth + Clear;
        Safety = SpringThickness/2;
        Straight = TravelY*4;
        // Inaccurate and lazy
        z = 2*TravelX;

        intersection() {
            translate([CoreOuter + SpringHalfWidth, 0, 0])
            for(i=[1 : Freq]) {
                translate([0,-(2*SliceWidth)*i - Clear/2, 0])
                rotate([0,90-Angle,0])

                translate([0,BandWidth/2 + d/2, 0])
                cube([Straight,d,z],center=true);
            }

            translate([0,0,-TravelY + Safety/2 - sin(Angle)*SpringThickness/2])
            cylinder(r=End, h=TravelY*2-Safety);

        }
    }

    module MouthFile() {
        MouthAngle = -25;
        Side = Ceiling-Floor;
        // translate([-3, -BandWidth/2, Ceiling])
        translate([0,-BandWidth/2,Ceiling])

        rotate([MouthAngle,0,0])
        translate([-CoreInner,0,-Side])
        cube([2*CoreInner, BandWidth/2, Side]);
    }

    difference() {
        HalfSwept();

        // Spring Slices
        Slices();
        mirror([1,0,0])
        Slices();

        MouthFile();
        mirror([0,1,0])
        MouthFile();
    }

}

module Band_Full(Hole = false) {
    difference() {
        union() {
            Band();
            rotate(180)
            mirror([0,0,1])
            Band();
        }

        if(Hole) {
            cube([CoreInner*2, BandWidth/2, Height*4], center=true);

            translate([CoreInner,0,-Height*2])
            cylinder(r=BandWidth/4, h = Height*4 );

            translate([-CoreInner,0,-Height*2])
            cylinder(r=BandWidth/4, h = Height*4 );
        }
    }
}

module Base() {
    translate([End-Thickness, -BandWidth/2,-Height])
    cube([Thickness , BandWidth, Height*2]);
}

union() {
    Band_Full();
    Base();
}
