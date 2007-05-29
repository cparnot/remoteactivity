//
//  MainController.m
//  RemoteActivity
//
//  Created by Drew McCormack on 14/01/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "MainController.h"
#import "BatchSystem.h"
#import "AccessShell.h"
#import "QueryManager.h"
#import "JobCountFormatter.h"
#import "GradientView.h"
#import "Job.h"
#import "FilterSegmentedControl.h"
#import "GlobalFunctions.h"
#import "VirtualHost.h"
#import "RealHost.h"


static NSString *ToggleJobDrawer        = @"ToggleJobDrawer";
static NSString *RefreshAllHosts        = @"RefreshSelectedHosts";
static NSString *RefreshSelectedHosts   = @"RefreshAllHosts";
static NSString *JobsSearchField        = @"JobsSearchField";


@interface MainController (Toolbar)

-(void)setupToolbar;

@end


@implementation MainController

+(void)initialize {
    NSRect collapsedFrame = NSMakeRect(40.0, 40.0, 170.0, 300.0);
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:NO],       @"windowIsCollapsed",
        NSStringFromRect(collapsedFrame),   @"alternateCollapsedStateFrameRect",
        nil]];
}

static MainController *sharedMainController = nil;
+(id)sharedMainController {
    return sharedMainController;
}
 
-(void)awakeFromNib {
    // Autosaving
    [self setShouldCascadeWindows:NO];  // Required to make autosaving of window work
    [[self window] setFrameAutosaveName:@"RemoteActivityMainWindow"];
    
    // Other setup
    sharedMainController = self;
    [jobCountTextField setFormatter:[[[JobCountFormatter alloc] init] autorelease]];
    [self setupToolbar];
    [BatchSystem refreshBatchSystems];
    [AccessShell refreshAccessShells];
    [[QueryManager sharedQueryManager] startQuerying];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:)
        name:NSApplicationWillTerminateNotification object:NSApp];
        
    // Setup filter bar
    [filterBarGradientView setDrawsBorder:NO];
    [[filterSegmentedControl cell] setControlSize:NSSmallControlSize];
    [[filterSegmentedControl cell] setFont:[NSFont systemFontOfSize:11]];
    [filterSegmentedControl setSegmentCount:4];
    [filterSegmentedControl setLabel:@"All" forSegment:0];
    [filterSegmentedControl setPredicate:[NSPredicate predicateWithValue:YES] forIndex:0];
    [filterSegmentedControl setLabel:@"Queued" forSegment:1];
    [filterSegmentedControl setPredicate:[NSPredicate predicateWithFormat:@"status == %@", [NSNumber numberWithInt:QueuedJobStatus]] forIndex:1];
    [filterSegmentedControl setLabel:@"Running" forSegment:2];
    [filterSegmentedControl setPredicate:[NSPredicate predicateWithFormat:@"status == %@", [NSNumber numberWithInt:RunningJobStatus]] forIndex:2];
    [filterSegmentedControl setLabel:@"Finished" forSegment:3];
    [filterSegmentedControl setPredicate:[NSPredicate predicateWithFormat:@"status == %@", [NSNumber numberWithInt:FinishedJobStatus]] forIndex:3];
    [filterSegmentedControl setSelectedSegment:0];
    [filterSegmentedControl sizeToFit];
    
    [searchField bind:NSPredicateBinding toObject:filterSegmentedControl withKeyPath:@"appendedPredicate" options:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"(name contains[c] $value) or (host.name contains[c] $value)", NSPredicateFormatBindingOption,
            @"Filter Jobs", NSDisplayNameBindingOption,
            nil]];
}


-(void)dealloc {
    [searchField unbind:@"predicate"];
    [super dealloc];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[QueryManager sharedQueryManager] stopQuerying];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Host menu methods
-(IBAction)editHost:(id)sender {
    [hostsController editHost:sender];
}

-(IBAction)takeHostsOnline:(id)sender {
    [hostsController takeHostsOnline:sender];
}

-(IBAction)takeHostsOffline:(id)sender {
    [hostsController takeHostsOffline:sender];
}

#pragma mark Actions
-(IBAction)queryAllHosts:(id)sender {
    [[QueryManager sharedQueryManager] queryHosts:[hostsController arrangedObjects]];
}

-(IBAction)querySelectedHosts:(id)sender {
    [[QueryManager sharedQueryManager] queryHosts:[hostsController selectedObjects]];
}

-(IBAction)expandJobInfo:(id)sender {
    [jobInfoSplitSubview expandWithAnimation];
}

