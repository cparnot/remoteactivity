#import "ImageAndTextCell.h"
#import "CTGradient.h"


static const double LeftPad = 3.0;
static const double ImageTextSpacing = 3.0;


@implementation ImageAndTextCell


- (void)dealloc {
    [image release];
    image = nil;
    [super dealloc];
}

- copyWithZone:(NSZone *)zone {
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
    cell->image = [image retain];
    return cell;
}

- (void)setImage:(NSImage *)anImage {
    if (anImage != image) {
        [image release];
        image = [anImage retain];
    }
}

- (NSImage *)image {
    return image;
}

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame {
    if (image != nil) {
        NSRect imageFrame;
        imageFrame.size = [image size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += LeftPad;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
        return NSZeroRect;
}


-(NSRect)textFrameForCellFrame:(NSRect)cellFrame {
    NSRect imageFrame, textFrame;
    NSSize imageSize = [image size];
    NSDivideRect(cellFrame, &imageFrame, &textFrame, LeftPad + imageSize.width, NSMinXEdge);        
    float pointSizeOfFont = [[self font] pointSize];
    textFrame.origin.x += ImageTextSpacing;
    textFrame.size.width -= ImageTextSpacing;
    textFrame = NSInsetRect(textFrame, 0.0, (NSHeight(textFrame) - pointSizeOfFont - 4) / 2.0);
    return textFrame;
}


- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    NSRect textFrame = [self textFrameForCellFrame:aRect];
    [super editWithFrame:textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}


- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
    NSRect textFrame = [self textFrameForCellFrame:aRect];
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSAssert( image != nil, @"Image was nil in drawWithFrame:");
    NSSize	imageSize;
    NSRect	imageFrame, textFrame;
    
    // Draw highlight
    BOOL highlighted = [self isHighlighted];
    /*
    if ( highlighted ) {
        CTGradient *grad = [CTGradient unifiedSelectedGradient];
        [grad fillRect:cellFrame angle:90.0];
    }*/

    imageSize = [image size];
    NSDivideRect(cellFrame, &imageFrame, &textFrame, LeftPad + imageSize.width, NSMinXEdge);
    if ([self drawsBackground]) {
        [[self backgroundColor] set];
        NSRectFill(imageFrame);
    }
    imageFrame.origin.x += LeftPad;
    imageFrame.size = imageSize;

    if ([controlView isFlipped])
        imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
    else
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

    [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    
    // Call super to draw text
    textFrame = [self textFrameForCellFrame:cellFrame];
    //[self setHighlighted:NO];
    [self setBackgroundColor:[NSColor clearColor]];
    [super drawWithFrame:textFrame inView:controlView];
    [self setHighlighted:highlighted];
    
}


- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + LeftPad + ImageTextSpacing;
    return cellSize;
}


@end

