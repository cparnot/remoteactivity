//
//  GradientView.m
//  Mental Case
//
//  Created by Drew McCormack on 25/02/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "GradientView.h"
#import "DrawingFunctions.h"
#import "CTGradient.h"


@interface GradientView (Private)
- (CTGradient *)gradient;
- (void)setGradient:(CTGradient *)newGradient;
@end


@implementation GradientView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setGradient:[CTGradient unifiedNormalGradient]];
        [self setAngle:90.0];
        [self setDrawsBorder:YES];
    }
    return self;
}

-(void)dealloc {
    [gradient release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect {
    if ( drawsBorder ) {
        NSDrawGroove([self bounds], [self bounds]);
        [gradient fillRect:NSInsetRect([self bounds],2,2) angle:angle];
    }
    else {
        [gradient fillRect:[self bounds] angle:angle];
    }
}

- (float)angle {
    return angle;
}

- (void)setAngle:(float)newAngle {
    angle = newAngle;
}


- (CTGradient *)gradient {
    return gradient; 
}

- (void)setGradient:(CTGradient *)newGradient {
    if (gradient != newGradient) {
        [gradient release];
        gradient = [newGradient retain];
    }
}

-(BOOL)drawsBorder {
    return drawsBorder;
}

-(void)setDrawsBorder:(BOOL)newDrawsBorder {
    drawsBorder = newDrawsBorder;
}


@end
