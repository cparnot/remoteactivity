//
//  JobCountFormatter.m
//  RemoteActivity
//
//  Created by Drew McCormack on 9/1/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "JobCountFormatter.h"


@implementation JobCountFormatter


-(NSString *)stringForObjectValue:(id)obj {
    int val = [obj intValue];
    NSString *result;
    if ( val == 0 ) {
        result = @"No jobs";
    }
    else if ( val == 1 ) {
        result = @"1 job";
    }
    else {
        result = [NSString stringWithFormat:@"%d jobs", val];
    }
    return result;
}


@end
