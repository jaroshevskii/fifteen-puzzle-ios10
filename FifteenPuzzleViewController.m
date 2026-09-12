#import "FifteenPuzzleViewController.h"
#import "PuzzleBoardView.h"
#import "PuzzleCore.h"
#import "AppSettings.h"
#import "SavedGame.h"
#import "DatabaseClient.h"
#import "AudioPlayerClient.h"
#import "SettingsViewController.h"
#import "ConfettiView.h"
#import "F15Trace.h"

static UIFont *PuzzleFont(CGFloat size, CGFloat weight) {
    return [UIFont systemFontOfSize:size weight:weight];
}

static UIColor *PuzzleOrange(void) {
    return [UIColor colorWithRed:255 / 255.0 green:161 / 255.0 blue:0 alpha:1.0];
}

@implementation FifteenPuzzleViewController {
    PuzzleBoardView *_boardView;
    UILabel *_statusLabel;
    UIButton *_minusButton;
    UIButton *_shuffleButton;
    UIButton *_restartButton;
    UIButton *_plusButton;
    UIButton *_settingsButton;
    UIView *_overlay;
    UILabel *_victoryTitle;
    UILabel *_victorySubtitle;
    ConfettiView *_confetti;
    UIView *_continueOverlay;
    UIView *_continuePanel;
    UILabel *_continueTitle;
    UILabel *_continueMessage;
    UIButton *_continueResumeButton;
    UIButton *_continueNewButton;

    int _tiles[PUZ_MAX_TILES];
    int _history[PUZ_MAX_HISTORY];
    int _historyLen;
    int _grid;
    BOOL _isGameOver;
    NSInteger _secondsElapsed;
    CFAbsoluteTime _startTime;
    NSTimer *_timer;
    PuzRng _rng;
    BOOL _started;
    BOOL _overlayVisible;

    AppSettings *_settings;
    SavedGame *_savedGame;
    BOOL _restoredFromSave;
    BOOL _didPromptForContinue;
    struct {
        NSInteger grid;
        NSInteger historyLen;
        NSInteger seconds;
    } _lastSavedSignature;
    BOOL _hasSavedSignature;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    F15Trace(@"viewDidLoad", @"start");

    _settings = [AppSettings sharedSettings];
    F15Trace(@"viewDidLoad", [NSString stringWithFormat:@"settings ok %p", (void *)_settings]);

    [[DatabaseClient sharedClient] migrateAndReturnError:NULL];
    F15Trace(@"viewDidLoad", @"migrate ok");

    __weak typeof(self) weakSelf = self;
    _boardView = [[PuzzleBoardView alloc] initWithFrame:CGRectZero tileTap:^(int index) {
        [weakSelf tileTapped:index];
    }];
    [self.view addSubview:_boardView];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.font = PuzzleFont(22.0, UIFontWeightRegular);
    [self.view addSubview:_statusLabel];

    _minusButton = [self makeActionButton:@"−" action:@selector(sizeDown:)];
    _shuffleButton = [self makeActionButton:@"Shuffle" action:@selector(shuffle:)];
    _restartButton = [self makeActionButton:@"Restart" action:@selector(restart:)];
    _plusButton = [self makeActionButton:@"+" action:@selector(sizeUp:)];
    [self.view addSubview:_minusButton];
    [self.view addSubview:_shuffleButton];
    [self.view addSubview:_restartButton];
    [self.view addSubview:_plusButton];

    _settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _settingsButton.backgroundColor = [UIColor colorWithRed:60 / 255.0 green:60 / 255.0 blue:60 / 255.0 alpha:1.0];
    [_settingsButton setTitle:@"Settings" forState:UIControlStateNormal];
    [_settingsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _settingsButton.titleLabel.font = PuzzleFont(15.0, UIFontWeightBold);
    _settingsButton.layer.cornerRadius = 6.0;
    [_settingsButton addTarget:self action:@selector(openSettings)
              forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_settingsButton];

    _overlay = [[UIView alloc] initWithFrame:CGRectZero];
    _overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    _overlay.userInteractionEnabled = YES;
    _overlay.hidden = YES;
    _overlay.alpha = 0.0;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(victoryTapped:)];
    [_overlay addGestureRecognizer:tap];

    _victoryTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    _victoryTitle.text = @"Victory!";
    _victoryTitle.textColor = [UIColor whiteColor];
    _victoryTitle.textAlignment = NSTextAlignmentCenter;
    _victoryTitle.font = PuzzleFont(60.0, UIFontWeightBold);
    [_overlay addSubview:_victoryTitle];

    _victorySubtitle = [[UILabel alloc] initWithFrame:CGRectZero];
    _victorySubtitle.textColor = [UIColor whiteColor];
    _victorySubtitle.textAlignment = NSTextAlignmentCenter;
    _victorySubtitle.font = PuzzleFont(20.0, UIFontWeightRegular);
    [_overlay addSubview:_victorySubtitle];

    _confetti = [[ConfettiView alloc] initWithFrame:CGRectZero];
    _confetti.hidden = YES;
    [_overlay addSubview:_confetti];

    [self.view addSubview:_overlay];

    _continueOverlay = [[UIView alloc] initWithFrame:CGRectZero];
    _continueOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.85];
    _continueOverlay.hidden = YES;

    _continuePanel = [[UIView alloc] initWithFrame:CGRectZero];
    _continuePanel.backgroundColor = [UIColor colorWithRed:112 / 255.0 green:31 / 255.0 blue:126 / 255.0 alpha:1.0];
    _continuePanel.layer.cornerRadius = 12.0;
    [_continueOverlay addSubview:_continuePanel];

    _continueTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    _continueTitle.text = @"Continue game?";
    _continueTitle.textColor = [UIColor whiteColor];
    _continueTitle.textAlignment = NSTextAlignmentCenter;
    _continueTitle.font = PuzzleFont(26.0, UIFontWeightBold);
    [_continuePanel addSubview:_continueTitle];

    _continueMessage = [[UILabel alloc] initWithFrame:CGRectZero];
    _continueMessage.text = @"An unfinished game was saved.";
    _continueMessage.textColor = [UIColor whiteColor];
    _continueMessage.textAlignment = NSTextAlignmentCenter;
    _continueMessage.font = PuzzleFont(16.0, UIFontWeightRegular);
    [_continuePanel addSubview:_continueMessage];

    _continueResumeButton = [self makeActionButton:@"Resume" action:@selector(resumeTapped:)];
    _continueResumeButton.backgroundColor = PuzzleOrange();
    [_continuePanel addSubview:_continueResumeButton];

    _continueNewButton = [self makeActionButton:@"New game" action:@selector(newGameTapped:)];
    _continueNewButton.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    [_continueNewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_continuePanel addSubview:_continueNewButton];

    [self.view addSubview:_continueOverlay];

    puz_rng_seed(&_rng, (uint64_t)CFAbsoluteTimeGetCurrent() * 2654435761u);

    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                           selector:@selector(timerTick:)
                                           userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    F15Trace(@"viewDidLoad", @"end");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // No UIAlertController here: the continue decision is an in-view overlay,
    // which cannot hit presentation races.
}

