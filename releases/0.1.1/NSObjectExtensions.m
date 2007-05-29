//
//  NSObjectExtensions.m
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "NSObjectExtensions.h"


@implementation NSObject (NSObjectExtensions)

-(void)repeatedlyPerformSelector:(SEL)sel withObjects:(NSArray *)objects {
    NSEnumerator *en = [objects objectEnumerator];
    id obj;
    while ( obj = [en nextObject] ) [self performSelector:sel withObject:obj];
}

@end
