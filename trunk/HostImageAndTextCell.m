//
//  HostImageAndTextCell.m
//  Mental Case
//
//  Created by Drew McCormack on 25/03/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "HostImageAndTextCell.h"
#import "HostFormatter.h"
#import "RealHost.h"


@implementation HostImageAndTextCell


-(id)init {
    if ( self = [super init] ) {
        [self setFormatter:[[[HostFormatter alloc] init] autorelease]];
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)coder {
    if ( self = [super initWithCoder:coder] ) {
        [self setFormatter:[[[HostFormatter alloc] init] autorelease]];
    }
    return self;
}


- (void)setObjectValue:(NSObject <NSCopying> *)object {
    [self setImage:[NSImage imageNamed:@"WorkgroupCluster"]];
    [super setObjectValue:object];
}


@end
