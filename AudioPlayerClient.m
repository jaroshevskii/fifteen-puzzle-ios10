#import "AudioPlayerClient.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation AudioPlayerClient {
    SystemSoundID _tickSound;
    BOOL _loaded;
}

+ (instancetype)sharedClient {
    static AudioPlayerClient *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AudioPlayerClient alloc] init];
    });
    return instance;
}

- (void)ensureLoaded {
    if (_loaded) return;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"tick" withExtension:@"wav"];
    if (url) {
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_tickSound);
    }
    _loaded = YES;
}

- (void)playTick {
    [self ensureLoaded];
    if (_tickSound) {
        AudioServicesPlaySystemSound(_tickSound);
    }
}

- (void)dealloc {
    if (_tickSound) AudioServicesDisposeSystemSoundID(_tickSound);
}

@end