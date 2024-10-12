#import <UIKit/UIKit.h>

/* To avoid breaking anything, we will apply a black background to the bottommost
transparent view if dark mode for the keyboard enabled */

@interface UIView (Private)
@property (nonatomic, assign, readonly) BOOL _mapkit_isDarkModeEnabled;

- (UIViewController *)_viewControllerForAncestor;
@end

static BOOL isDarkMode(UIView *view) {
	if ([view respondsToSelector:@selector(_mapkit_isDarkModeEnabled)]) {
		return view._mapkit_isDarkModeEnabled;
	}

	return view._viewControllerForAncestor.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
}

@interface UIKeyboard : UIView // Regular keyboard
+ (instancetype)activeKeyboard;
@end

%hook UIKeyboard
- (void)displayLayer:(id)arg1 {
    %orig;

    self.backgroundColor = isDarkMode(self) ? [UIColor blackColor] : [UIColor clearColor];
}
%end

@interface UIPredictionViewController : UIViewController // Keyboard with enabled predictions panel
@end

%hook UIPredictionViewController
- (id)_currentTextSuggestions {
    UIKeyboard *keyboard = [%c(UIKeyboard) activeKeyboard];

    if (isDarkMode(keyboard)) {
        [self.view setBackgroundColor:[UIColor blackColor]];
        keyboard.backgroundColor = [UIColor blackColor];
    } else {
        [self.view setBackgroundColor:[UIColor clearColor]];
        keyboard.backgroundColor = [UIColor clearColor];
    }

    return %orig;
}
%end

@interface UIKeyboardDockView : UIView // Dock under keyboard for notched devices
@end

%hook UIKeyboardDockView
- (void)layoutSubviews {
    %orig;

    self.backgroundColor = isDarkMode(self) ? [UIColor blackColor] : [UIColor clearColor];
}
%end

// Since we can't hook a private framework class from UIKit, we check the class name through the nearest available from UIKit class
%hook UIInputView
- (void)layoutSubviews {
    %orig;

    if ([self isKindOfClass:NSClassFromString(@"TUIEmojiSearchInputView")]) { // Emoji searching panel
        self.backgroundColor = isDarkMode(self) ? [UIColor blackColor] : [UIColor clearColor];
    }
}
%end
