//
//  EnvironmentVariable.h
//  RemoteActivity
//
//  Created by Drew McCormack on 9/1/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EnvironmentVariable : NSManagedObject {

}

+(id)environmentVariableWithName:(NSString *)name andValue:(NSString *)value;

@end
