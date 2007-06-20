//
//  HostCell.m
//  RemoteActivity
//
//  Created by Drew McCormack on 8/14/06.
//  Copyright 2006 Drew McCormack. All rights reserved.
//

#import "HostCell.h"
#import "HostFormatter.h"
#import "RealHost.h"
#import "VirtualHost.h"
#import "NSBezierPathAdditions.h"


static const double LeftPad = 3.0;
static const double IconTextSpacing = 3.0;
static const double TextJobsStatsSpacing = 6.0;
static const double JobsStatsSpacing = 1.0;
static const double JobsStatsWidth = 30.0;
static const double IconDimension = 40.0;


@interface HostCell (Private)

-(void)drawJobStat:(int)numJobs withBackgroundColor:(NSColor *)bgColor inRect:(NSRect)rect withCellFrame:(NSRect)cellFrame;

-(NSRect)textFrameForCellFrame:(NSRect)cellFrame;
-(NSRect)iconFrameForCellFrame:(NSRect)cellFrame;
-(NSRect)jobsStatFrameForCellFrame:(NSRect)cellFrame;
-(NSRect)queuedJobsStatFrameForCellFrame:(NSRect)cellFrame;
-(NSRect)runningJobsStatFrameForCellFrame:(NSRect)cellFrame;
-(NSRect)finishedJobsStatFrameForCellFrame:(NSRect)cellFrame;
-(NSRect)progressIndicatorFrameForCellFrame:(NSRect)cellFrame;

@end


@implementation HostCell

