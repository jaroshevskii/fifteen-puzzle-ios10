#import "FifteenPuzzleAppDelegate.h"
#import "FifteenPuzzleViewController.h"

@implementation FifteenPuzzleAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[FifteenPuzzleViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end