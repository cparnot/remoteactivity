//
//  Job.h
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum _JobStatus {
    NoJobStatus             = 0,
    QueuedJobStatus         = 100,
    RunningJobStatus        = 200,
    FinishedJobStatus       = 300
} JobStatus;


typedef enum _JobAction {
    NoJobAction             = 0,
    SendEmailJobAction      = 100,
    DisplayDialogJobAction  = 200
} JobAction;


@class RealHost;

@interface Job : NSManagedObject {

}

+(Job *)fetchJobWithHost:(RealHost *)host name:(NSString *)name andIdentifier:(NSNumber *)number;
+(Job *)jobWithHost:(RealHost *)host name:(NSString *)name andIdentifier:(NSNumber *)number;

-(void)setStatus:(int)status;

@end