- (void)appWillBackground:(NSNotification *)notification {
    [self autosave];
}

#pragma mark - Game lifecycle

- (void)beginInitialGame {
    NSLog(@"[F15] beginInitialGame");
    SavedGame *loaded = [[SavedGame alloc] init];
    const BOOL hasSave = [loaded loadFromDisk];
    F15Trace(@"beginInitialGame", [NSString stringWithFormat:@"hasSave=%d grid=%ld saved=%p",
                                                           (int)hasSave, (long)loaded.grid, (void *)loaded]);
    if (hasSave) {
        _savedGame = loaded;
    } else {
        _savedGame = nil;
    }
    if (_savedGame && [self savedIsValid] && ![self savedIsSolved]) {
        _restoredFromSave = YES;
        NSLog(@"[F15] restoring saved game grid=%ld history=%lu",
              (long)_savedGame.grid, (unsigned long)_savedGame.moveHistory.count);
        [self restoreGame:_savedGame];
        if (_settings.autoResume) {
            _savedGame = nil;
            _restoredFromSave = NO; // straight into the restored game, no prompt
            NSLog(@"[F15] autoResume: jumping into restored game");
        } else {
            [self showContinueOverlay];
        }
    } else {
        if (_savedGame) {
            NSLog(@"[F15] invalid saved game, clearing");
            [_savedGame clear];
        }
        _savedGame = nil;
        [self startNewGame:_settings.lastBoardSize];
    }
    F15Trace(@"beginInitialGame", @"end");
}

