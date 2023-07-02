/* [Dimensions] */
// The interior radius of the tape roll.
TapeInner =76/2;
// The full or current radius of tape.
TapeOuter = TapeInner+8;
// The depth/height of the tape roll.abs
TapeDepth = 24;

/* [Hidden] */
$fn=50;
Overlap = 0.01;

// Computed values 
    Scale = 0.5;
    Clearance = 0.3;
    LayerHeight = 0.2;

    TapeInnerAdjusted = TapeInner * Scale;
    TapeOuterAdjusted = TapeOuter * Scale;
    TapeWidth = TapeOuterAdjusted - TapeInnerAdjusted;
    TapeDepthAdjusted = TapeDepth * Scale;

    Thickness = 1.5;
    ThicknessSpring = 1.0;

    Ingress = TapeDepthAdjusted/8;
    IngressSplit = 0.5;

    Extension = 1;
    EndAngle = 15;


module Tape(Full = true) {
    difference() {
        cylinder(TapeDepthAdjusted, r= Full ? TapeOuterAdjusted : TapeInnerAdjusted + TapeRollThickness, center=true);
        cylinder(TapeDepthAdjusted + Overlap, r=TapeInnerAdjusted, center=true);
    }
}
// #Tape();

module TapeProfile() {
    translate([TapeInnerAdjusted,-TapeDepthAdjusted/2])
    square([TapeWidth, TapeDepthAdjusted]);

    translate([TapeInnerAdjusted-Ingress-Clearance, TapeDepthAdjusted/2 - Ingress])
    square(Ingress);
}
// #TapeProfile();

// Thickness per point, subdivide and taper? too much.
module DrawLineAbs(Points, Thickness, RoundEnd = false, RoundStart = false, Vertices = false) { // Rounded) {
    for( i = [0 : len(Points)-1] ) {
        if(i != len(Points)-1) {
            p1 = Points[i];
            p2 = Points[i+1]; 

            // direction
            c = atan((p2[1] - p1[1])/(p2[0] - p1[0]));
            t = abs(c);
            vX = p2[0] - p1[0]; 
            vY = p2[1] - p1[1]; 
            Angle = (vX < 0 ? (vY < 0 ? 180 + t : 180-t ) : (vY < 0 ? 360 - t : t));

            Length = sqrt(pow(p2[1] - p1[1],2)+pow(p2[0]-p1[0], 2));

            translate(p1)
            rotate(Angle)
            translate([0, -Thickness/2])
            square([Length, Thickness]);
        }

        // rounds 
        if((RoundStart == true || i != 0) && (RoundEnd == true || i != len(Points)-1)) {
            translate(Points[i])
            circle(r=Thickness/2);
        }

        // View points to test  
        if(Vertices == true) {
            translate(Points[i])
            #circle(r=Thickness/2);
        }
    }
}

module DrawLineRel(Points, Thickness, Vertices) {
    // just cum them lol.
    function CalcAbs(pts) = [for (pt = pts[0]-pts[0], i = 0; i < len(pts); pt = pt+pts[i], i = i+1) pt+pts[i]];
    PointsAbs = CalcAbs(Points);
    DrawLineAbs(PointsAbs, Thickness, Vertices);
}

// Main band computeds
BandLevel0 = TapeDepthAdjusted/2 + Thickness/2 - Ingress;
BandLevel1 = BandLevel0 + Ingress*IngressSplit;
BandLevel2 = TapeDepthAdjusted/2 + Clearance + Thickness/2;

corePts =
[
    [
        0, 
        BandLevel0
    ],
    [
        TapeInnerAdjusted - tan(45)*(Ingress*IngressSplit) - Thickness/2 - Clearance,
        BandLevel0
    ],
    [
        TapeInnerAdjusted - Clearance - Thickness/2,
        BandLevel1 
    ],
    [
        TapeInnerAdjusted - Clearance - Thickness/2,
        BandLevel2
    ],
    [
        TapeOuterAdjusted * Extension,
        BandLevel2
    ]
];

coreBound = [
    max([ for (i = corePts) i[0]]),
    max([ for (i = corePts) i[1]]),
];

nCore = corePts[len(corePts)-1];

Radius = coreBound[1]/2;

ArcX = cos(EndAngle) * Radius;
ArcY = sin(EndAngle) * Radius;
V = ArcY + coreBound[1] - Radius + Thickness/2;
H = tan(EndAngle) * V;
Travel = sqrt(pow(H, 2) + pow(V, 2));
Width = ArcX + H;

Depth = 2 * coreBound[1];
BandWidth = coreBound[0]*0.75;

Extent = coreBound[0]+Width*2;

Tip = [Extent - (sin(EndAngle)*(BandWidth/2)) + ThicknessSpring, BandWidth/2];

// 2D Profile of main structure
module BandProfile() {
    module Extender1(Anchor, Mirror = false) {
        union() {
            intersection() {
                difference() {
                    union() {
                        difference() {
                            circle(Radius);
                            circle(Radius - ThicknessSpring);
                        }

                        Diff = Thickness - ThicknessSpring;
                        translate([0, Radius-ThicknessSpring-Diff])
                        difference() {
                            square(Diff);
                            translate([+Diff,0])
                            circle(Diff);
                        }
                    }

                    translate([-Radius,0])
                    square(Radius);
                }
                rotate(EndAngle)
                square(Radius);
            }

