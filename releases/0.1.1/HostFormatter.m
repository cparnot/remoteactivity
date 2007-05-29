//
//  HostFormatter.m
//  RemoteActivity
//
//  Created by Drew McCormack on 7/18/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "HostFormatter.h"


@implementation HostFormatter 

-(NSString *)stringForObjectValue:(id)obj {
    return [obj valueForKey:@"name"];
}

@end
