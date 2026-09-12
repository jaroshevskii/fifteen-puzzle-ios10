#import "F15Trace.h"

static NSString *F15TracePath(void) {
    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                          inDomains:NSUserDomainMask] firstObject];
    return [[docs URLByAppendingPathComponent:@"trace.log"] path];
}

void F15Trace(NSString *tag, NSString *detail) {
    static NSLock *lock;
    static int lines;
    static BOOL capped;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        lock = [[NSLock alloc] init];
        [[NSFileManager defaultManager] removeItemAtPath:F15TracePath() error:NULL];
    });
    if (capped) return;
    [lock lock];
    lines++;
    if (lines > 4000) {
        capped = YES;
        [lock unlock];
        return;
    }
    NSString *line = [NSString stringWithFormat:@"[%@] %@ %@\n",
                                                 [NSDate date], tag, detail ?: @""];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:F15TracePath()];
    if (!handle) {
        [[NSData data] writeToFile:F15TracePath() atomically:NO];
        handle = [NSFileHandle fileHandleForWritingAtPath:F15TracePath()];
    }
    if (handle) {
        @try {
            [handle seekToEndOfFile];
            [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        } @catch (NSException *exception) {
        }
    }
    [lock unlock];
}