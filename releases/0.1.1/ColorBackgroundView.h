//
//  ColorBackgroundView.h
//  Mental Case
//
//  Created by Drew McCormack on 30/03/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ColorBackgroundView : NSView {
    NSColor *backgroundColor;
    NSColor *borderColor;
}

- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;

- (NSColor *)borderColor;
- (void)setBorderColor:(NSColor *)newBorderColor;

@end