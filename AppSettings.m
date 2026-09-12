#import "AppSettings.h"

static NSString *const kSettingsFileName = @"settings.json";

static NSString *SettingsPath(void) {
    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                          inDomains:NSUserDomainMask] firstObject];
    return [[docs URLByAppendingPathComponent:kSettingsFileName] path];
}

@implementation AppSettings

+ (instancetype)load {
    AppSettings *settings = [[AppSettings alloc] init];
    settings.isSoundEnabled = NO;
    settings.lastBoardSize = 4;
    settings.playerName = @"Player";
    settings.autoResume = NO;

    NSData *data = [NSData dataWithContentsOfFile:SettingsPath()];
    if (data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if ([dict isKindOfClass:[NSDictionary class]]) {
            if ([dict[@"isSoundEnabled"] respondsToSelector:@selector(boolValue)]) {
                settings.isSoundEnabled = [dict[@"isSoundEnabled"] boolValue];
            }
            if ([dict[@"lastBoardSize"] respondsToSelector:@selector(integerValue)]) {
                NSInteger size = [dict[@"lastBoardSize"] integerValue];
                if (size >= 4 && size <= 13) settings.lastBoardSize = size;
            }
            if ([dict[@"playerName"] isKindOfClass:[NSString class]]) {
                settings.playerName = dict[@"playerName"];
            }
            if ([dict[@"autoResume"] respondsToSelector:@selector(boolValue)]) {
                settings.autoResume = [dict[@"autoResume"] boolValue];
            }
        }
    }
    return settings;
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