//
//  EditorScene.h
//  Shikaku Madness
//
//  Created by Nathan Demick on 3/22/12.
//  Copyright 2012 Ganbaru Games. All rights reserved.
//

#import "RoundRectNode.h"
#import "Clue.h"
#import "SimpleAudioEngine.h"
#import "TitleScene.h"
#import "GameSingleton.h"

@interface EditorScene : CCLayer 
{
    // This'll hold the loaded level
    NSArray *level;
    
    // Display/store player moves and puzzle clues
    NSMutableArray *squares, *clues;
    RoundRectNode *selection;
    
    // Stores info about grid
    int blockSize, gridSize;
    
    // Stores info about player input
    CGPoint touchStart, touchPrevious;
    int touchRow, touchCol, startRow, startCol, previousRow, previousCol;
    
    // Labels for giving player information
    CCLabelTTF *areaLabel, *timerLabel;
    
    // Store coord crap
    CGSize window;
    CGPoint offset;
    
    // Info about platform
    NSString *iPadSuffix;
    int fontMultiplier;
}

// returns a CCScene that contains the GameScene as the only child
+ (CCScene *)scene;
- (BOOL)saveLevel;
- (NSString *)createUUID;
- (BOOL)checkSolution;

@end
