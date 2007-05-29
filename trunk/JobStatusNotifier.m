//
//  JobStatusNotifier.m
//  RemoteActivity
//
//  Created by Drew McCormack on 8/31/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import <Message/NSMailDelivery.h>
#import "JobStatusNotifier.h"
#import "Job.h"
#import "RealHost.h"


@interface JobStatusNotifier (Private)

-(void)displayDialogForCompletingJobs:(NSSet *)completingJobs initiatingJobs:(NSSet *)initiatingJobs;
-(void)sendEmailForCompletingJobs:(NSSet *)completingJobs initiatingJobs:(NSSet *)initiatingJobs;

-(void)messageText:(NSString **)message andInformativeText:(NSString **)informativeText forCompletingJobs:(NSSet *)completingJobs 
    initiatingJobs:(NSSet *)initiatingJobs;
-(NSString *)identifiersStringForJobs:(NSSet *)jobs;

-(NSSet *)filterJobs:(NSSet *)jobs withNotificationAction:(unsigned)action;

@end


@implementation JobStatusNotifier


-(id)initWithCompletingJobs:(NSSet *)theCompletingJobs initiatingJobs:(NSSet *)theInitiatingJobs onHost:(RealHost *)theHost {
    if ( self = [super init] ) {
        completingJobs = [theCompletingJobs retain];
        initiatingJobs = [theInitiatingJobs retain];
        host = [theHost retain];
    }
    return self;
}


-(void)dealloc {
    [completingJobs release];
    [initiatingJobs release];
    [host release];
    [super dealloc];
}


-(NSString *)identifiersStringForJobs:(NSSet *)jobs {
    if ( [jobs count] == 0 ) return @"";
    NSEnumerator *en = [jobs objectEnumerator];
    NSMutableString *string = [NSMutableString stringWithFormat:@"%d", [[[en nextObject] valueForKey:@"identifier"] intValue]];
    Job *job;
    while ( job = [en nextObject] ) {
        [string appendString:[NSString stringWithFormat:@", %d", [[job valueForKey:@"identifier"] intValue]]];
    }
    return string;
}


-(NSSet *)filterJobs:(NSSet *)jobs withActionKey:(NSString *)actionKey actionValue:(unsigned)action {
    NSMutableSet *filteredJobs = [NSMutableSet set];
    NSEnumerator *en = [jobs objectEnumerator];
    Job *job;
    while ( job = [en nextObject] ) {
        if ( [[job valueForKey:actionKey] unsignedIntValue] == action ) [filteredJobs addObject:job];
    }
    return filteredJobs;
}


-(void)notifyUserOfChanges {
    [self displayDialogForCompletingJobs:[self filterJobs:completingJobs withActionKey:@"completionAction" actionValue:DisplayDialogJobAction]
                          initiatingJobs:[self filterJobs:initiatingJobs withActionKey:@"initiationAction" actionValue:DisplayDialogJobAction]];
    [self sendEmailForCompletingJobs:[self filterJobs:completingJobs withActionKey:@"completionAction" actionValue:SendEmailJobAction]
                          initiatingJobs:[self filterJobs:initiatingJobs withActionKey:@"initiationAction" actionValue:SendEmailJobAction]];
}


-(void)displayDialogForCompletingJobs:(NSSet *)theCompletingJobs initiatingJobs:(NSSet *)theInitiatingJobs {
    NSString *message, *informativeText;
    [self messageText:&message andInformativeText:&informativeText forCompletingJobs:theCompletingJobs initiatingJobs:theInitiatingJobs];
    if ( message ) {
        NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:@"OK"
                                       alternateButton:nil 
                                           otherButton:nil 
                             informativeTextWithFormat:informativeText];
        [alert runModal];
    }
}


-(void)sendEmailForCompletingJobs:(NSSet *)theCompletingJobs initiatingJobs:(NSSet *)theInitiatingJobs {
    NSString *message, *informativeText;
    NSString *emailAddress = [[NSUserDefaults standardUserDefaults] valueForKey:@"NotificationEmailAddress"];
    [self messageText:&message andInformativeText:&informativeText forCompletingJobs:theCompletingJobs initiatingJobs:theInitiatingJobs];
    if ( message && emailAddress ) {
        [NSMailDelivery deliverMessage:[NSString stringWithFormat:@"%@\n\n%@", message, informativeText] 
            subject:@"[Remote Activity] A job or jobs have changed status" 
            to:emailAddress]; 
    }
}


-(void)messageText:(NSString **)message andInformativeText:(NSString **)informativeText forCompletingJobs:(NSSet *)theCompletingJobs 
    initiatingJobs:(NSSet *)theInitiatingJobs {
    *message = nil;
    *informativeText = nil;
    unsigned numCompleting = [theCompletingJobs count];
    unsigned numInitiating = [theInitiatingJobs count];
    if ( numCompleting == 0 && numInitiating > 0 ) {
        *message = [NSString stringWithFormat:@"A job or jobs have begun running on host '%@'.", [host valueForKey:@"name"]];
        *informativeText = [NSString stringWithFormat:@"Identifiers for the jobs that have started running are: %@.", 
            [self identifiersStringForJobs:theInitiatingJobs]];
    }
    else if ( numCompleting > 0 && numInitiating == 0 ) {
        *message = [NSString stringWithFormat:@"A job or jobs have finished running on host '%@'.", [host valueForKey:@"name"]];
        *informativeText = [NSString stringWithFormat:@"Identifiers for the jobs that have finished running are: %@.", 
            [self identifiersStringForJobs:theCompletingJobs]];
    }
    else if ( numCompleting > 0 && numInitiating > 0 ) {
        *message = [NSString stringWithFormat:@"A job or jobs have finished and started running on host '%@'.", [host valueForKey:@"name"]];
        *informativeText = [NSString stringWithFormat:@"Identifiers for the jobs that have finished running are: %@. \nIdentifiers for the jobs that have started running are: %@.", 
            [self identifiersStringForJobs:theCompletingJobs], 
            [self identifiersStringForJobs:theInitiatingJobs]];
    }
}


@end
