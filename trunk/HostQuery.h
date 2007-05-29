//
//  HostQuery.h
//  RemoteActivity
//
//  This class is used to query a host for a list of jobs.
//
//  Created by Drew McCormack on 3/1/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RealHost;
@class AccessShell;
@class HostQuery;



@interface NSObject (HostQueryDelegateMethods)
-(void)hostQueryDidFinish:(HostQuery *)hostQuery;
-(void)hostQuery:(HostQuery *)hostQuery didFailWithError:(NSError *)error;
@end


@interface HostQuery : NSObject {
    id delegate;
    NSData *outputData;
    NSData *errorData;
    NSString *queryExecutablePath;
    NSDictionary *responsePropertyList;
    NSArray *shellArguments;
    NSString *shellPath;
    RealHost *host;
}

-(id)initWithHost:(RealHost *)host
    shellPath:(NSString *)shellPath
    queryExecutablePath:(NSString *)scriptPath
    shellArguments:(NSArray *)shellArguments;
    
-(void)initiateQuery;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

-(NSString *)queryExecutablePath;
-(void)setQueryExecutablePath:(NSString *)newQueryExecutablePath;
-(NSDictionary *)responsePropertyList;
-(void)setResponsePropertyList:(NSDictionary *)newResponsePropertyList;
-(NSArray *)shellArguments;
-(void)setShellArguments:(NSArray *)newShellArguments;
-(NSString *)shellPath;
-(void)setShellPath:(NSString *)newShellPath;
-(RealHost *)host;
-(void)setHost:(RealHost *)newHost;

@end
