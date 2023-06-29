/* [Dimensions] */
// The interior radius of the tape roll.
TapeInner = 41;
// The full or current radius of tape.
TapeOuter = 140;
// The depth/height of the tape roll.abs
TapeDepth = 50;


/* [Hidden] */
// Scaling for quick prototype/demo
Scale = 0.5;
Clearance = 0.3;
LayerHeight = 0.2;

TapeInner = TapeInner * Scale;
TapeOuter = TapeOuter * Scale;
TapeDepth = TapeDepth * Scale;

SpringThickness = 1.75;
SpringDepth = 2*SpringThickness; //TapeDepth/25;

WallThickness = 3;

CartDepth = TapeDepth + SpringDepth + 4;
CartWidth = TapeOuter*2 + 12;