- (BOOL)savedIsValid {
    if (!_savedGame) return NO;
    if (_savedGame.tiles.count != (NSUInteger)(_savedGame.grid * _savedGame.grid)) return NO;
    if (_savedGame.grid < 4 || _savedGame.grid > 13) return NO;

    BOOL seen[PUZ_MAX_TILES] = {NO};
    for (NSUInteger i = 0; i < _savedGame.tiles.count; ++i) {
        const int value = _savedGame.tiles[i].intValue;
        if (value < 0 || value >= _savedGame.grid * _savedGame.grid || seen[value]) {
            return NO; // corrupt save: not a permutation of 0..N-1
        }
        seen[value] = YES;
    }
    return YES;
}

- (BOOL)savedIsSolved {
    if (!_savedGame) return NO;
    int tiles[PUZ_MAX_TILES];
    for (NSUInteger i = 0; i < _savedGame.tiles.count; ++i) {
        tiles[i] = _savedGame.tiles[i].intValue;
    }
    return puz_is_solved(tiles, (int)_savedGame.grid);
}

- (void)restoreGame:(SavedGame *)game {
    _grid = (int)game.grid;
    NSUInteger count = game.tiles.count;
    for (NSUInteger i = 0; i < count; ++i) {
        _tiles[i] = game.tiles[i].intValue;
    }
    _historyLen = 0;
    for (NSNumber *move in game.moveHistory) {
        if (_historyLen < PUZ_MAX_HISTORY) {
            _history[_historyLen++] = move.intValue;
        }
    }
    _secondsElapsed = game.secondsElapsed;
    _startTime = CFAbsoluteTimeGetCurrent() - (CFAbsoluteTime)_secondsElapsed;
    _isGameOver = NO;
    _hasSavedSignature = NO;
    F15Trace(@"restoreGame", [NSString stringWithFormat:@"grid=%d tiles=%lu hist=%d",
                                                       (int)game.grid,
                                                       (unsigned long)game.tiles.count,
                                                       _historyLen]);
    [self layoutUI];
    [_boardView setTiles:_tiles grid:_grid animate:NO];
    [self updateStatus];
}

- (void)showContinueOverlay {
    NSLog(@"[F15] showing continue overlay");
    _didPromptForContinue = YES;
    _continueOverlay.hidden = NO;
    [self.view bringSubviewToFront:_continueOverlay];
}

- (void)resumeTapped:(UIButton *)sender {
    NSLog(@"[F15] continue: Resume");
    _restoredFromSave = NO;
    _savedGame = nil;
    _continueOverlay.hidden = YES;
}

- (void)newGameTapped:(UIButton *)sender {
    NSLog(@"[F15] continue: New game");
    _restoredFromSave = NO;
    _savedGame = nil;
    _continueOverlay.hidden = YES;
    [self startNewGame:_settings.lastBoardSize];
}

- (void)startNewGame:(int)grid {
    _grid = grid;
    puz_scramble(grid, &_rng, _tiles, &_historyLen, _history, grid * grid * 10);
    _startTime = CFAbsoluteTimeGetCurrent();
    _secondsElapsed = 0;
    _isGameOver = NO;
    _hasSavedSignature = NO;
    F15Trace(@"startNewGame", [NSString stringWithFormat:@"grid=%d", grid]);
    [self setOverlayHidden:YES];
    [_boardView setTiles:_tiles grid:_grid animate:NO];
    [self layoutUI];
    [self updateStatus];
}

- (void)autosave {
    if (!_started || _isGameOver) return;
    if (_hasSavedSignature && _lastSavedSignature.grid == _grid &&
        _lastSavedSignature.historyLen == _historyLen &&
        _lastSavedSignature.seconds == _secondsElapsed) {
        return;
    }
    SavedGame *game = [[SavedGame alloc] init];
    game.grid = _grid;
    game.secondsElapsed = _secondsElapsed;
    NSMutableArray<NSNumber *> *tiles = [NSMutableArray arrayWithCapacity:_grid * _grid];
    for (int i = 0; i < _grid * _grid; ++i) {
        [tiles addObject:@(_tiles[i])];
    }
    game.tiles = tiles;
    NSMutableArray<NSNumber *> *history = [NSMutableArray arrayWithCapacity:_historyLen];
    for (int i = 0; i < _historyLen; ++i) {
        [history addObject:@(_history[i])];
    }
    game.moveHistory = history;
    [game save];

    _lastSavedSignature.grid = _grid;
    _lastSavedSignature.historyLen = _historyLen;
    _lastSavedSignature.seconds = _secondsElapsed;
    _hasSavedSignature = YES;
}

