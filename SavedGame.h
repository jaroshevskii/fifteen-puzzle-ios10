#import <Foundation/Foundation.h>

@interface SavedGame : NSObject
@property (nonatomic) NSInteger grid;
@property (nonatomic) NSInteger secondsElapsed;
@property (nonatomic, copy) NSArray<NSNumber *> *tiles;
@property (nonatomic, copy) NSArray<NSNumber *> *moveHistory;
+ (instancetype)load;
- (BOOL)save;
- (void)clear;
@end