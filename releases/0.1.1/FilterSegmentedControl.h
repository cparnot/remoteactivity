//
//  FilterSegmentedControl.h
//  RemoteActivity
//
//  Created by Drew McCormack on 11/20/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FilterSegmentedControl : NSSegmentedControl {
    NSPredicate *appendedPredicate;
    NSMutableDictionary *predicateDict;
    id predicateTarget;
}

-(NSPredicate *)predicateForIndex:(unsigned)index;
-(void)setPredicate:(NSPredicate *)predicate forIndex:(unsigned)index;

-(id)predicateTarget;
-(void)setPredicateTarget:(id)newPredicateTarget;

-(void)updatePredicate;

-(NSPredicate *)appendedPredicate;
-(void)setAppendedPredicate:(NSPredicate *)pred;

@end
