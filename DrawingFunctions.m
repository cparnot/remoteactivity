//
//  DrawingFunctions.m
//  Mental Case
//
//  Created by Drew McCormack on 25/02/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "DrawingFunctions.h"


void DrawReflectiveSurfaceInRect( NSRect bounds, NSColor *backgroundColor, NSColor *foregroundColor ) {
    DrawGradientInRect(bounds, backgroundColor, foregroundColor);

    // Add reflection
    float height = NSHeight(bounds);
    unsigned int row;
    for (row = height; row > height / 2; row--) {
        [[NSColor colorWithDeviceWhite:1.0 alpha:((height - row) / (height * 1.2))] set];
        NSRectFillUsingOperation(NSMakeRect(0, row, NSWidth(bounds), 1), NSCompositeSourceOver);
    }
}


void DrawGradientInRect( NSRect bounds, NSColor *backgroundColor, NSColor *foregroundColor ) {
    [backgroundColor set];
    NSRectFill(bounds);
    
    float height = NSHeight(bounds);
    unsigned int row;
    for (row = 0; row < height; row++) {
        [[foregroundColor colorWithAlphaComponent:((float)row / height)] set];
        NSRectFillUsingOperation(NSMakeRect(0, row, NSWidth(bounds), 1), NSCompositeSourceOver);
    }
}

