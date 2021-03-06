//
//  ExpandingSidebar.m
//  iSoul
//
//  Created by Richard on 1/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ExpandingSidebar.h"
#import "SidebarItem.h"
#import "MainWindowController.h"

#define kRightBuffer    61
#define kLeftBuffer     75
#define kTopBuffer      5
#define kIconSize       14

@implementation ExpandingSidebar
@synthesize connectionState;

- (void)awakeFromNib
{
	connectionState = usOffline;
}

- (void)setConnectionState:(ConnectionState)newState
{
	connectionState = newState;
	[self setNeedsDisplayInRect:[self getIconRect]];
}
	 
- (NSRect)getIconRect
{
	NSRect bounds = [self bounds];
	return NSMakeRect(bounds.origin.x + kLeftBuffer,
					  bounds.origin.y + kTopBuffer, kIconSize, kIconSize);
}

- (void)reloadData;
{
	[super reloadData];
	
	for(NSInteger i = 0; i < [self numberOfRows]; i++) {
		NSTreeNode *item = [self itemAtRow:i];
		SidebarItem *si = [item representedObject];
		if([[si isExpanded] boolValue]) {
			[self expandItem:item];
		}			
	}
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	NSImage *statusImage = nil;
	switch (connectionState) 
    {
		case usOnline:
		{
			//statusImage = [NSImage imageNamed:@"Connect"];
            statusImage = [NSImage imageNamed:@"GreenDot"];
			break;
		}
		case usOffline:
		{
			//statusImage = [NSImage imageNamed:@"Disconnect"];
            statusImage = [NSImage imageNamed:@"RedDot"];
			break;
		}
		case usAway:
		{
			//statusImage = [NSImage imageNamed:@"Away"];
            statusImage = [NSImage imageNamed:@"YellowDot"];
			break;
		}
	}
	
	if (statusImage) 
    {
		NSRect imageRect = [self getIconRect];
		
		// only draw the image if necessary
		if (NSIntersectsRect(rect, imageRect)) 
        {
//			[statusImage compositeToPoint:NSMakePoint(imageRect.origin.x, imageRect.origin.y + imageRect.size.height)
//								operation:NSCompositeSourceOver];
            [statusImage drawInRect:[self getIconRect] 
                           fromRect:NSZeroRect 
                          operation:NSCompositeSourceOver 
                           fraction:1.0 
                     respectFlipped:YES 
                              hints:nil];
		}		
	}
}


- (void) keyDown:(NSEvent *) theEvent
{

    NSInteger rowIndex = [self selectedRow];
    
    if ([theEvent modifierFlags] & NSNumericPadKeyMask) { // arrow keys have this mask
        NSString *theArrow = [theEvent charactersIgnoringModifiers];
        if ( [theArrow length] == 1 ) {
            unichar pressedKey = [theArrow characterAtIndex:0];
            if (pressedKey == NSLeftArrowFunctionKey ||
                pressedKey == NSRightArrowFunctionKey ||
                pressedKey == NSDownArrowFunctionKey ||
                pressedKey == NSUpArrowFunctionKey)
            {
                // In which direction should the selection change?
                NSInteger direction =
                    (pressedKey == NSLeftArrowFunctionKey ||
                     pressedKey == NSUpArrowFunctionKey) ? -1 : 1;
                
                // Skip non selectable rows
                do {
                    rowIndex += direction;
                    // If you have to skip too far, don't change the selection at all
                    if (rowIndex < 0 || rowIndex >= [self numberOfRows]) {
                        rowIndex = [self selectedRow];
                        break;
                    }
                } while (![self shouldSelectItemAtIndex:rowIndex]);

                [self selectRowIndexes:
                    [NSIndexSet indexSetWithIndex:(NSUInteger)rowIndex] byExtendingSelection:NO];
                [(id)self.delegate changeView:self];
            }
        }
    }
    
    // before: [super keyDown:event]; /* This is an error. Events are passed to responders.*/
    [self.nextResponder keyDown:theEvent];
}

- (BOOL) shouldSelectItemAtIndex:(NSInteger) rowIndex
{
    id rowItem = [self itemAtRow:rowIndex];
    return [self.delegate outlineView:self shouldSelectItem:rowItem];
}

@end
