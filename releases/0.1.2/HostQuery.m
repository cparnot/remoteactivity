//
//  HostQuery.m
//  RemoteActivity
//
//  Created by Drew McCormack on 3/1/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "HostQuery.h"
#import "GlobalFunctions.h"
#import "Errors.h"
#import "NSData-Base64Extensions.h"


//environment variable set for query scripts/executables
//in future versions, we might add more as needed
//Note: additional environment variables can be set by individual Host instances as set by the user in the GUI (implemented as the relationship 'environmentVariables' in Host)

static NSString *REMOTE_ACTIVITY_HOSTNAME   = @"REMOTE_ACTIVITY_HOSTNAME";


@interface HostQuery (Private)

-(NSString *)queryScriptString;

@end


@implementation HostQuery


-(id)initWithHost:(RealHost *)aHost
    shellPath:(NSString *)aShellPath
    queryExecutablePath:(NSString *)aQueryScriptPath
    shellArguments:(NSArray *)someShellArguments {
    
    if ( self = [super init] ) {
        [self setHost:aHost];
        [self setShellPath:aShellPath];
        [self setQueryExecutablePath:aQueryScriptPath];
        [self setShellArguments:someShellArguments];
        [self setDelegate:nil];
        outputData = nil;
        errorData = nil;
    }
    
    return self;
}


-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [queryExecutablePath release];
    [responsePropertyList release];
    [shellArguments release];
    [shellPath release];
    [host release];
    [super dealloc];
}


-(NSString *)queryScriptString {
    // Wrap query script in shell code that encodes and decodes the executable
    NSString *uniqueId = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *encodedPath = [NSString stringWithFormat:@"/tmp/remoteactivity_%@.uuen", uniqueId];
    NSString *exePath = [NSString stringWithFormat:@"/tmp/remoteactivity_%@", uniqueId];
    
    // Environment on remote host
    NSMutableString *exportCommands = [NSMutableString string];
    NSEnumerator *envEnum = [[self valueForKeyPath:@"host.environmentVariables"] objectEnumerator];
    id envVar;
    while ( envVar = [envEnum nextObject] ) {
        if ( [envVar valueForKey:@"name"] && [[envVar valueForKey:@"name"] length] > 0 ) {
            [exportCommands appendFormat:@"\nexport %@=\"%@\"", 
                [envVar valueForKey:@"name"], 
                [envVar valueForKey:@"value"]];
        }
    }
	
	//adding environment variable with the hostname, specific for Remote Activity
	[exportCommands appendFormat:@"\nexport %@=\"%@\"", REMOTE_ACTIVITY_HOSTNAME, [self valueForKeyPath:@"host.address"]];
	
    // Header
    NSString *shebang = @"#!/bin/sh";
    NSString *catCommand = [NSString stringWithFormat:@"cat - <<end_of_query_script > %@", encodedPath];
    NSString *header = [NSString stringWithFormat:@"%@\n%@\n%@\n", shebang, exportCommands, catCommand];
    
    // Trailer
    NSString *trailer = 
        @"\nend_of_query_script\n"
        @"openssl base64 -d < %@ > %@\n"
        @"chmod +x %@\n"
        @"%@\n"
        @"exitcode=$?\n"
        @"rm %@ %@\n"
        @"exit $exitcode\n";
    trailer = [NSString stringWithFormat:trailer, encodedPath, exePath, exePath, exePath, exePath, encodedPath];
    
    // Read and encode the executable, which forms the body of the message
    NSData *exeData = [NSData dataWithContentsOfFile:[self valueForKey:@"queryExecutablePath"]];
    NSString *encodedExeString = [exeData encodeBase64];
        
    // Join up parts to form the script that runs on remote machine
    NSString *queryScript = [NSString stringWithFormat:@"%@%@%@", header, encodedExeString, trailer];
    return queryScript;
}