-(id)init {
    if ( self = [super init] ) {
        [self setFormatter:[[[HostFormatter alloc] init] autorelease]];
        progressIndicator = nil;
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)coder {
    if ( self = [super initWithCoder:coder] ) {
        [self setFormatter:[[[HostFormatter alloc] init] autorelease]];
        progressIndicator = nil;
    }
    return self;
}


-(void)dealloc {
    [icon release];
    [progressIndicator release];
    [super dealloc];
}


- (void)setObjectValue:(NSObject <NSCopying> *)object {
    if ( object == nil ) return;
    NSString *iconName = nil;
    if ( [object isKindOfClass:[RealHost class]] ) {
        switch ([[object valueForKey:@"machineType"] intValue]  ) {
        case DesktopMachineType:
            iconName = @"MacPro";
            break;
        case LaptopMachineType:
            iconName = @"MacBookPro";
            break;
        case ClusterMachineType:
            iconName = @"WorkgroupCluster";
            break;
        case SupercomputerMachineType:
            iconName = @"Supercomputer";
            break;
        case GridMachineType:
            iconName = @"Grid";
            break;
        default:
            @throw [NSException exceptionWithName:@"InvalidMachineType" 
                reason:@"Invalid machine type in setObjectValue:"
                userInfo:nil];
        }
        [self setProgressIndicator:[object valueForKey:@"refreshProgressIndicator"]];
    } else {
        NSString *name = [object valueForKey:@"name"];
        if ( [name isEqualToString:@"All Jobs"]  ) {
            iconName = @"All";
        }   
        else if ( [name isEqualToString:@"Recently Changed"]  ) {
            iconName = @"RecentlyChanged";
        }  
        else {
            @throw [NSException exceptionWithName:@"InvalidVirtualHost" 
                reason:@"Invalid virtual host in setObjectValue:"
                userInfo:nil];
        }
    }
    [self setIcon:[NSImage imageNamed:iconName]];
    numRunningJobs = [[object valueForKey:@"runningJobs"] count];
    numQueuedJobs = [[object valueForKey:@"queuedJobs"] count];
    numFinishedJobs = [[object valueForKey:@"finishedJobs"] count];
    [super setObjectValue:object];
}


-(id)copyWithZone:(NSZone *)zone {
    HostCell *cell = (HostCell *)[super copyWithZone:zone];
    cell->icon = [icon retain];
    cell->progressIndicator = [progressIndicator retain];
    return cell;
}

-(void)setIcon:(NSImage *)anIcon {
    if (anIcon != icon) {
        [icon release];
        icon = [anIcon retain];
    }
}

- (NSImage *)icon {
    return icon;
}


-(NSView *)progressIndicator {
    return progressIndicator;
}

-(void)setProgressIndicator:(NSView *)newProgressIndicator {
    [newProgressIndicator retain];
    [progressIndicator release];
    progressIndicator = newProgressIndicator;
}


-(NSRect)iconFrameForCellFrame:(NSRect)cellFrame {
    if (icon != nil) {
        NSRect iconFrame;
        //iconFrame.size = [icon size];
        iconFrame.size = NSMakeSize(IconDimension,IconDimension);
        iconFrame.origin = cellFrame.origin;
        iconFrame.origin.x += LeftPad;
        iconFrame.origin.y += ceil((cellFrame.size.height - iconFrame.size.height) / 2);
        return iconFrame;
    }
    else
        return NSZeroRect;
}


-(NSRect)progressIndicatorFrameForCellFrame:(NSRect)cellFrame {
    NSRect textFrame = [self textFrameForCellFrame:cellFrame];
    NSSize viewSize = (nil == progressIndicator ? NSZeroSize : [progressIndicator frame].size);
    NSRect indicatorFrame = textFrame;
    indicatorFrame.origin.x = NSMaxX(textFrame);
    indicatorFrame.size.width = viewSize.width;
    
    // Align bottom of progress indicator with bottom of text
    indicatorFrame.origin.y += textFrame.size.height - viewSize.height;
    
    return indicatorFrame;
}


-(NSRect)textFrameForCellFrame:(NSRect)cellFrame {
    NSRect iconFrame, textFrame;
    NSSize iconSize = NSMakeSize(IconDimension, IconDimension);
    NSDivideRect(cellFrame, &iconFrame, &textFrame, LeftPad + iconSize.width, NSMinXEdge);        
    float pointSizeOfFont = [[self font] pointSize];
    textFrame.origin.x += IconTextSpacing;
    textFrame.size.width -= IconTextSpacing;
    textFrame.size.width -= ( progressIndicator != nil ? NSWidth([[self progressIndicator] frame]) : 0 );
    textFrame.size.height = pointSizeOfFont + 4;
    iconFrame = [self iconFrameForCellFrame:cellFrame];
    textFrame.origin.y = iconFrame.origin.y;
    return textFrame;
}


-(NSRect)jobsStatFrameForCellFrame:(NSRect)cellFrame {
    NSRect iconFrame = [self iconFrameForCellFrame:cellFrame];
    NSRect textFrame = [self textFrameForCellFrame:cellFrame];
    float width = MAX(0.0, NSMaxX(cellFrame) - NSMaxX(iconFrame));
    float height = NSHeight(iconFrame) - TextJobsStatsSpacing - NSHeight(textFrame); 
    float x = NSMinX(textFrame);
    float y = NSMaxY(textFrame) + TextJobsStatsSpacing;
    return NSMakeRect(x, y, width, height);
}


-(NSRect)queuedJobsStatFrameForCellFrame:(NSRect)cellFrame {
    NSRect jobsStatFrame = [self jobsStatFrameForCellFrame:cellFrame];
    NSRect queuedFrame = jobsStatFrame;
    queuedFrame.size.width = JobsStatsWidth;
    return queuedFrame;
}


-(NSRect)runningJobsStatFrameForCellFrame:(NSRect)cellFrame {
    NSRect queuedFrame = [self queuedJobsStatFrameForCellFrame:cellFrame];
    NSRect runningFrame = queuedFrame;
    runningFrame.origin.x += NSWidth(queuedFrame) + JobsStatsSpacing;
    return runningFrame;
}


-(NSRect)finishedJobsStatFrameForCellFrame:(NSRect)cellFrame {
    NSRect runningFrame = [self runningJobsStatFrameForCellFrame:cellFrame];
    NSRect finishedFrame = runningFrame;
    finishedFrame.origin.x += NSWidth(runningFrame) + JobsStatsSpacing;
    return finishedFrame;
}


- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    NSRect textFrame = [self textFrameForCellFrame:aRect];
    [super editWithFrame:textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}


- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
    NSRect textFrame = [self textFrameForCellFrame:aRect];
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}


