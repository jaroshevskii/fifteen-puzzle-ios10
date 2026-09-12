ARCHS = armv7 armv7s
TARGET = iphone:clang:10.3:8.0
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = FifteenPuzzle
FifteenPuzzle_FILES = main.m FifteenPuzzleAppDelegate.m FifteenPuzzleViewController.m PuzzleBoardView.m PuzzleCore.c
FifteenPuzzle_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore CoreFoundation
FifteenPuzzle_CFLAGS = -fobjc-arc -fno-builtin
FifteenPuzzle_USE_MODULES = 0
FifteenPuzzle_LDFLAGS = -Wl,-U,_memset

include $(THEOS_MAKE_PATH)/application.mk