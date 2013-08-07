//
//  GBAController.m
//  GBA4iOS
//
//  Created by Riley Testut on 7/27/13.
//  Copyright (c) 2013 Riley Testut. All rights reserved.
//

#import "GBAController.h"
#import "UIScreen+Widescreen.h"

typedef NS_ENUM(NSInteger, GBAControllerRect)
{
    GBAControllerRectDPad,
    GBAControllerRectA,
    GBAControllerRectB,
    GBAControllerRectAB,
    GBAControllerRectL,
    GBAControllerRectR,
    GBAControllerRectStart,
    GBAControllerRectSelect,
    GBAControllerRectMenu,
    GBAControllerRectScreen
};

static NSString *GBAScreenTypeiPhone = @"iPhone";
static NSString *GBAScreenTypeRetina = @"Retina";
static NSString *GBAScreenTypeRetina4 = @"Retina 4";
static NSString *GBAScreenTypeiPad = @"iPad";

@interface GBAController () <UIGestureRecognizerDelegate>

@property (copy, nonatomic) NSDictionary *infoDictionary;
@property (strong, nonatomic) UIImageView *imageView;

@property (readwrite, nonatomic) GBAControllerButton pressedButtons;

@property (strong, nonatomic) UIView *overlayView;

@end

@implementation GBAController

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

- (void)initialize
{
    self.multipleTouchEnabled = YES;
    self.backgroundColor = [UIColor clearColor];
    
    self.exclusiveTouch = YES;
    
    self.imageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:imageView];
        imageView;
    });
    self.orientation = GBAControllerOrientationPortrait;
}

#pragma mark - Getters / Setters

- (void)setSkinFilepath:(NSString *)skinFilepath
{
    _skinFilepath = [skinFilepath copy];
    _infoDictionary = [NSDictionary dictionaryWithContentsOfFile:[skinFilepath stringByAppendingPathComponent:@"Info.plist"]];
}

- (void)setOrientation:(GBAControllerOrientation)orientation
{
    _orientation = orientation;
    
    [self update];
}

#pragma mark - UIView subclass

- (CGSize)intrinsicContentSize
{
    return self.imageView.image.size;
}

#pragma mark - Touch Handling

static unsigned long pressedButtons;
static unsigned long newtouches[15];
static unsigned long oldtouches[15];

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouchEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self handleTouchEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self handleTouchEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject]; // Only get the new touch
    CGPoint location = [touch locationInView:self];
    
    if (location.y > CGRectGetHeight(self.bounds) - 20.0f)
    {
        // Need to run on next run loop, because Apple delays touches in the bottom 20 pixels for Control Center
        [self performSelector:@selector(handleTouchEvent:) withObject:event afterDelay:0.15];
    }
    else
    {
        [self handleTouchEvent:event];
    }
}

