//
//  ColorBackgroundView.m
//  Mental Case
//
//  Created by Drew McCormack on 30/03/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "ColorBackgroundView.h"


@implementation ColorBackgroundView


-(id)initWithFrame:(NSRect)frame {
	if ( self = [super initWithFrame:frame] ) {
        float f = 237.0 / 255.0;
        NSColor *color = [NSColor colorWithDeviceRed:f green:f blue:f alpha:1.0];
		[self setBackgroundColor:color];

        float bd = 0.7;
        NSColor *bc = [NSColor colorWithDeviceRed:bd green:bd blue:bd alpha:1.0];
        [self setBorderColor:bc]; 
    }
	return self;
}


-(void)dealloc {
    [backgroundColor release];
    [super dealloc];
}


- (void)setBackgroundColor:(NSColor *)bg {
    if ([backgroundColor isEqual:bg] == NO) {
		[backgroundColor autorelease];
        backgroundColor = [bg retain];
        [self setNeedsDisplay:YES];
    }
}


- (NSColor *)backgroundColor {
    return backgroundColor;
}


- (NSColor *)borderColor {
    return [[borderColor retain] autorelease]; 
}

- (void)setBorderColor:(NSColor *)newBorderColor {
    if (borderColor != newBorderColor) {
        [newBorderColor retain];
        [borderColor release];
        borderColor = newBorderColor;
        [self setNeedsDisplay:YES];
    }
}


- (void)drawRect:(NSRect)rect {
    if (backgroundColor != nil) {
        [backgroundColor set];
        NSRectFill(rect);
        if ( borderColor != nil ) {
            [borderColor set];
            [NSBezierPath strokeRect:[self frame]];
        }
    }
    [super drawRect:rect];
}


@end

