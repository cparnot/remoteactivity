//
//  GradientView.h
//  Mental Case
//
//  Created by Drew McCormack on 25/02/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CTGradient.h"


@interface GradientView : NSView {
    BOOL drawsBorder;
    CTGradient *gradient;
    float angle;
}

-(CTGradient *)gradient;
-(void)setGradient:(CTGradient *)gradient;

-(float)angle;
-(void)setAngle:(float)newAngle;

-(BOOL)drawsBorder;
-(void)setDrawsBorder:(BOOL)newDrawsBorder;


@end
