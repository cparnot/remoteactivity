//
//  FilterSegmentedControl.m
//  RemoteActivity
//
//  Created by Drew McCormack on 11/20/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "FilterSegmentedControl.h"
#import "FilterSegmentedCell.h"


@implementation FilterSegmentedControl


+(void)initialize{
    [self setCellClass:[FilterSegmentedCell class]];
}


-(void)commonInit {
    predicateDict = [[NSMutableDictionary dictionary] retain];
    predicateTarget = nil;
    appendedPredicate = nil;
}


-(id)initWithFrame:(NSRect)frame {
    if ( self = [super initWithFrame:frame] ) [self commonInit];
    return self;
}


-(id)initWithCoder:(NSCoder *)coder {
    if ( self = [super initWithCoder:coder] ) [self commonInit];
    return self;
}


-(void)dealloc {
    [appendedPredicate release];
    [predicateDict release];
    [super dealloc];
}


-(NSPredicate *)predicateForIndex:(unsigned)index {
    return [predicateDict objectForKey:[NSNumber numberWithUnsignedInt:index]];
}


-(void)setPredicate:(NSPredicate *)predicate forIndex:(unsigned)index  {
    return [predicateDict setObject:predicate forKey:[NSNumber numberWithUnsignedInt:index]];
}


-(void)updatePredicate {
    NSPredicate *pred = [self predicateForIndex:[self selectedSegment]];
    if ( nil != pred && nil != appendedPredicate ) 
        pred = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:pred, appendedPredicate, nil]];
    if ( nil != predicateTarget && nil != pred ) [predicateTarget setFilterPredicate:pred];
}


-(id)predicateTarget {
    return predicateTarget;
}

-(void)setPredicateTarget:(id)newPredicateTarget {
    predicateTarget = newPredicateTarget;
}


-(NSPredicate *)appendedPredicate {
    return appendedPredicate;
}

-(void)setAppendedPredicate:(NSPredicate *)newAppendedPredicate {
    [newAppendedPredicate retain];
    [appendedPredicate release];
    appendedPredicate = newAppendedPredicate;
    [self updatePredicate];
}


@end
