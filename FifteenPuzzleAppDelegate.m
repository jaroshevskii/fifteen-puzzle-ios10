#import "FifteenPuzzleAppDelegate.h"
#import "FifteenPuzzleViewController.h"
#import "F15Trace.h"
#import <execinfo.h>

static NSString *F15CrashLogPath(void) {
    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                          inDomains:NSUserDomainMask] firstObject];
    return [[docs URLByAppendingPathComponent:@"crash.log"] path];
}

static void F15WriteCrash(const char *tag, NSString *details) {
    NSLog(@"[F15CRASH][%s] %@", tag, details);
    @autoreleasepool {
        NSString *line = [NSString stringWithFormat:@"\n[%@] %@", [NSDate date], details];
        NSFileHandle *handle =
            [NSFileHandle fileHandleForWritingAtPath:F15CrashLogPath()];
        if (!handle) {
            [[NSFileManager defaultManager] createFileAtPath:F15CrashLogPath()
                                                    contents:nil
                                                  attributes:nil];
            handle = [NSFileHandle fileHandleForWritingAtPath:F15CrashLogPath()];
        }
        if (handle) {
            @try {
                [handle seekToEndOfFile];
                [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
                [handle closeFile];
            } @catch (NSException *exception) {
            }
        } else {
            [[line dataUsingEncoding:NSUTF8StringEncoding] writeToFile:F15CrashLogPath()
                                                           atomically:YES];
        }
    }
}

static void F15UncaughtExceptionHandler(NSException *exception) {
    NSString *details = [NSString stringWithFormat:@"EXCEPTION %@: %@\n%@", exception.name,
                                                   exception.reason,
                                                   [exception.callStackSymbols componentsJoinedByString:@"\n"]];
    F15WriteCrash("exception", details);
}

static void F15SignalHandler(int sig) {
    void *frames[128];
    const int count = backtrace(frames, 128);
    char **symbols = backtrace_symbols(frames, count);
    NSMutableString *stack = [NSMutableString string];
    for (int i = 0; i < count; ++i) {
        [stack appendFormat:@"%s\n", symbols[i]];
    }
    F15WriteCrash("signal", [NSString stringWithFormat:@"SIGNAL %d\n%@", sig, stack]);
    free(symbols);
    _exit(sig);
}

static void F15InstallCrashHandlers(void) {
    NSSetUncaughtExceptionHandler(&F15UncaughtExceptionHandler);
    signal(SIGABRT, F15SignalHandler);
    signal(SIGBUS, F15SignalHandler);
    signal(SIGSEGV, F15SignalHandler);
    signal(SIGILL, F15SignalHandler);
    signal(SIGFPE, F15SignalHandler);
}

@implementation FifteenPuzzleAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    F15Trace(@"app", @"launching");
    NSLog(@"[F15] app launching");
    F15InstallCrashHandlers();
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[FifteenPuzzleViewController alloc] init];
    [self.window makeKeyAndVisible];
    F15Trace(@"app", @"launched");
    NSLog(@"[F15] app did finish launching");
    return YES;
}

@end