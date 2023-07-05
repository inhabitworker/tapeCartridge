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

Scale = 1;
TapeInnerAdj = TapeInner/2 * Scale;
TapeOuterAdj = TapeOuter/2 * Scale;
TapeDepthAdj = TapeDepth * Scale;
TapeWidthAdj = TapeOuterAdj - TapeInnerAdj;

Thickness = max(2.5, TapeDepthAdj/10);
BandWidth = TapeOuterAdj*0.75;

Ingress = TapeDepthAdj/8;
IngressSplit = 0.5;
IngressAngle = 45;

SpringThickness = min(1.25, TapeDepth/20);

OuterExtension = 2;
CoreOuter = TapeOuterAdj + Clearance + Overlap + OuterExtension;
CoreInner = TapeInnerAdj - Clearance;

Ceiling = TapeDepthAdj/2 + Clearance;
Floor = TapeDepthAdj/2 - Ingress;
Height = Ceiling + Thickness;

SpringAnchor = [
    CoreOuter,
    Ceiling + SpringThickness
];

SpringHeight = 2*(Ceiling + SpringThickness/2);
SpringLength = 6*Ingress;
SpringArcRadius = SpringAnchor.y/4;

// Hmm...
InitSpringAngle = atan((SpringLength)/(SpringHeight));
InitArcY = sin(InitSpringAngle)*SpringArcRadius;
InitArcX = cos(InitSpringAngle)*SpringArcRadius;
TravelX = SpringLength - 2*(InitArcX);
TravelY = SpringHeight - 2*(SpringArcRadius-InitArcY);

SpringAngle = atan((TravelX)/(TravelY));

ArcY = sin(SpringAngle)*SpringArcRadius;
ArcX = cos(SpringAngle)*SpringArcRadius;
BarX = SpringLength - 2*ArcX;
BarY = SpringHeight - 2*(SpringArcRadius - ArcY);
SpringBarLength = sqrt(pow(BarX, 2) + pow(BarY, 2));

SpringEnd = CoreOuter + SpringLength;
End = SpringEnd + Thickness;


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
// #Tape(Full = true, Profile = false);

module PointViz(Points) {
    for(i = [0 : 1 : len(Points)-1]) {
        translate(Points[i])
        color("green")
        circle(Scale);
    }
}
// -------------


module Band(BoundingBox = false) {

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
        polygon(Points);
    }

    module Profile_Spring() {
        module Spring_Rounding() {
            translate([0,-SpringArcRadius - SpringThickness/2])
            translate([-SpringLength/2, SpringAnchor.y]) {
                difference() {
                    // circle quadrant + overlap
                    intersection() {
                        circle(SpringArcRadius + SpringThickness/2);
                        translate([-Overlap, -Overlap])
                        square(SpringArcRadius*2);
                    }

                    // bore circle
                    circle(SpringArcRadius-SpringThickness/2);

                    rotate(SpringAngle)
                    translate([0,-SpringArcRadius*2])
                    square(SpringArcRadius*2);
                }

            }
        }

        module Spring_Bar() {
            rotate(SpringAngle)
            square([SpringThickness, SpringBarLength], center=true);
        }

        module Spring_End() {
            translate([SpringLength/2 - Overlap, - Height])
            square([Thickness, Height*2]);
        }

        translate([SpringAnchor.x + SpringLength/2 - Overlap,0]) {
            union() {
                Spring_Bar();
                Spring_Rounding();
                rotate(180)
                Spring_Rounding();
                Spring_End();
            }
        }
    }

    module Profile_Cowl() {
        CowlLength = SpringLength;
        CowlRatio = 0.3;
        CowlAngle = 60;
        Gap = CowlLength/6;
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

            translate([CowlLength/16, - SpringArcRadius + Thickness/2])
            circle(SpringArcRadius);
        }

        translate([CoreOuter + SpringLength - Overlap - UpperLength, - Height])
        difference() {
            translate([UpperLength,0])
            mirror([1,0])
            polygon(CowlPoints(UpperLength));

            translate([UpperLength-CowlLength/16, SpringArcRadius + Thickness/2])
            circle(SpringArcRadius);
        }
    }

    module Profile_Full(){
        union() {
            Profile_Core();
            Profile_Spring();
            Profile_Cowl();
        }
    }

    module Profile_Preview() {
        rotate([90,0,0])  {
            Profile_Full();
            mirror([0,1])
            Profile_Full();
        }
    }
    // #Profile_Preview();

    module HalfSwept() {
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
        Straight = TravelY;
        // Inaccurate and lazy
        z = TravelX;

        intersection() {
            translate([CoreOuter + SpringLength/2, 0, 0])
            for(i=[-1 : Freq+1]) {
                translate([0,-(2*SliceWidth)*i - Clear/2, 0])
                rotate([0,90-SpringAngle,0])

                translate([0,BandWidth/2 + d/2, 0])
                cube([Straight,d,z],center=true);
            }

            translate([0,0,-TravelY/2 + Safety/2 - sin(SpringAngle)*SpringThickness/2])
            cylinder(r=SpringEnd-Safety, h=TravelY-Safety);
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

    module HalfBand() {
        difference() {
            HalfSwept();

            #Slices();
            mirror([1,0,0])
            #Slices();

            MouthFile();
            mirror([0,1,0])
            MouthFile();
        }
    }

    HalfBand();
}

// Band();

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

module Cartridge() {
    union() {
        Band_Full();
        Base();
    }
}

Cartridge();
