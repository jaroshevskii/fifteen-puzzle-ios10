#import <Foundation/Foundation.h>

@interface SavedGame : NSObject
@property (nonatomic) NSInteger grid;
@property (nonatomic) NSInteger secondsElapsed;
@property (nonatomic, copy) NSArray<NSNumber *> *tiles;
@property (nonatomic, copy) NSArray<NSNumber *> *moveHistory;
- (BOOL)loadFromDisk;
- (BOOL)save;
- (void)clear;
@end