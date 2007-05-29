//
//  JobStatusValueTransformer.m
//  RemoteActivity
//
//  Created by Drew McCormack on 3/29/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "JobStatusValueTransformer.h"
#import "Job.h"


@implementation JobStatusValueTransformer


+(Class)transformedValueClass { return [NSImage self]; }
+(BOOL)allowsReverseTransformation { return NO; }


- (id)transformedValue:(id)value {
    NSImage *image = nil;
    int status = [value intValue];
    if ( status == QueuedJobStatus ) 
        image = [NSImage imageNamed:@"QueuedDot"];
    else if ( status == RunningJobStatus )
        image = [NSImage imageNamed:@"RunningDot"];
    else if ( status == FinishedJobStatus )
        image = [NSImage imageNamed:@"FinishedDot"];
    else
        image = [NSImage imageNamed:@"UnknownDot"];
    return image;
}


@end
