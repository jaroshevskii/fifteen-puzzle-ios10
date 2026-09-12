#import "AppSettings.h"

static NSString *const kSettingsFileName = @"settings.json";

static NSString *SettingsPath(void) {
    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                          inDomains:NSUserDomainMask] firstObject];
    return [[docs URLByAppendingPathComponent:kSettingsFileName] path];
}

@implementation AppSettings

+ (instancetype)sharedSettings {
    static AppSettings *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AppSettings alloc] init];
        shared.isSoundEnabled = NO;
        shared.lastBoardSize = 4;
        shared.playerName = @"Player";
        shared.autoResume = NO;
        [shared reloadFromDisk];
    });
    return shared;
}

- (void)reloadFromDisk {
    NSData *data = [NSData dataWithContentsOfFile:SettingsPath()];
    if (!data) return;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (![dict isKindOfClass:[NSDictionary class]]) return;
    if ([dict[@"isSoundEnabled"] respondsToSelector:@selector(boolValue)]) {
        self.isSoundEnabled = [dict[@"isSoundEnabled"] boolValue];
    }
    if ([dict[@"lastBoardSize"] respondsToSelector:@selector(integerValue)]) {
        NSInteger size = [dict[@"lastBoardSize"] integerValue];
        if (size >= 4 && size <= 13) self.lastBoardSize = size;
    }
    if ([dict[@"playerName"] isKindOfClass:[NSString class]]) {
        self.playerName = dict[@"playerName"];
    }
    if ([dict[@"autoResume"] respondsToSelector:@selector(boolValue)]) {
        self.autoResume = [dict[@"autoResume"] boolValue];
    }
}

- (void)save {
    NSDictionary *dict = @{
        @"isSoundEnabled" : @(self.isSoundEnabled),
        @"lastBoardSize" : @(self.lastBoardSize),
        @"playerName" : self.playerName ?: @"Player",
        @"autoResume" : @(self.autoResume),
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted
                                                    error:NULL];
    if (data) {
        [data writeToFile:SettingsPath() atomically:YES];
    }
}

@end