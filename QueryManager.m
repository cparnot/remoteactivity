//
//  QueryManager.m
//  RemoteActivity
//
//  Created by Drew McCormack on 3/3/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "QueryManager.h"
#import "RealHost.h"
#import "AccessShell.h"
#import "HostQuery.h"
#import "Job.h"
#import "CoreDataUtilities.h"
#import "GlobalFunctions.h"
#import "NSObjectExtensions.h"
#import "MainController.h"
#import "JobStatusNotifier.h"


// Keys for job property lists returned by HostQuery
NSString *JobDescriptionsKey   = @"JobDescriptionsKey";
NSString *JobIdentifierKey     = @"JobIdentifierKey";
NSString *JobStatusKey         = @"JobStatusKey";
NSString *JobNameKey           = @"JobNameKey";
NSString *JobSubmissionDateKey = @"JobSubmissionDateKey";


@interface QueryManager (Private)
-(void)startQueryTimer;
-(void)stopQueryTimer;
-(void)setIsQuerying:(BOOL)flag;
-(void)performScheduledHostQuery:(NSTimer *)timer;
-(void)removeOldJobs;
-(void)disableUndoRegistration;
-(void)enableUndoRegistration;
@end


@interface QueryManager (HostQueryDelegateMethods)
-(void)hostQueryDidFinish:(HostQuery *)hostQuery;
@end


@implementation QueryManager


+(id)sharedQueryManager {
    static QueryManager *sharedQueryManager = nil;
    if ( nil == sharedQueryManager ) sharedQueryManager = [QueryManager new];
    return sharedQueryManager;
}


