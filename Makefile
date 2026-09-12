ARCHS = armv7 armv7s
TARGET = iphone:clang:10.3:8.0
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = FifteenPuzzle
FifteenPuzzle_FILES = main.m FifteenPuzzleAppDelegate.m FifteenPuzzleViewController.m PuzzleBoardView.m PuzzleCore.c AppSettings.m SavedGame.m DatabaseClient.m AudioPlayerClient.m SettingsViewController.m ConfettiView.m F15Trace.m
FifteenPuzzle_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore CoreFoundation AudioToolbox
FifteenPuzzle_CFLAGS = -fobjc-arc -fno-builtin
FifteenPuzzle_USE_MODULES = 0
FifteenPuzzle_LDFLAGS = -Wl,-U,_memset -lsqlite3

include $(THEOS_MAKE_PATH)/application.mk