- (void)submitVictoryAndClearSave {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        ScoreSubmission *submission = [[ScoreSubmission alloc] init];
        submission.name = _settings.playerName;
        submission.gridSize = _grid;
        submission.moves = _historyLen;
        submission.duration = (NSInteger)(CFAbsoluteTimeGetCurrent() - _startTime);
        submission.playedAt = [[NSDate date] timeIntervalSince1970];
        [[DatabaseClient sharedClient] saveGame:submission error:NULL];
    });
    SavedGame *saveFile = [[SavedGame alloc] init];
    [saveFile clear];
    _savedGame = nil;
    _hasSavedSignature = NO;
}

- (void)tileTapped:(int)index {
    if (_isGameOver) {
        [self startNewGame:_grid];
        return;
    }
    if (puz_slide(_tiles, _history, &_historyLen, _grid, index)) {
        [_boardView setTiles:_tiles grid:_grid animate:YES];
        [self updateStatus];
        if (puz_is_solved(_tiles, _grid)) {
            [self onVictory];
        } else {
            [self autosave];
        }
    }
}

- (void)onVictory {
    _isGameOver = YES;
    const NSInteger duration = MAX(0, (NSInteger)(CFAbsoluteTimeGetCurrent() - _startTime));
    _victorySubtitle.text = [NSString stringWithFormat:@"%02ld:%02ld   %ld moves",
                                                       (long)(duration / 60), (long)(duration % 60),
                                                       (long)_historyLen];
    [self updateStatus];
    [self submitVictoryAndClearSave];
    [self setOverlayHidden:NO];
}

#pragma mark - Actions

- (void)shuffle:(id)sender {
    if (_isGameOver) {
        [self startNewGame:_grid];
        return;
    }
    puz_scramble(_grid, &_rng, _tiles, &_historyLen, _history, _grid * _grid * 10);
    [_boardView setTiles:_tiles grid:_grid animate:YES];
    [self autosave];
}

- (void)restart:(id)sender {
    [self startNewGame:_grid];
}

- (void)sizeDown:(id)sender {
    if (_grid > 4) [self startNewGame:_grid - 1];
}

- (void)sizeUp:(id)sender {
    if (_grid < 13) [self startNewGame:_grid + 1];
}

- (void)victoryTapped:(UITapGestureRecognizer *)recognizer {
    [self startNewGame:_grid];
}

- (void)openSettings {
    SettingsViewController *vc = [[SettingsViewController alloc] initWithSettings:_settings];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.navigationBar.barStyle = UIBarStyleBlack;
    nav.navigationBar.tintColor = PuzzleOrange();
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)setOverlayHidden:(BOOL)hidden {
    if (hidden) {
        [_confetti stopRain];
        _confetti.hidden = YES;
    } else {
        _overlay.hidden = NO;
        _confetti.frame = _overlay.bounds;
        _confetti.hidden = NO;
        [_confetti startRain];
    }
    _overlayVisible = !hidden;
    [UIView animateWithDuration:0.25 animations:^{
        _overlay.alpha = hidden ? 0.0 : 1.0;
    } completion:^(BOOL finished) {
        _overlay.hidden = hidden;
    }];
}

#pragma mark - Timer & status

- (void)timerTick:(NSTimer *)timer {
    if (!_started || _isGameOver) return;
    static BOOL s_firstTick;
    if (!s_firstTick) {
        s_firstTick = YES;
        F15Trace(@"timer", [NSString stringWithFormat:@"first tick settings=%p saved=%p",
                                                      (void *)_settings, (void *)_savedGame]);
    }
    const NSInteger seconds = (NSInteger)(CFAbsoluteTimeGetCurrent() - _startTime);
    if (seconds != _secondsElapsed) {
        _secondsElapsed = seconds;
        if (_settings && _settings.isSoundEnabled) {
            [[AudioPlayerClient sharedClient] playTick];
        }
        [self updateStatus];
        [self autosave];
    }
}

