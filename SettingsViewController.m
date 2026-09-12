#import "SettingsViewController.h"

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) AppSettings *settings;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak) UILabel *sizeValueLabel;
@property (nonatomic, weak) UIStepper *sizeStepper;
@end

@implementation SettingsViewController

- (instancetype)initWithSettings:(AppSettings *)settings {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _settings = settings;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    self.view.backgroundColor = [UIColor whiteColor];

    UIBarButtonItem *done = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                             target:self
                             action:@selector(doneTapped)];
    self.navigationItem.rightBarButtonItem = done;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                  style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
}

- (void)doneTapped {
    [self.view endEditing:YES];
    [self.settings save];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Game" : @"Player";
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:@"cell"];
    }
    cell.textLabel.font = [UIFont systemFontOfSize:17.0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Sound";
            UISwitch *toggle = [[UISwitch alloc] init];
            toggle.on = self.settings.isSoundEnabled;
            [toggle addTarget:self action:@selector(soundChanged:)
             forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
        } else {
            cell.textLabel.text = @"Board size";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld×%ld",
                                                                   (long)self.settings.lastBoardSize,
                                                                   (long)self.settings.lastBoardSize];
            self.sizeValueLabel = cell.detailTextLabel;
            UIStepper *stepper = [[UIStepper alloc] init];
            stepper.minimumValue = 4.0;
            stepper.maximumValue = 13.0;
            stepper.stepValue = 1.0;
            stepper.value = self.settings.lastBoardSize;
            [stepper addTarget:self action:@selector(sizeChanged:)
              forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = stepper;
            self.sizeStepper = stepper;
        }
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Player name";
            UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 140, 30)];
            field.borderStyle = UITextBorderStyleRoundedRect;
            field.textAlignment = NSTextAlignmentRight;
            field.font = [UIFont systemFontOfSize:17.0];
            field.returnKeyType = UIReturnKeyDone;
            field.autocapitalizationType = UITextAutocapitalizationTypeWords;
            field.text = self.settings.playerName;
            field.delegate = self;
            [field addTarget:self action:@selector(nameChanged:)
           forControlEvents:UIControlEventEditingChanged];
            cell.accessoryView = field;
        } else {
            cell.textLabel.text = @"Auto-resume game";
            UISwitch *toggle = [[UISwitch alloc] init];
            toggle.on = self.settings.autoResume;
            [toggle addTarget:self action:@selector(autoResumeChanged:)
             forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
        }
    }
    return cell;
}

#pragma mark - Actions

- (void)soundChanged:(UISwitch *)toggle {
    self.settings.isSoundEnabled = toggle.on;
    [self.settings save];
}

- (void)autoResumeChanged:(UISwitch *)toggle {
    self.settings.autoResume = toggle.on;
    [self.settings save];
}

- (void)sizeChanged:(UIStepper *)stepper {
    self.settings.lastBoardSize = (NSInteger)stepper.value;
    self.sizeValueLabel.text = [NSString stringWithFormat:@"%ld×%ld",
                                                          (long)self.settings.lastBoardSize,
                                                          (long)self.settings.lastBoardSize];
    [self.settings save];
}

- (void)nameChanged:(UITextField *)field {
    self.settings.playerName = field.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end