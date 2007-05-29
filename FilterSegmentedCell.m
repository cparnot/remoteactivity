//
//  FilterSegmentedControlCell.m
//  RemoteActivity
//
//  Created by Drew McCormack on 11/20/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "FilterSegmentedCell.h"
#import "FilterSegmentedControl.h"


@implementation FilterSegmentedCell


-(void)setSelectedSegment:(int)index {
    [super setSelectedSegment:index];
    [(id)[self controlView] updatePredicate];
}


//-(void)drawSegment:(int)segment inFrame:(NSRect)frame withView:(NSView *)controlView {
//}


@end
