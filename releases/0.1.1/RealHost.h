//
//  RealHost.h
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Host.h"


typedef enum _MachineType {
    DesktopMachineType         = 0,
    LaptopMachineType          = 100,
    ClusterMachineType         = 200,
    SupercomputerMachineType   = 300,
    GridMachineType            = 400
} MachineType;


@interface RealHost : Host {
    
}

-(NSString *)userAndAddress;

@end