- (void)handleTouchEvent:(UIEvent *)event
{
    
    // Oh man, the hours I spent trying to debug this because I didn't realize t only returns the CHANGED touches, while [event allTouches] actually has all touches
    NSSet *touches = [event allTouches];
    
	int touchstate[15];
    
	int touchcount = [touches count];
	
	for (int i = 0; i < 10; i++)
	{
		touchstate[i] = 0;
		oldtouches[i] = newtouches[i];
	}
    
	for (int i = 0; i < touchcount; i++)
	{
		UITouch *touch = [[touches allObjects] objectAtIndex:i];
		
		if (touch != nil && (touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary) )
		{
			CGPoint point = [touch locationInView:self];
            
			touchstate[i] = 1;
            
            
            CGRect dPadRect = [self rectForButtonRect:GBAControllerRectDPad];
            if (CGRectContainsPoint(dPadRect, point))
            {
                CGRect topRect            = CGRectMake(dPadRect.origin.x, dPadRect.origin.y, dPadRect.size.width, dPadRect.size.height * (1.0f/3.0f));
                CGRect bottomRect         = CGRectMake(dPadRect.origin.x, dPadRect.origin.y + dPadRect.size.height * (2.0f/3.0f), dPadRect.size.width, dPadRect.size.height * (1.0f/3.0f));
                CGRect leftRect           = CGRectMake(dPadRect.origin.x, dPadRect.origin.y, dPadRect.size.width * (1.0f/3.0f), dPadRect.size.height);
                CGRect rightRect          = CGRectMake(dPadRect.origin.x + dPadRect.size.width * (2.0f/3.0f), dPadRect.origin.y, dPadRect.size.width * (1.0f/3.0f), dPadRect.size.height);
                
                CGRect topLeftRect        = CGRectIntersection(topRect, leftRect);
                CGRect topRightRect       = CGRectIntersection(topRect, rightRect);
                CGRect bottomLeftRect     = CGRectIntersection(bottomRect, leftRect);
                CGRect bottomRightRect    = CGRectIntersection(bottomRect, rightRect);
                
                if (CGRectContainsPoint(topLeftRect, point))
                {
                    pressedButtons |= GBAControllerButtonUp | GBAControllerButtonLeft;
                    newtouches[i] = GBAControllerButtonUp | GBAControllerButtonLeft;
                }
                else if (CGRectContainsPoint(topRightRect, point))
                {
                    pressedButtons |= GBAControllerButtonUp | GBAControllerButtonRight;
                    newtouches[i] = GBAControllerButtonUp | GBAControllerButtonRight;
                }
                else if (CGRectContainsPoint(bottomLeftRect, point))
                {
                    pressedButtons |= GBAControllerButtonDown | GBAControllerButtonLeft;
                    newtouches[i] = GBAControllerButtonDown | GBAControllerButtonLeft;
                }
                else if (CGRectContainsPoint(bottomRightRect, point))
                {
                    pressedButtons |= GBAControllerButtonDown | GBAControllerButtonRight;
                    newtouches[i] = GBAControllerButtonDown | GBAControllerButtonRight;
                }
                else if (CGRectContainsPoint(topRect, point))
                {
                    pressedButtons |= GBAControllerButtonUp;
                    newtouches[i] = GBAControllerButtonUp;
                }
                else if (CGRectContainsPoint(leftRect, point))
                {
                    pressedButtons |= GBAControllerButtonLeft;
                    newtouches[i] = GBAControllerButtonLeft;
                }
                else if (CGRectContainsPoint(bottomRect, point))
                {
                    pressedButtons |= GBAControllerButtonDown;
                    newtouches[i] = GBAControllerButtonDown;
                }
                else if (CGRectContainsPoint(rightRect, point))
                {
                    pressedButtons |= GBAControllerButtonRight;
                    newtouches[i] = GBAControllerButtonRight;
                }
                
            }
            else if (CGRectContainsPoint([self rectForButtonRect:GBAControllerRectA], point))
			{
				pressedButtons |= GBAControllerButtonA;
				newtouches[i] = GBAControllerButtonA;
			}
            else if (CGRectContainsPoint([self rectForButtonRect:GBAControllerRectB], point))
			{
				pressedButtons |= GBAControllerButtonB;
				newtouches[i] = GBAControllerButtonB;
			}
            else if (CGRectContainsPoint([self rectForButtonRect:GBAControllerRectAB], point))
			{
				pressedButtons |= GBAControllerButtonA | GBAControllerButtonB;
				newtouches[i] = GBAControllerButtonA | GBAControllerButtonB;
			}
			else if (CGRectContainsPoint([self rectForButtonRect:GBAControllerRectL], point))
			{
				pressedButtons |= GBAControllerButtonL;
				newtouches[i] = GBAControllerButtonL;
			}
			else if (CGRectContainsPoint([self rectForButtonRect:GBAControllerRectR], point))
			{
				pressedButtons |= GBAControllerButtonR;
				newtouches[i] = GBAControllerButtonR;
			}
			else if (CGRectContainsPoint([self rectForButtonRect:GBAControllerRectSelect], point))
			{
				pressedButtons |= GBAControllerButtonSelect;
				newtouches[i] = GBAControllerButtonSelect;
			}
			else if (CGRectContainsPoint([self rectForButtonRect:GBAControllerRectStart], point))
			{
				pressedButtons |= GBAControllerButtonStart;
				newtouches[i] = GBAControllerButtonStart;
			}
			else if (CGRectContainsPoint([self rectForButtonRect:GBAControllerRectMenu], point))
			{
                [self sendActionsForControlEvents:UIControlEventTouchUpInside];
			}
			
			if(oldtouches[i] != newtouches[i])
			{
				pressedButtons &= ~(oldtouches[i]);
			}
		}
	}
    
    
	for (int i = 0; i < 10; i++)
	{
		if(touchstate[i] == 0)
		{
			pressedButtons &= ~(newtouches[i]);
			newtouches[i] = 0;
			oldtouches[i] = 0;
		}
	}
    
    if (self.pressedButtons != pressedButtons)
    {
        self.pressedButtons = pressedButtons;
        
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

#pragma mark - Public

- (void)showButtonRects
{
    self.overlayView = (
                        {
                            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
                            view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                            view.userInteractionEnabled = NO;
                            [self addSubview:view];
                            view;
                        });
    
    void(^AddOverlayForButton)(GBAControllerRect button) = ^(GBAControllerRect button)
    {
        UILabel *overlay = [[UILabel alloc] initWithFrame:[self rectForButtonRect:button]];
        overlay.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
        overlay.text = [self keyForButtonRect:button];
        overlay.adjustsFontSizeToFitWidth = YES;
        overlay.textColor = [UIColor whiteColor];
        overlay.font = [UIFont boldSystemFontOfSize:18.0f];
        overlay.textAlignment = NSTextAlignmentCenter;
        [self addSubview:overlay];
    };
    
    AddOverlayForButton(GBAControllerRectDPad);
    AddOverlayForButton(GBAControllerRectA);
    AddOverlayForButton(GBAControllerRectB);
    AddOverlayForButton(GBAControllerRectAB);
    AddOverlayForButton(GBAControllerRectL);
    AddOverlayForButton(GBAControllerRectR);
    AddOverlayForButton(GBAControllerRectStart);
    AddOverlayForButton(GBAControllerRectSelect);
    AddOverlayForButton(GBAControllerRectMenu);
    
    // AddOverlayForButton(GBAControllerRectScreen);
}

- (void)hideButtonRects
{
    [self.overlayView removeFromSuperview];
    self.overlayView = nil;
}

#pragma mark - Private

- (void)update
{
    self.imageView.image = [self imageForOrientation:self.orientation];
    [self invalidateIntrinsicContentSize];
}

#pragma mark - Private Helper Methods

- (UIImage *)imageForOrientation:(GBAControllerOrientation)orientation
{
    NSDictionary *dictionary = [self dictionaryForOrientation:orientation];
    NSDictionary *assets = dictionary[@"Assets"];
    
    NSString *key = [self keyForCurrentDeviceWithDictionary:assets];
    NSString *relativePath = assets[key];
    
    NSString *filepath = [self.skinFilepath stringByAppendingPathComponent:relativePath];
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    if ([key isEqualToString:GBAScreenTypeiPhone] || [key isEqualToString:GBAScreenTypeiPad])
    {
        scale = 1.0f; // In case of a skin without retina artwork
    }
    
    UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:filepath] scale:scale];
    
    return image;
}