-(id)init {
    if ( self = [super init] ) {
        [self setIsQuerying:NO];
        hostQueries = [[NSMutableSet alloc] initWithCapacity:10];
        queryTimer = nil;
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.SecondsBetweenRefreshes" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}


- (void)dealloc {
    [hostQueries release];
    [queryTimer invalidate];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.SecondsBetweenRefreshes"];
    [super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ( [keyPath isEqual:@"values.SecondsBetweenRefreshes"] ) {
        [self stopQueryTimer];
        [self startQueryTimer];
    }
}


-(void)startQuerying {
    if ( ![self isQuerying] ) [self startQueryTimer];
    [self setIsQuerying:YES];
}


-(void)stopQuerying {
    if ( [self isQuerying] ) [self stopQueryTimer];
    [self setIsQuerying:NO];
}


-(void)startQueryTimer {
    NSTimeInterval timeInterval = [[[NSUserDefaults standardUserDefaults] valueForKey:@"SecondsBetweenRefreshes"] intValue]; 
    queryTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self 
        selector:@selector(performScheduledHostQuery:)
        userInfo:nil repeats:YES];
    NSAssert( nil != queryTimer, @"Timer was nil in startQueryTimer" );
    [queryTimer fire];
}


-(void)stopQueryTimer {
    [queryTimer invalidate];
}


-(void)hostQueryDidFinish:(HostQuery *)hostQuery {
    [self disableUndoRegistration];
    
    // Create jobs and update the managed object context
    NSDate *now = [NSCalendarDate date];
    NSArray *retrievedJobsDicts = [[hostQuery valueForKey:@"responsePropertyList"] objectForKey:JobDescriptionsKey];
    NSEnumerator *jobEnum = [retrievedJobsDicts objectEnumerator];
    NSDictionary *jobDict = nil;
    NSMutableSet *retrievedJobsSet = [NSMutableSet setWithCapacity:[retrievedJobsDicts count]];
    NSMutableSet *completingJobsSet = [NSMutableSet set];
    NSMutableSet *initiatingJobsSet = [NSMutableSet set];
    while ( jobDict = [jobEnum nextObject] ) {
        NSNumber *identifier = [jobDict objectForKey:JobIdentifierKey];
        NSString *name = [jobDict objectForKey:JobNameKey];
        NSDate *submissionDate = [jobDict objectForKey:JobSubmissionDateKey];
        NSNumber *status = [jobDict objectForKey:JobStatusKey];

        // Search for existing job, and if not found, create a new one
        Job *job = [Job fetchJobWithHost:[hostQuery valueForKey:@"host"] name:name andIdentifier:identifier];
        if ( nil == job ) {  // New job
            job = [Job jobWithHost:[hostQuery valueForKey:@"host"] name:name andIdentifier:identifier];
            if ( nil != submissionDate ) 
                [job setValue:submissionDate forKey:@"submissionDate"];
            else
                [job setValue:[job valueForKey:@"firstObservedDate"] forKey:@"submissionDate"];
        }
        
        // Update job status, and determine if the job just finished, or just started running
        NSNumber *statusBeforeQuery = [job valueForKey:@"status"];
        if ( ![statusBeforeQuery isEqual:status] && FinishedJobStatus == [status intValue] ) {
            [job setValue:now forKey:@"completionDate"];  // Job finished
            [completingJobsSet addObject:job];
        }        
        else if ( ![statusBeforeQuery isEqual:status] && RunningJobStatus == [status intValue] ) {
            [initiatingJobsSet addObject:job];
        }
        [job setValue:status forKey:@"status"];
        
        [retrievedJobsSet addObject:job];
    }
    
    // Change status of jobs on this host that were not retrieved, and have thus finished.
    NSMutableSet *unretrievedJobsSet = [[[[hostQuery valueForKey:@"host"] valueForKey:@"jobs"] mutableCopy] autorelease]; // all jobs
    [unretrievedJobsSet minusSet:retrievedJobsSet];
    jobEnum = [unretrievedJobsSet objectEnumerator];
    Job *job;
    NSNumber *statusNum = [NSNumber numberWithInt:FinishedJobStatus];
    while ( job = [jobEnum nextObject] ) {
        if ( [[job valueForKey:@"status"] intValue] != FinishedJobStatus ) {
            [completingJobsSet addObject:job];
            [job setValue:now forKey:@"completionDate"];  
            [job setValue:statusNum forKey:@"status"];
        }
    }
    
    // Stop refreshing host
    RealHost *host = [hostQuery valueForKey:@"host"];
    [host setValue:[NSNumber numberWithBool:NO] forKey:@"isRefreshing"];
    
    // Update last updated date
    [host setValue:now forKey:@"lastUpdated"];
    
    // Refresh host so that fetched properties update
    [ManagedObjectContext() refreshObject:host mergeChanges:YES];
    
    // Remove host query
    [hostQueries removeObject:hostQuery];
    
    // Notify user of changes
    JobStatusNotifier *notifier = 
        [[JobStatusNotifier alloc] initWithCompletingJobs:completingJobsSet initiatingJobs:initiatingJobsSet onHost:host];
    [notifier notifyUserOfChanges];
    [notifier release];
    
    // Save changes
    NSError *saveError;
    [ManagedObjectContext() save:&saveError];
    
    [self enableUndoRegistration];
}


-(void)hostQuery:(HostQuery *)hostQuery didFailWithError:(NSError *)error {
    [self disableUndoRegistration];
    
    // Stop refreshing host
    [[hostQuery valueForKey:@"host"] setValue:[NSNumber numberWithBool:NO] forKey:@"isRefreshing"];
    
    // Deactivate host
    [[hostQuery valueForKey:@"host"] setValue:[NSNumber numberWithBool:NO] forKey:@"isActive"];
    
    // Warn user of problem
    [NSApp presentError:error modalForWindow:[[MainController sharedMainController] window] delegate:nil didPresentSelector:NULL contextInfo:NULL];
    
    // Remove host query
    [hostQueries removeObject:hostQuery];
    
    [self enableUndoRegistration];
}


-(void)performScheduledHostQuery:(NSTimer *)timer {
    NSError *error;
    NSFetchRequest *activeHostsRequest = [ManagedObjectModel() fetchRequestTemplateForName:@"ActiveHosts"];
    NSArray *activeHosts = [ManagedObjectContext() executeFetchRequest:activeHostsRequest error:&error];
    [self queryHosts:activeHosts];
    [self removeOldJobs];
}


- (BOOL)isQuerying {
    return isQuerying;
}


- (void)setIsQuerying:(BOOL)flag {
    isQuerying = flag;
}


// Immediately initiate queries of all hosts
-(void)queryHosts:(NSArray *)hosts {
    [self repeatedlyPerformSelector:@selector(queryHost:) withObjects:hosts];
}


-(void)queryHost:(Host *)host {
    if ( ![host isKindOfClass:[RealHost class]] ) return;
    if ( ![[host valueForKey:@"isActive"] boolValue] ) return;
    if ( [[host valueForKey:@"isRefreshing"] boolValue] ) return;
    
    // Query the host
    AccessShell *accessShell = [host valueForKey:@"accessShell"];
    if ( nil == accessShell ) return; // No shell to access, so don't query
    HostQuery *hostQuery = [accessShell queryForHost:(RealHost *)host];
    if ( nil == hostQuery ) return;  // Not enough information to query
    [hostQuery setDelegate:self];
    [hostQueries addObject:hostQuery];
    
    [self disableUndoRegistration];
    [host setValue:[NSNumber numberWithBool:YES] forKey:@"isRefreshing"];
    [self enableUndoRegistration];

    [hostQuery initiateQuery];

}


-(void)removeOldJobs {    
    NSError *error = nil;
    int hours = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HoursBeforeRemovalOfFinishedJobs"] intValue];
    if ( hours < 0 ) return; // Manual removal
    
    [self disableUndoRegistration];
    
    NSCalendarDate *expiryDate = [[NSCalendarDate date] dateByAddingYears:0 months:0 days:0 hours:-hours minutes:0 seconds:0];
    NSArray *jobs = [NSManagedObjectContext fetchObjectsWithTemplate:@"OldJobs" substitutionDictionary:
        [NSDictionary dictionaryWithObjectsAndKeys:
            expiryDate, @"EXPIRY_DATE", 
            nil] error:&error];
    [ManagedObjectContext() repeatedlyPerformSelector:@selector(deleteObject:) withObjects:jobs];
    
    [self enableUndoRegistration];
}


-(void)disableUndoRegistration {
    [ManagedObjectContext() processPendingChanges]; 
    [[ManagedObjectContext() undoManager] disableUndoRegistration];
}


-(void)enableUndoRegistration {
    [ManagedObjectContext() processPendingChanges];  
    [[ManagedObjectContext() undoManager] enableUndoRegistration];
}


@end