- (void)updateStatus {
    const long total = (long)_secondsElapsed;
    NSString *label = [NSString stringWithFormat:@"%02ld:%02ld:%02ld   %dx%d",
                                                 total / 3600, (total % 3600) / 60, total % 60,
                                                 _grid, _grid];
    _statusLabel.text = _isGameOver ? [@"Victory Time " stringByAppendingString:label] : label;
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    static int s_layoutCalls;
    s_layoutCalls++;
    if (s_layoutCalls <= 3 || (s_layoutCalls % 500) == 0) {
        F15Trace(@"viewDidLayoutSubviews", [NSString stringWithFormat:@"call=%d", s_layoutCalls]);
    }
    [self layoutUI];
    if (!_started) {
        _started = YES;
        F15Trace(@"viewDidLayoutSubviews", @"beginInitialGame");
        [self beginInitialGame];
    }
}

- (void)layoutUI {
    const CGRect bounds = self.view.bounds;
    const CGFloat sw = bounds.size.width;
    const CGFloat sh = bounds.size.height;
    const CGFloat statusH = 44.0;
    const CGFloat buttonH = 44.0;
    const CGFloat gap = 20.0;
    const int grid = _grid > 0 ? _grid : 4;

    const CGFloat usableH = sh - statusH - gap - buttonH - gap;
    const CGFloat available = MIN(sw, usableH) * 0.92;
    const CGFloat tile = MIN(120.0, available / (CGFloat)grid);
    const CGFloat boardSize = tile * (CGFloat)grid;

    _boardView.frame = CGRectMake((sw - boardSize) / 2.0,
                                  (usableH - boardSize) / 2.0 + gap,
                                  boardSize, boardSize);
    _statusLabel.frame = CGRectMake(0, CGRectGetMaxY(_boardView.frame) + 8.0, sw, statusH);

    const CGFloat margin = 24.0;
    const CGFloat spacing = 12.0;
    const CGFloat buttonWidth = (sw - margin * 2.0 - spacing * 3.0) / 4.0;
    const CGFloat y = sh - gap - buttonH;
    CGFloat x = margin;
    NSArray *buttons = @[ _minusButton, _shuffleButton, _restartButton, _plusButton ];
    for (UIButton *button in buttons) {
        button.frame = CGRectMake(x, y, buttonWidth, buttonH);
        x += buttonWidth + spacing;
    }

    _settingsButton.frame = CGRectMake(sw - 108.0, 8.0, 96.0, 40.0);

    _overlay.frame = bounds;
    _victoryTitle.frame = CGRectMake(0, sh / 2.0 - 76.0, sw, 70.0);
    _victorySubtitle.frame = CGRectMake(0, sh / 2.0 + 12.0, sw, 30.0);
    _confetti.frame = bounds;

    _continueOverlay.frame = bounds;
    const CGFloat panelW = MIN(sw - 64.0, 360.0);
    const CGFloat panelH = 220.0;
    _continuePanel.frame = CGRectMake((sw - panelW) / 2.0, (sh - panelH) / 2.0,
                                      panelW, panelH);
    _continueTitle.frame = CGRectMake(16, 28, panelW - 32, 34);
    _continueMessage.frame = CGRectMake(16, 70, panelW - 32, 24);
    const CGFloat buttonGap = 12.0;
    const CGFloat buttonW = (panelW - 32.0 - buttonGap) / 2.0;
    _continueResumeButton.frame = CGRectMake(16, 124, buttonW, 48);
    _continueNewButton.frame = CGRectMake(16 + buttonW + buttonGap, 124, buttonW, 48);

    if (_started && _grid > 0) {
        [_boardView setTiles:_tiles grid:_grid animate:NO];
    }
    static int s_layoutCount;
    s_layoutCount++;
    if (s_layoutCount <= 3 || (s_layoutCount % 500) == 0) {
        F15Trace(@"layoutUI", [NSString stringWithFormat:@"count=%d grid=%d", s_layoutCount, _grid]);
    }
}

- (UIButton *)makeActionButton:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = PuzzleOrange();
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.titleLabel.font = PuzzleFont(18.0, UIFontWeightBold);
    button.layer.cornerRadius = 4.0;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end