- (CGRect)rectForButtonRect:(GBAControllerRect)button
{
    NSDictionary *dictionary = [self dictionaryForOrientation:self.orientation];
    NSDictionary *layout = dictionary[@"Layout"];
    
    NSString *key = [self keyForCurrentDeviceWithDictionary:layout];
    NSDictionary *rect = layout[key];
    
    key = [self keyForButtonRect:button];
    NSDictionary *buttonRect = rect[key];
    
    return CGRectMake([buttonRect[@"X"] floatValue], [buttonRect[@"Y"] floatValue], [buttonRect[@"Width"] floatValue], [buttonRect[@"Height"] floatValue]);
}

- (NSString *)keyForButtonRect:(GBAControllerRect)button
{
    NSString *key = nil;
    switch (button) {
        case GBAControllerRectDPad:
            key = @"D-Pad";
            break;
            
        case GBAControllerRectA:
            key = @"A";
            break;
            
        case GBAControllerRectB:
            key = @"B";
            break;
            
        case GBAControllerRectAB:
            key = @"AB";
            break;
            
        case GBAControllerRectStart:
            key = @"Start";
            break;
            
        case GBAControllerRectSelect:
            key = @"Select";
            break;
            
        case GBAControllerRectL:
            key = @"L";
            break;
            
        case GBAControllerRectR:
            key = @"R";
            break;
            
        case GBAControllerRectMenu:
            key = @"Menu";
            break;
            
        case GBAControllerRectScreen:
            key = @"Screen";
            break;
    }
    
    return key;
}

- (NSString *)keyForCurrentDeviceWithDictionary:(NSDictionary *)dictionary
{
    NSString *key = nil;
    
    if ([[UIScreen mainScreen] scale] == 2.0)
    {
        if ([[UIScreen mainScreen] isWidescreen])
        {
            if ([dictionary objectForKey:GBAScreenTypeRetina4])
            {
                key = GBAScreenTypeRetina4;
            }
            else if ([dictionary objectForKey:GBAScreenTypeRetina])
            {
                key = GBAScreenTypeRetina;
            }
            else {
                key = GBAScreenTypeiPhone;
            }
            
        }
        else
        {
            if ([dictionary objectForKey:GBAScreenTypeRetina])
            {
                key = GBAScreenTypeRetina;
            }
            else {
                key = GBAScreenTypeiPhone;
            }
        }
    }
    else
    {
        key = GBAScreenTypeiPhone;
    }
    
    return key;
}

- (NSDictionary *)dictionaryForOrientation:(GBAControllerOrientation)orientation
{
    NSDictionary *dictionary = nil;
    
    switch (orientation) {
        case GBAControllerOrientationPortrait:
            dictionary = self.infoDictionary[@"Portrait"];
            break;
            
        case GBAControllerOrientationLandscape:
            dictionary = self.infoDictionary[@"Landscape"];
            break;
    }
    
    return dictionary;
}

@end
