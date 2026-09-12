#import "DatabaseClient.h"
#import <sqlite3.h>

static NSString *DatabasePath(void) {
    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                          inDomains:NSUserDomainMask] firstObject];
    return [[docs URLByAppendingPathComponent:@"FifteenPuzzle.sqlite"] path];
}

static NSError *DbError(NSString *message) {
    return [NSError errorWithDomain:@"com.example.fifteenpuzzle.db"
                               code:-1
                           userInfo:@{NSLocalizedDescriptionKey : message}];
}

@implementation ScoreSubmission
@end

@implementation LeaderboardEntry
@end

@implementation Stats
@end

@implementation DatabaseClient {
    sqlite3 *_db;
}

+ (instancetype)sharedClient {
    static DatabaseClient *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DatabaseClient alloc] init];
    });
    return instance;
}

- (void)dealloc {
    if (_db) sqlite3_close(_db);
}

- (sqlite3 *)openDbReturningError:(NSError **)error {
    if (_db) return _db;
    sqlite3 *db = NULL;
    if (sqlite3_open([DatabasePath() UTF8String], &db) != SQLITE_OK) {
        if (db) sqlite3_close(db);
        if (error) *error = DbError(@"Could not open database");
        return NULL;
    }
    _db = db;
    return db;
}

- (BOOL)migrateAndReturnError:(NSError **)error {
    sqlite3 *db = [self openDbReturningError:error];
    if (!db) return NO;
    const char *schema =
        "CREATE TABLE IF NOT EXISTS games ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "name TEXT NOT NULL,"
        "gridSize INTEGER NOT NULL,"
        "moves INTEGER NOT NULL,"
        "duration INTEGER NOT NULL,"
        "playedAt REAL NOT NULL);";
    char *errMsg = NULL;
    if (sqlite3_exec(db, schema, NULL, NULL, &errMsg) != SQLITE_OK) {
        if (error) *error = DbError([NSString stringWithUTF8String:errMsg ?: "migration failed"]);
        sqlite3_free(errMsg);
        return NO;
    }
    return YES;
}

- (BOOL)saveGame:(ScoreSubmission *)submission error:(NSError **)error {
    sqlite3 *db = [self openDbReturningError:error];
    if (!db) return NO;
    static const char *sql =
        "INSERT INTO games (name, gridSize, moves, duration, playedAt) VALUES (?, ?, ?, ?, ?);";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK) {
        if (error) *error = DbError(@"Could not prepare insert");
        return NO;
    }
    sqlite3_bind_text(stmt, 1, [submission.name ?: @"Player" UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(stmt, 2, (int)submission.gridSize);
    sqlite3_bind_int(stmt, 3, (int)submission.moves);
    sqlite3_bind_int(stmt, 4, (int)submission.duration);
    sqlite3_bind_double(stmt, 5, submission.playedAt);
    const BOOL ok = sqlite3_step(stmt) == SQLITE_DONE;
    sqlite3_finalize(stmt);
    if (!ok && error) *error = DbError(@"Could not insert game");
    return ok;
}

- (NSArray<LeaderboardEntry *> *)fetchBestScoresForGrid:(NSInteger)grid error:(NSError **)error {
    sqlite3 *db = [self openDbReturningError:error];
    if (!db) return nil;
    static const char *sql =
        "SELECT name, gridSize, moves, duration, playedAt FROM games "
        "WHERE gridSize = ? ORDER BY duration ASC, playedAt ASC LIMIT 10;";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK) {
        if (error) *error = DbError(@"Could not prepare select");
        return nil;
    }
    sqlite3_bind_int(stmt, 1, (int)grid);
    NSMutableArray<LeaderboardEntry *> *result = [NSMutableArray array];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        LeaderboardEntry *entry = [[LeaderboardEntry alloc] init];
        const unsigned char *name = sqlite3_column_text(stmt, 0);
        entry.name = name ? [NSString stringWithUTF8String:(const char *)name] : @"Player";
        entry.gridSize = sqlite3_column_int(stmt, 1);
        entry.moves = sqlite3_column_int(stmt, 2);
        entry.duration = sqlite3_column_int(stmt, 3);
        entry.playedAt = sqlite3_column_double(stmt, 4);
        [result addObject:entry];
    }
    sqlite3_finalize(stmt);
    return result;
}

- (Stats *)fetchStatsWithError:(NSError **)error {
    sqlite3 *db = [self openDbReturningError:error];
    if (!db) return nil;
    static const char *sql = "SELECT COUNT(*), IFNULL(MIN(duration), 0), IFNULL(SUM(duration), 0) "
                             "FROM games;";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK) {
        if (error) *error = DbError(@"Could not prepare stats");
        return nil;
    }
    Stats *stats = [[Stats alloc] init];
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        stats.gamesPlayed = sqlite3_column_int(stmt, 0);
        stats.bestDurationSeconds = sqlite3_column_int(stmt, 1);
        stats.totalSeconds = sqlite3_column_double(stmt, 2);
    }
    sqlite3_finalize(stmt);
    return stats;
}

@end