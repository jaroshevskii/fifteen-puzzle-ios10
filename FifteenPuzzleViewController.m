#import "FifteenPuzzleViewController.h"
#import "PuzzleBoardView.h"
#import "PuzzleCore.h"

static UIFont *PuzzleMonoFont(CGFloat size) {
    return [UIFont fontWithName:@"Menlo-Bold" size:size] ?: [UIFont boldSystemFontOfSize:size];
}

@implementation FifteenPuzzleViewController {
    PuzzleBoardView *_boardView;
    UILabel *_statusLabel;
    UIButton *_minusButton;
    UIButton *_shuffleButton;
    UIButton *_restartButton;
    UIButton *_plusButton;
    UIView *_overlay;
    UILabel *_victoryTitle;
    UILabel *_victorySubtitle;

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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    __weak typeof(self) weakSelf = self;
    _boardView = [[PuzzleBoardView alloc] initWithFrame:CGRectZero tileTap:^(int index) {
        [weakSelf tileTapped:index];
    }];
    [self.view addSubview:_boardView];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.font = PuzzleMonoFont(22.0);
    [self.view addSubview:_statusLabel];

    _minusButton = [self makeActionButton:@"−"];
    _shuffleButton = [self makeActionButton:@"Shuffle"];
    _restartButton = [self makeActionButton:@"Restart"];
    _plusButton = [self makeActionButton:@"+"];
    [_minusButton addTarget:self action:@selector(sizeDown:) forControlEvents:UIControlEventTouchUpInside];
    [_shuffleButton addTarget:self action:@selector(shuffle:) forControlEvents:UIControlEventTouchUpInside];
    [_restartButton addTarget:self action:@selector(restart:) forControlEvents:UIControlEventTouchUpInside];
    [_plusButton addTarget:self action:@selector(sizeUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_minusButton];
    [self.view addSubview:_shuffleButton];
    [self.view addSubview:_restartButton];
    [self.view addSubview:_plusButton];

    _overlay = [[UIView alloc] initWithFrame:CGRectZero];
    _overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75]; // 192/255
    _overlay.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(victoryTapped:)];
    [_overlay addGestureRecognizer:tap];

    _victoryTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    _victoryTitle.text = @"Victory!";
    _victoryTitle.textColor = [UIColor whiteColor];
    _victoryTitle.textAlignment = NSTextAlignmentCenter;
    _victoryTitle.font = PuzzleMonoFont(60.0);
    [_overlay addSubview:_victoryTitle];

    _victorySubtitle = [[UILabel alloc] initWithFrame:CGRectZero];
    _victorySubtitle.text = @"Tap to play again.";
    _victorySubtitle.textColor = [UIColor whiteColor];
    _victorySubtitle.textAlignment = NSTextAlignmentCenter;
    _victorySubtitle.font = PuzzleMonoFont(20.0);
    [_overlay addSubview:_victorySubtitle];

    [self.view addSubview:_overlay];
    _overlay.hidden = YES;

    puz_rng_seed(&_rng, (uint64_t)CFAbsoluteTimeGetCurrent() * 2654435761u);

    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                           selector:@selector(timerTick:)
                                           userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutUI];
    if (!_started) {
        _started = YES;
        _grid = PUZ_MIN_GRID;
        [self startNewGame:_grid];
    }
}