            translate([cos(EndAngle)*Radius, sin(EndAngle)*Radius])
            rotate(EndAngle) 
            translate([-ThicknessSpring, -Travel-Overlap])
            square([ThicknessSpring, Travel+Overlap*2]);
        }
    }

    module Extender2() {
        Ratio = 0.5;
        RealBound = coreBound[1]+Thickness/2+Overlap;
        Straight = RealBound*Ratio;
        ThisRadius = RealBound*(1-Ratio) ;

        translate([coreBound[0],-Overlap])
        union() {
            translate([0, RealBound-Straight])
            square([ThicknessSpring, Straight]);

            translate([ThisRadius, +ThisRadius])
            intersection() {
                difference() {
                    circle(ThisRadius);
                    circle(ThisRadius - ThicknessSpring);
                }

                translate([-ThisRadius,-ThisRadius])
                square(ThisRadius);
            }

            Support = 2;
            translate([-ThicknessSpring*2, RealBound-Support-Thickness])
            difference() {
                square(Support);
                translate([0,0])
                circle(Support);
            }

                translate([Radius,0])
                circle(ThicknessSpring);

        }
    }

    union() {
        DrawLineAbs(corePts, Thickness);
        // Extender2();

        translate([nCore[0], coreBound[1]-Radius+Thickness/2])
        Extender1();
        translate([nCore[0] + Width*2 - cos(EndAngle)*ThicknessSpring , Radius - coreBound[1]-Thickness/2-sin(EndAngle)*ThicknessSpring])
        rotate(180)
        Extender1();

        translate([nCore[0] + Width*2 - cos(EndAngle)*ThicknessSpring/2, 0])
        square([ThicknessSpring, Depth+2*ThicknessSpring], center=true);

        // Capper 
        translate([0,BandLevel2*2 - Ingress])
        mirror([0,1,0])
        DrawLineAbs([corePts[0], [corePts[1][0]*0.5, corePts[1][1]], [corePts[2][0], corePts[2][1]], corePts[3]], Thickness);
    }

}
// BandProfile();


module Band(BoundingBox = false) {

    /*
    module DetailSlices(Length = TapeOuterAdjusted, Freq = 6) {
        Clear = 0.5;
        SliceWidth = (BandWidth / (2*Freq+1));

        intersection() {
            for(i=[1 : Freq]) {
                // Origining
                translate([0,-(2*SliceWidth)*i, 0])
                translate([Length/2-5,BandWidth/2 + SliceWidth/2,0])
                cube([Length+10, SliceWidth,Depth*2],center=true);
            }

            translate([0,0,coreBound[1]-Thickness*2])
            cylinder(Thickness*4, r2=TapeOuterAdjusted+Ingress, r1=TapeInnerAdjusted/2);
        }
    } */
    // #DetailSlices(); 

    module CoreQuad() {
        intersection() {
            union() {
                difference() {
                    rotate_extrude()
                    BandProfile();
                }
            }

            translate([Extent/2-1,0,0])
            cube([Extent+2, BandWidth, Depth*2], center=true);
        }
    }
    CoreQuad();

    module Slices() {
        // at what co ords? 
        Freq = 4;
        Clear = 0.5;
        SliceWidth = (BandWidth / (2*Freq));
        d = SliceWidth + Clear;
        l = Travel*2;
        // Inaccurate and lazy
        z = H*4;
        translate([coreBound[0] + ArcX + ThicknessSpring/2, 0,0])
        for(i=[1 : Freq]) {
            // Origining
            translate([0,-(2*SliceWidth)*i - Clear/2, 0])
            rotate([0,90-EndAngle,0])
            translate([sin(EndAngle)*ThicknessSpring,BandWidth/2+d/2,-z/4])
            cube([l,d,z],center=true);
        }
    }
    // #Slices();

    module MouthFile() {
        side = 2*Thickness;
        translate([-3,-BandWidth/2,BandLevel0-sqrt(2)*side])
        translate([0,0,+Thickness/2])
        rotate([45,0,0])
        cube([TapeOuterAdjusted,side,side]);
    }
    // #MouthFile();

    module SlicedQuad() {
        difference() {
            CoreQuad();
            MouthFile();
            mirror([0,1,0])
            MouthFile();
            Slices();
        }
    }
    // SlicedQuad();

    module Half() {
        SlicedQuad();
        rotate(180)
        SlicedQuad();
    }

    module Full() {
        union() {
            Half();
            mirror([0,0,1])
            mirror([0,1,0])
            Half();
        }
    }
    // Full();

    module BoundingBox() {
        #cube([coreBound[0]*2+Thickness, BandWidth, coreBound[1]*2 + Thickness], center=true);
    }
    if(BoundingBox) #BoundingBox();
}

module Cap() {

}

module Base() {
    translate([Extent-ThicknessSpring,0,-Depth/2 - ThicknessSpring])
    cube([ThicknessSpring,10,Depth+ThicknessSpring*2]);
}

module Stand() {
    // Yikes
    translate(Tip)
    rotate([0,0,EndAngle*2])
    translate([-ThicknessSpring,0,-Depth/2-ThicknessSpring])
    cube([ThicknessSpring*1.05,BandWidth*1.25,Depth+ThicknessSpring*2]);
}

union() {
    // Stand();
    Band();
    // Cap();
}
