/*
 * BannerOffset  (com.sonic125.banneroffset)
 *
 * Moves ONLY the notification banner window to a hardcoded offset.
 *   - iOS 16+: the banner window is SBBannerWindow
 *   - older iOS: SBNotificationBannerWindow (resolved at runtime)
 *
 * Notification Center, the lock screen and Control Center live in other
 * SpringBoard windows and are NOT hooked by this tweak.
 *
 * Rootless build (THEOS_PACKAGE_SCHEME = rootless), injected into SpringBoard only.
 */

#import <UIKit/UIKit.h>
#import <substrate.h>

// ============================================================================
//  EDIT THESE VALUES, THEN REBUILD
// ============================================================================
// Offset in points, measured from the top-left corner of the screen.
//   X: positive moves banners right, negative moves them left
//   Y: positive moves banners down,  negative moves them up
#define BANNER_OFFSET_X  0.0
#define BANNER_OFFSET_Y  40.0
// ============================================================================

// Candidate private banner window classes, tried in order.
static NSString *const kBannerWindowClassNames[] = {
    @"SBBannerWindow",
    @"SBNotificationBannerWindow",
};

// The banner window's origin is pinned to the hardcoded offset using ABSOLUTE
// values (not "add to the current origin"). Every call therefore produces the
// same result, so repeated layout passes or re-assigned frames never stack.
static CGRect BOBannerFrame(CGRect frame) {
    frame.origin = CGPointMake(BANNER_OFFSET_X, BANNER_OFFSET_Y);
    return frame;
}

static BOOL BOBannerIsAtOffset(UIView *view) {
    CGPoint origin = view.frame.origin;
    return origin.x == BANNER_OFFSET_X && origin.y == BANNER_OFFSET_Y;
}

// ---- -initWithFrame: --------------------------------------------------------
static id (*orig_initWithFrame)(id self, SEL _cmd, CGRect frame);
static id hook_initWithFrame(id self, SEL _cmd, CGRect frame) {
    return orig_initWithFrame(self, _cmd, BOBannerFrame(frame));
}

// ---- -setFrame: -------------------------------------------------------------
static void (*orig_setFrame)(id self, SEL _cmd, CGRect frame);
static void hook_setFrame(id self, SEL _cmd, CGRect frame) {
    orig_setFrame(self, _cmd, BOBannerFrame(frame));
}

// ---- -layoutSubviews --------------------------------------------------------
static void (*orig_layoutSubviews)(id self, SEL _cmd);
static void hook_layoutSubviews(id self, SEL _cmd) {
    orig_layoutSubviews(self, _cmd);

    // Safety net for code paths that move the window without going through
    // setFrame: (for example setCenter: or setBounds:).
    UIView *view = (UIView *)self;
    if (!BOBannerIsAtOffset(view)) {
        view.frame = BOBannerFrame(view.frame);
    }
}

%ctor {
    NSString *hookedName = nil;

    for (size_t i = 0; i < sizeof(kBannerWindowClassNames) / sizeof(kBannerWindowClassNames[0]); i++) {
        Class cls = NSClassFromString(kBannerWindowClassNames[i]);
        if (!cls) {
            continue;
        }

        MSHookMessageEx(cls, @selector(initWithFrame:), (IMP)hook_initWithFrame, (IMP *)&orig_initWithFrame);
        MSHookMessageEx(cls, @selector(setFrame:), (IMP)hook_setFrame, (IMP *)&orig_setFrame);
        MSHookMessageEx(cls, @selector(layoutSubviews), (IMP)hook_layoutSubviews, (IMP *)&orig_layoutSubviews);

        hookedName = kBannerWindowClassNames[i];
        break; // Only ever hook one banner window class.
    }

    if (hookedName) {
        NSLog(@"[BannerOffset] hooked %@ at offset x=%.1f y=%.1f",
              hookedName, (double)BANNER_OFFSET_X, (double)BANNER_OFFSET_Y);
    } else {
        NSLog(@"[BannerOffset] no banner window class found on this iOS version; no changes made");
    }
}
