#import <Foundation/Foundation.h>

@interface ScoreSubmission : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger gridSize;
@property (nonatomic) NSInteger moves;
@property (nonatomic) NSInteger duration;
@property (nonatomic) NSTimeInterval playedAt;
@end

@interface LeaderboardEntry : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger gridSize;
@property (nonatomic) NSInteger moves;
@property (nonatomic) NSInteger duration;
@property (nonatomic) NSTimeInterval playedAt;
@end

@interface Stats : NSObject
@property (nonatomic) NSInteger gamesPlayed;
@property (nonatomic) NSInteger bestDurationSeconds;
@property (nonatomic) NSTimeInterval totalSeconds;
@end

@interface DatabaseClient : NSObject
+ (instancetype)sharedClient;
- (BOOL)migrateAndReturnError:(NSError **)error;
- (BOOL)saveGame:(ScoreSubmission *)submission error:(NSError **)error;
- (NSArray<LeaderboardEntry *> *)fetchBestScoresForGrid:(NSInteger)grid error:(NSError **)error;
- (Stats *)fetchStatsWithError:(NSError **)error;
@end