-(void)initiateQuery {
    // Create task for query, and launch
    NSPipe *standardInput = [NSPipe pipe];
    NSPipe *standardOutput = [NSPipe pipe];
    NSPipe *standardError = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    
    // Set shell arguments
    NSMutableArray *args = [NSMutableArray array];
    NSString *hostShellArgs = [host valueForKey:@"executionShellOptions"];
    if ( nil != hostShellArgs ) {
        NSMutableArray *components = [NSMutableArray arrayWithArray:[hostShellArgs componentsSeparatedByString:@" "]];
        [components removeObject:@""]; // Remove empty strings
        [args addObjectsFromArray:components];
    }
    [args addObjectsFromArray:shellArguments];
    [task setArguments:args];
    
    // Finish task setup
    [task setLaunchPath:[self valueForKey:@"shellPath"]];
    [task setStandardInput:standardInput];
    [task setStandardOutput:standardOutput];
    [task setStandardError:standardError];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryDidFinish:) 
        name:NSTaskDidTerminateNotification object:task];
    [task launch];
    
    // Nullify data
    errorData = nil;
    outputData = nil;
    
    // Register to receive file notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputDataWasRead:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[standardOutput fileHandleForReading]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorDataWasRead:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[standardError fileHandleForReading]];
    [[standardOutput fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    [[standardError fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    
    // Write script to standard input pipe
    [[standardInput fileHandleForWriting] writeData:[[self queryScriptString] dataUsingEncoding:NSUTF8StringEncoding]];
    [[standardInput fileHandleForWriting] closeFile];
}


-(void)outputDataWasRead:(NSNotification *)notif {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notif object]];
    outputData = [[[notif userInfo] valueForKey:NSFileHandleNotificationDataItem] retain];
}


-(void)errorDataWasRead:(NSNotification *)notif {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notif object]];
    errorData = [[[notif userInfo] valueForKey:NSFileHandleNotificationDataItem] retain];
}


-(void)queryDidFinish:(NSNotification *)notif {
    NSTask *task = [notif object];
    int status = [task terminationStatus];
    BOOL failed = (status != 0);
    
    // If output has not been read, come back later
    if ( outputData == nil && !failed ) {
        [self performSelector:@selector(queryDidFinish:) withObject:notif afterDelay:0.0];
        return;
    }
    
    if ( !failed ) {
        // Strip off any extraneous output that might originate from the access shell
        NSString *outputString = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
        NSRange range = [outputString rangeOfString:@"<?xml"];
        if ( range.location == NSNotFound ) {
            failed = YES;
        }
        else {
            // Trim output and parse plist
            outputString = [outputString substringFromIndex:range.location];
            NSData *trimmedData = [outputString dataUsingEncoding:NSUTF8StringEncoding];
            NSString *errorString;
            NSDictionary *responseDict = [NSPropertyListSerialization propertyListFromData:trimmedData
                                                                          mutabilityOption:NSPropertyListImmutable 
                                                                                    format:NULL 
                                                                          errorDescription:&errorString];
            [self setResponsePropertyList:responseDict];
        }
    }
    
    // Clean up
    [[NSNotificationCenter defaultCenter] removeObserver:self 
        name:NSTaskDidTerminateNotification object:task];
    [outputData release]; outputData = nil;
    [errorData release]; errorData = nil;
    [task release]; task = nil;
    
    // Inform delegate
    if ( !failed ) {
        if ( nil != delegate &&
             [delegate respondsToSelector:@selector(hostQueryDidFinish:)] ) {
            [delegate hostQueryDidFinish:self];
        }
    }
    else {
        if ( nil != delegate &&
             [delegate respondsToSelector:@selector(hostQuery:didFailWithError:)] ) {
            NSString *hostName = [self valueForKeyPath:@"host.name"];
            NSString *desc = [NSString stringWithFormat:@"A query of host '%@' failed. This host will be taken offline to prevent further failures.", hostName];
            NSString *suggestion = @"A host query can fail if the host computer is offline, the remote shell is incorrectly configured, or the batch system is not correct. Check the host properties and online status of the machine before going online again.";
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                desc,       NSLocalizedDescriptionKey,
                suggestion, NSLocalizedRecoverySuggestionErrorKey,
                nil];
            NSError *error = [NSError errorWithDomain:RemoteActivityErrorDomain code:HostQueryFailureErrorCode userInfo:userInfo];
            [delegate hostQuery:self didFailWithError:error];
        }
    }    

}

- (id)delegate {
    return delegate; 
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}


-(NSString *)queryExecutablePath {
    return queryExecutablePath;
}

-(void)setQueryExecutablePath:(NSString *)newQueryExecutablePath {
    [newQueryExecutablePath retain];
    [queryExecutablePath release];
    queryExecutablePath = newQueryExecutablePath;
}

-(NSDictionary *)responsePropertyList {
    return responsePropertyList;
}

-(void)setResponsePropertyList:(NSDictionary *)newResponsePropertyList {
    [newResponsePropertyList retain];
    [responsePropertyList release];
    responsePropertyList = newResponsePropertyList;
}

-(NSArray *)shellArguments {
    return shellArguments;
}

-(void)setShellArguments:(NSArray *)newShellArguments {
    [newShellArguments retain];
    [shellArguments release];
    shellArguments = newShellArguments;
}

-(NSString *)shellPath {
    return shellPath;
}

-(void)setShellPath:(NSString *)newShellPath {
    [newShellPath retain];
    [shellPath release];
    shellPath = newShellPath;
}

-(RealHost *)host {
    return host;
}

-(void)setHost:(RealHost *)newHost {
    [newHost retain];
    [host release];
    host = newHost;
}


@end