- (void)layoutUI {
    const CGRect bounds = self.view.bounds;
    const CGFloat sw = bounds.size.width;
    const CGFloat sh = bounds.size.height;
    const CGFloat statusH = 44.0;
    const CGFloat buttonH = 44.0;
    const CGFloat gap = 20.0;

    const CGFloat usableH = sh - statusH - gap - buttonH - gap;
    const CGFloat available = MIN(sw, usableH) * 0.92;
    const CGFloat tile = MIN(120.0, available / (CGFloat)_grid);
    const CGFloat boardSize = tile * (CGFloat)_grid;

    _boardView.frame = CGRectMake((sw - boardSize) / 2.0,
                                  (usableH - boardSize) / 2.0 + gap,
                                  boardSize, boardSize);
    _statusLabel.frame = CGRectMake(0, CGRectGetMaxY(_boardView.frame) + 8.0, sw, statusH);

    const CGFloat margin = 24.0;
    const CGFloat spacing = 12.0;
    const CGFloat totalSpacing = spacing * 3.0;
    const CGFloat buttonWidth = (sw - margin * 2.0 - totalSpacing) / 4.0;
    const CGFloat y = sh - gap - buttonH;
    CGFloat x = margin;
    for (UIButton *button in @[_minusButton, _shuffleButton, _restartButton, _plusButton]) {
        button.frame = CGRectMake(x, y, buttonWidth, buttonH);
        x += buttonWidth + spacing;
    }

    _overlay.frame = bounds;
    _victoryTitle.frame = CGRectMake(0, sh / 2.0 - 76.0, sw, 70.0);
    _victorySubtitle.frame = CGRectMake(0, sh / 2.0 + 12.0, sw, 30.0);

    if (_started) {
        [_boardView setTiles:_tiles grid:_grid animate:NO];
    }
}

- (UIButton *)makeActionButton:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = PuzzleOrange();
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.titleLabel.font = PuzzleMonoFont(18.0);
    button.layer.cornerRadius = 4.0;
    return button;
}

static UIColor *PuzzleOrange(void) {
    return [UIColor colorWithRed:255 / 255.0 green:161 / 255.0 blue:0 alpha:1.0];
}

- (void)startNewGame:(int)grid {
    _grid = grid;
    puz_scramble(grid, &_rng, _tiles, _history, &_historyLen, grid * grid * 10);
    _startTime = CFAbsoluteTimeGetCurrent();
    _secondsElapsed = 0;
    _isGameOver = NO;
    [self setOverlayHidden:YES];
    [_boardView setTiles:_tiles grid:_grid animate:NO];
    [self layoutUI];
    [self updateStatus];
}

- (void)tileTapped:(int)index {
    if (_isGameOver) {
        [self startNewGame:_grid];
        return;
    }
    if (puz_slide(_tiles, _history, &_historyLen, _grid, index)) {
        [_boardView setTiles:_tiles grid:_grid animate:YES];
        if (puz_is_solved(_tiles, _grid)) {
            _isGameOver = YES;
            [self updateStatus];
            [self setOverlayHidden:NO];
        } else {
            [self updateStatus];
        }
    }
}

- (void)shuffle:(id)sender {
    if (_isGameOver) {
        [self startNewGame:_grid];
        return;
    }
    puz_scramble(_grid, &_rng, _tiles, _history, &_historyLen, _grid * _grid * 10);
    [_boardView setTiles:_tiles grid:_grid animate:YES];
}

- (void)restart:(id)sender {
    [self startNewGame:_grid];
}

- (void)sizeDown:(id)sender {
    if (_grid > PUZ_MIN_GRID) [self startNewGame:_grid - 1];
}

- (void)sizeUp:(id)sender {
    if (_grid < PUZ_MAX_GRID) [self startNewGame:_grid + 1];
}

- (void)victoryTapped:(UITapGestureRecognizer *)recognizer {
    [self startNewGame:_grid];
}

- (void)setOverlayHidden:(BOOL)hidden {
    if (_overlayVisible == hidden) {
        _overlay.hidden = hidden;
    }
    _overlayVisible = !hidden;
    [UIView animateWithDuration:0.25 animations:^{
        _overlay.alpha = _overlayVisible ? 1.0 : 0.0;
    } completion:^(BOOL finished) {
        _overlay.hidden = !_overlayVisible;
    }];
}

- (void)timerTick:(NSTimer *)timer {
    if (_isGameOver || !_started) return;
    const NSInteger seconds = (NSInteger)(CFAbsoluteTimeGetCurrent() - _startTime);
    if (seconds != _secondsElapsed) {
        _secondsElapsed = seconds;
        [self updateStatus];
    }
}

- (void)updateStatus {
    const long total = (long)_secondsElapsed;
    NSString *label = [NSString stringWithFormat:@"%02ld:%02ld:%02ld   %dx%d",
                                                 total / 3600, (total % 3600) / 60, total % 60,
                                                 _grid, _grid];
    _statusLabel.text = _isGameOver ? [@"Victory Time " stringByAppendingString:label] : label;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc {
    [_timer invalidate];
}

@end