-(IBAction)toggleCollapsedStateOfJobInfo:(id)sender {
    if ( [jobInfoSplitSubview isCollapsed] ) 
        [jobInfoSplitSubview expandWithAnimation];
    else
        [jobInfoSplitSubview collapseWithAnimation];
}

-(IBAction)undo:sender {
    [[ManagedObjectContext() undoManager] undo];
}


-(IBAction)redo:sender {
    [[ManagedObjectContext() undoManager] redo];
}

-(IBAction)toggleCollapsedStateOfWindow:(id)sender {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSRect currentFrame = [[self window] frame];
    NSRect newFrame = NSRectFromString([defs stringForKey:@"alternateCollapsedStateFrameRect"]);
    [defs setValue:NSStringFromRect(currentFrame) forKey:@"alternateCollapsedStateFrameRect"];
    if ( [defs boolForKey:@"windowIsCollapsed"] ) {
        [jobSplitSubview performSelector:@selector(expand) withObject:nil afterDelay:0.0];
    }
    else {
        [jobSplitSubview collapse];
    }
    [[self window] setFrame:newFrame display:YES animate:YES];
    [defs setBool:![defs boolForKey:@"windowIsCollapsed"] forKey:@"windowIsCollapsed"];
}


#pragma mark Undo/Redo
-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
    return [ManagedObjectContext() undoManager];
}


#pragma mark Interface Item Validation
-(BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if ([anItem action] == @selector(undo:)) {
        return [[ManagedObjectContext() undoManager] canUndo];
    }
    if ([anItem action] == @selector(redo:)) {
        return [[ManagedObjectContext() undoManager] canRedo];
    }
    if ( [anItem action] == @selector(editHost:) ) {
        return [hostsController validateMenuItem:anItem];
    }
    if ( [anItem action] == @selector(takeHostsOnline:) || [anItem action] == @selector(takeHostsOffline:) ) {
        return [hostsController validateMenuItem:anItem];
    }
    if ( [anItem action] == @selector(toggleCollapsedStateOfJobInfo:) ) {
        if ( [jobInfoSplitSubview isCollapsed] )
            [(id)anItem setTitle:@"Show Job Info"];
        else
            [(id)anItem setTitle:@"Hide Job Info"];
        return YES;
    }
    if ( [anItem action] == @selector(toggleCollapsedStateOfWindow:) ) {
        BOOL windowIsCollapsed = [[NSUserDefaults standardUserDefaults] boolForKey:@"windowIsCollapsed"];
        if ( windowIsCollapsed ) 
            [anItem setTitle:@"Full Detail Mode"];
        else 
            [anItem setTitle:@"Summary Mode"];
        return YES;
    }
    if ( [anItem action] == @selector(querySelectedHosts:) || [anItem action] == @selector(queryAllHosts:) ) {
        return [hostsController validateMenuItem:anItem];
    }
    return [super validateMenuItem:anItem];
}


#pragma mark Toolbar
-(void)setupToolbar {
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"MainWindowToolbar"];
    [toolbar autorelease];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [[self window] setToolbar:toolbar];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
    itemForItemIdentifier:(NSString *)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ( [itemIdentifier isEqualToString:ToggleJobDrawer] ) {
        [item setLabel:@"Job Info"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"JobInfo"]];
        [item setTarget:self];
        [item setAction:@selector(toggleCollapsedStateOfJobInfo:)];
    }
    else if ( [itemIdentifier isEqualToString:RefreshAllHosts] ) {
        [item setLabel:@"Refresh All"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"RefreshAll"]];
        [item setTarget:self];
        [item setAction:@selector(queryAllHosts:)];
    }
    else if ( [itemIdentifier isEqualToString:RefreshSelectedHosts] ) {
        [item setLabel:@"Refresh Selected"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"RefreshSelected"]];
        [item setTarget:self];
        [item setAction:@selector(querySelectedHosts:)];
    }
    else if ( [itemIdentifier isEqualToString:JobsSearchField] ) {
        [item setLabel:@"Search"];
        [item setPaletteLabel:[item label]];
        [item setMinSize:NSMakeSize(150.0f,32.0f)];
        [item setView:searchField];
    }
    
    return [item autorelease];
}



- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
        NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier, 
        ToggleJobDrawer,
        RefreshSelectedHosts,
        RefreshAllHosts,
        JobsSearchField,
        nil];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
        ToggleJobDrawer,
        NSToolbarSeparatorItemIdentifier,
        RefreshSelectedHosts,
        RefreshAllHosts,
        NSToolbarFlexibleSpaceItemIdentifier,
        JobsSearchField,
        nil];
}


@end
