//
//  ViewCell.m
//  RemoteActivity
//
//  Created by Drew McCormack on 7/25/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "ViewCell.h"


@implementation ViewCell


-(void)setObjectValue:(id <NSCopying>)object {
    view = (id)object;
}


-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if( [view superview] != controlView ) {
        [controlView addSubview:view];
    }
    NSSize viewSize = [view frame].size;
    float dx = 0.5f * (cellFrame.size.width - viewSize.width);
    float dy = 0.5f * (cellFrame.size.height - viewSize.height);
    NSRect viewFrame = NSInsetRect(cellFrame, dx, dy);
    [view setFrame:viewFrame];
}


@end
