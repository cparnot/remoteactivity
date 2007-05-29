//
//  Host.h
//  RemoteActivity
//
//  Created by Drew McCormack on 2/24/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Host : NSManagedObject <NSCopying> {

}

-(id)observedSelf;

+(void)setNotificationTriggeringKeys;

@end