-(void)drawJobStat:(int)numJobs withBackgroundColor:(NSColor *)bgColor inRect:(NSRect)rect withCellFrame:(NSRect)cellFrame {
    // Draw circle
    [NSGraphicsContext saveGraphicsState]; 
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowOffset:NSMakeSize(0,-1.5)];
    [shadow setShadowBlurRadius:1.0];
    [shadow set];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect,4,2) cornerRadius:5.0];
    [[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
    [path fill];
    [[bgColor colorWithAlphaComponent:1.0] set];
    [path fill];
    [bgColor set];
    [path setLineWidth:0.5];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
    
    // First setup text attributes
    [NSGraphicsContext saveGraphicsState]; 
    NSMutableParagraphStyle *paraStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paraStyle setAlignment:NSCenterTextAlignment];
    NSMutableDictionary *attribs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:9.0], NSFontAttributeName,
        paraStyle, NSParagraphStyleAttributeName,
        nil];
        
    // Draw bevel
    rect.origin.y += 3.0; // Trial and error centering of text
    NSString *statString = ( numQueuedJobs > 999 ? @"---" : [NSString stringWithFormat:@"%d", numJobs] );
    [attribs setObject:[NSColor colorWithCalibratedWhite:0.7 alpha:0.5] forKey:NSForegroundColorAttributeName];
    rect.origin.y += 0.5;
    rect.origin.x += 0.5;
    [statString drawInRect:rect withAttributes:attribs];
        
    // Draw text
    rect.origin.y -= 0.5;
    rect.origin.x -= 0.5;
    [attribs setObject:[NSColor colorWithCalibratedWhite:0.35 alpha:1.0] forKey:NSForegroundColorAttributeName];
    [statString drawInRect:rect withAttributes:attribs];

    [NSGraphicsContext restoreGraphicsState];
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSAssert( icon != nil, @"Icon was nil in drawWithFrame:");
    NSSize	iconSize;
    NSRect	iconFrame, textFrame;
    
    [[NSColor blackColor] set];
    
    // Draw icon
    iconSize = [icon size];
    NSDivideRect(cellFrame, &iconFrame, &textFrame, LeftPad + iconSize.width, NSMinXEdge);
    if ([self drawsBackground]) {
        [[self backgroundColor] set];
        NSRectFill(iconFrame);
    }
    iconFrame.origin.x += LeftPad;
    iconFrame.size = iconSize;
    
    if (![controlView isFlipped])
        iconFrame.origin.y += ceil((cellFrame.size.height + iconFrame.size.height) / 2);
    else
        iconFrame.origin.y += ceil((cellFrame.size.height - iconFrame.size.height) / 2);
    
    [icon setFlipped:[controlView isFlipped]];
    [icon drawInRect:iconFrame fromRect:NSMakeRect(0,0,iconSize.width,iconSize.height) operation:NSCompositeSourceOver fraction:1.0];
    
    // Draw badge if offlines
    if ( [[self objectValue] isKindOfClass:[RealHost class]] && ![[[self objectValue] valueForKey:@"isActive"] boolValue] ) {
        NSImage *badge = [NSImage imageNamed:@"HostOffline"];
        [badge setFlipped:YES];
        NSRect offlineBadgeRect = NSMakeRect(iconFrame.origin.x + 0.5*(iconFrame.size.width-[badge size].width), iconFrame.origin.y + 0.5*[badge size].height, [badge size].width, [badge size].height);
        [badge drawInRect:offlineBadgeRect fromRect:NSMakeRect(0, 0, [badge size].width, [badge size].height) 
            operation:NSCompositeSourceOver fraction:1.0];
    }
        
    // Now draw images and text
    // Begin with queued jobs. First set a clipping rect.
    [self drawJobStat:numQueuedJobs 
        withBackgroundColor:[NSColor colorWithDeviceRed:0.88 green:0.88 blue:0.45 alpha:1.0]
        inRect:[self queuedJobsStatFrameForCellFrame:cellFrame] 
        withCellFrame:cellFrame];
    
    // Running jobs
    [self drawJobStat:numRunningJobs 
        withBackgroundColor:[NSColor colorWithDeviceRed:0.69 green:0.88 blue:0.45 alpha:1.0]
        inRect:[self runningJobsStatFrameForCellFrame:cellFrame] 
        withCellFrame:cellFrame];
        
    // Finished jobs
    [self drawJobStat:numFinishedJobs 
        withBackgroundColor:[NSColor colorWithDeviceRed:0.91 green:0.54 blue:0.53 alpha:1.0]
        inRect:[self finishedJobsStatFrameForCellFrame:cellFrame] 
        withCellFrame:cellFrame];

    // Call super to draw text
    textFrame = [self textFrameForCellFrame:cellFrame];
    [self setBackgroundColor:[NSColor clearColor]];
    [super drawWithFrame:textFrame inView:controlView];
    
    // Add progress indicator to table view
    if( progressIndicator != nil && [progressIndicator superview] != controlView ) {
        [controlView addSubview:progressIndicator];
    }
    NSRect progIndicatorRect = [self progressIndicatorFrameForCellFrame:cellFrame];
    [progressIndicator setFrame:progIndicatorRect];
}


- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (icon ? [icon size].width : 0) + LeftPad + IconTextSpacing;
    return cellSize;
}


@end

