#import "SavedGame.h"

static NSString *const kSavedGameFileName = @"saved_game.json";

static NSString *SavedGamePath(void) {
    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                          inDomains:NSUserDomainMask] firstObject];
    return [[docs URLByAppendingPathComponent:kSavedGameFileName] path];
}

@implementation SavedGame

- (BOOL)loadFromDisk {
    NSData *data = [NSData dataWithContentsOfFile:SavedGamePath()];
    if (!data) return NO;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (![dict isKindOfClass:[NSDictionary class]]) return NO;

    NSArray *rawTiles = dict[@"tiles"];
    NSArray *rawHistory = dict[@"moveHistory"];
    if (![rawTiles isKindOfClass:[NSArray class]] || ![rawHistory isKindOfClass:[NSArray class]]) {
        return NO;
    }
    NSNumber *gridNum = dict[@"grid"];
    NSNumber *secondsNum = dict[@"secondsElapsed"];
    if (![gridNum respondsToSelector:@selector(integerValue)] ||
        ![secondsNum respondsToSelector:@selector(integerValue)]) {
        return NO;
    }
    NSInteger grid = [gridNum integerValue];
    if (grid < 4 || grid > 13 || rawTiles.count != (NSUInteger)(grid * grid)) {
        return NO;
    }

    self.grid = grid;
    self.secondsElapsed = [secondsNum integerValue];
    NSMutableArray<NSNumber *> *tiles = [NSMutableArray arrayWithCapacity:rawTiles.count];
    for (id value in rawTiles) {
        NSNumber *number = [value isKindOfClass:[NSNumber class]]
                               ? value
                               : ([[value description] respondsToSelector:@selector(integerValue)]
                                      ? @([[value description] integerValue])
                                      : @0);
        [tiles addObject:number];
    }
    self.tiles = tiles;
    NSMutableArray<NSNumber *> *history = [NSMutableArray arrayWithCapacity:rawHistory.count];
    for (id value in rawHistory) {
        NSNumber *number = [value isKindOfClass:[NSNumber class]]
                               ? value
                               : ([[value description] respondsToSelector:@selector(integerValue)]
                                      ? @([[value description] integerValue])
                                      : @0);
        [history addObject:number];
    }
    self.moveHistory = history;
    return YES;
}

- (BOOL)save {
    NSArray<NSNumber *> *tiles = self.tiles ?: @[];
    NSArray<NSNumber *> *history = self.moveHistory ?: @[];
    NSDictionary *dict = @{
        @"grid" : @(self.grid),
        @"secondsElapsed" : @(self.secondsElapsed),
        @"tiles" : tiles,
        @"moveHistory" : history,
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    if (!data) return NO;
    return [data writeToFile:SavedGamePath() atomically:YES];
}

- (void)clear {
    [[NSFileManager defaultManager] removeItemAtPath:SavedGamePath() error:NULL];
}

@end