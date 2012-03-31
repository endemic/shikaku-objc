//
//  GameScene.m
//  Shikaku Madness
//
//  Created by Nathan Demick on 3/18/12.
//  Copyright Ganbaru Games 2012. All rights reserved.
//


// Import the interfaces
#import "GameScene.h"

// GameScene implementation
@implementation GameScene

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameScene *layer = [GameScene node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
        // Get window size
        window = [CCDirector sharedDirector].winSize;
        
        // Determine offset of grid
        if ([GameSingleton sharedGameSingleton].isPad)
        {
            iPadOffset = ccp(32, 16);
            // Determine offset of grid
            offset = ccp(32, 66);
            blockSize = 64;
            iPadSuffix = @"-ipad";
            fontMultiplier = 2;
        }
        else 
        {
            iPadOffset = ccp(0, 0);
            offset = ccp(0, 25);
            blockSize = 32;
            iPadSuffix = @"";
            fontMultiplier = 1;
        }
        
        gridSize = 10;
        
        [self setIsTouchEnabled:YES];
        
        // Set up the array that will hold player "moves"
        squares = [[[NSMutableArray alloc] init] retain];
        clues = [[[NSMutableArray alloc] init] retain];
        
        // Set up the sprite that will show the player's current move
        selection = [RoundRectNode initWithRectSize:CGSizeMake(blockSize, blockSize)];
        [self addChild:selection z:1];
        selection.visible = NO;
        
        // Add background
		CCSprite *background = [CCSprite spriteWithFile:@"background.png"];
        background.position = ccp(window.width / 2, window.height / 2);
        [self addChild:background z:0];
        
        // Add grid
        CCSprite *grid = [CCSprite spriteWithFile:@"grid.png"];
        grid.position = ccp(window.width / 2, grid.contentSize.height / 2 + iPadOffset.y + (25 * fontMultiplier));
        [self addChild:grid z:0];
        
        // Add "reset" and "quit" buttons
        CCMenuItemImage *resetButton = [CCMenuItemImage itemFromNormalImage:@"reset-button.png" selectedImage:@"reset-button.png" block:^(id sender) {
            // TODO: Show confirmation popup here
            // Remove squares from layer
            for (int i = 0; i < [squares count]; i++) 
            {
                RoundRectNode *r = [squares objectAtIndex:i];
                [self removeChild:r cleanup:YES];
            }
            
            // Remove from organizational array
            [squares removeAllObjects];
            
            [[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
        }];
        
        CCMenuItemImage *quitButton = [CCMenuItemImage itemFromNormalImage:@"quit-button.png" selectedImage:@"quit-button.png" block:^(id sender) {
            // TODO: Show confirmation popup here
            
            [[SimpleAudioEngine sharedEngine] playEffect:@"button.caf"];
            
            CCTransitionMoveInT *transition = [CCTransitionMoveInT transitionWithDuration:0.5 scene:[LevelSelectScene scene]];
            [[CCDirector sharedDirector] replaceScene:transition];
        }];
        
        CCMenu *menu = [CCMenu menuWithItems:quitButton, resetButton, nil];
        menu.position = ccp(window.width / 2, window.height - quitButton.contentSize.height / 1.5);
        [menu alignItemsHorizontallyWithPadding:20.0];
        [self addChild:menu];
        
        // Add "area" label
        areaLabel = [CCLabelTTF labelWithString:@"Area:\n   -" dimensions:CGSizeMake(window.width / 2, 300 * fontMultiplier) alignment:CCTextAlignmentLeft fontName:@"insolent.otf" fontSize:24.0 * fontMultiplier];
        areaLabel.color = ccc3(255, 255, 255);
        areaLabel.position = ccp(areaLabel.contentSize.width / 2, menu.position.y - areaLabel.contentSize.height / 1.5);
        [self addChild:areaLabel];
        
        // Add "timer" label
        timerLabel = [CCLabelTTF labelWithString:@"Time:\n   00:00" dimensions:CGSizeMake(window.width / 2, 300 * fontMultiplier) alignment:CCTextAlignmentLeft fontName:@"insolent.otf" fontSize:24.0 * fontMultiplier];
        timerLabel.color = ccc3(255, 255, 255);
        timerLabel.position = ccp(window.width - timerLabel.contentSize.width / 2, menu.position.y - timerLabel.contentSize.height / 1.5);
        [self addChild:timerLabel];
        
        // Schedule update method for timer
        timer = 0;
        [self schedule:@selector(updateTimer:) interval:1.0];
        
        // Load level dictionary
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *pathToFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@", [GameSingleton sharedGameSingleton].difficulty, [GameSingleton sharedGameSingleton].levelToLoad]];
        
        // Get JSON data out of file, and parse into dictionary
        NSData *json = [NSData dataWithContentsOfFile:pathToFile];
        NSError *error = nil;
        level = [NSDictionary dictionaryWithJSONData:json error:&error];
        
        if (error != nil)
        {
            CCLOG(@"Error deserializing JSON data: %@", error);
        }
        
//        level = [NSDictionary dictionaryWithContentsOfFile:pathToFile];
        CCLOG(@"Level data: %@", level);
        
        // Get out the "clue" objects
        NSArray *c = [level objectForKey:@"clues"];
        
        // Iterate and draw
        for (int i = 0; i < [c count]; i++)
        {
            NSArray *val = [c objectAtIndex:i];
            int value = [(NSNumber *)[val objectAtIndex:2] intValue],
                x = [(NSNumber *)[val objectAtIndex:0] intValue],
                y = [(NSNumber *)[val objectAtIndex:1] intValue];
            
            Clue *c = [Clue clueWithNumber:value];
            c.position = ccp(x * blockSize + offset.x + blockSize / 2, y * blockSize + offset.y + blockSize / 2);
            [self addChild:c z:2];
            
            // Add clue to the organization array
            [clues addObject:c];
        }
	}
	return self;
}

/**
 * Method that gets called every second, to update the "timer" label
 */
- (void)updateTimer:(ccTime)dt
{
    timer++;
    timerLabel.string = [NSString stringWithFormat:@"Time:\n   %02i:%02i", timer / 60, timer % 60];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Get the touch coords
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
	// Only register the touch as "valid" if it's within the allowed indices of the grid
    CGRect gridBounds = CGRectMake(offset.x, offset.y, gridSize * blockSize, gridSize * blockSize);
    CGRect touchBounds = CGRectMake(touchPoint.x, touchPoint.y, 1, 1);		// 1x1 square
    
	if (CGRectIntersectsRect(gridBounds, touchBounds))
	{
        touchStart = touchPrevious = touchPoint;
        
        // Figure out the row/column that was touched
        touchRow = startRow = previousRow = (touchPoint.y - offset.y) / blockSize;
        touchCol = startCol = previousCol = (touchPoint.x - offset.x) / blockSize;
  
        // Determine if we need to delete a square here
        for (int i = 0; i < [squares count]; i++)
        {
            RoundRectNode *r = [squares objectAtIndex:i];
            
            // RoundRectNode origin is upper left
            // CGRect origin is lower left
            
            int width = r.size.width, height = r.size.height;
            CGRect rectBounds = CGRectMake(r.position.x, r.position.y - height, width, height);
            CGRect touchBounds = CGRectMake(touchPoint.x, touchPoint.y, 1, 1);		// 1x1 square
            
            // If the touch point is inside the bounds of an existing square, remove it
            if (CGRectIntersectsRect(rectBounds, touchBounds))
            {
                [self removeChild:r cleanup:NO];
                [squares removeObjectAtIndex:i];
                i--;
            }
        }
        
        selection.visible = YES;
        selection.size = CGSizeMake(blockSize, blockSize);  // Default size
        selection.position = ccp((touchCol * blockSize) + offset.x, (touchRow * blockSize) + (offset.y + blockSize));
	}
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Get the touch coords
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    // Figure out the row/column that was touched
	touchRow = (touchPoint.y - offset.y) / blockSize;
	touchCol = (touchPoint.x - offset.x) / blockSize;
    
    // Limit movement to within the grid
    if (touchRow > gridSize - 1)
    {
        touchRow = gridSize - 1;
    }
    
    if (touchRow < 0)
    {
        touchRow = 0;
    }
    
    if (touchCol > gridSize - 1)
    {
        touchCol = gridSize - 1;
    }
    
    if (touchCol < 0)
    {
        touchCol = 0;
    }
    
    // Determine the width/height of the selection by subtracting the start from the current touch row/col
    int width = abs(startCol - touchCol) + 1,
        height = abs(startRow - touchRow) + 1;
    
    // If touches move out of the initial square, determine direction and scale appropriately
    // y-axis
    if (touchRow != previousRow)
    {
        // Change height
        selection.size = CGSizeMake(selection.size.width, height * blockSize);
        
        // Determine if necessary to just draw (normal) or draw & move up (upwards movement)
        if (touchRow >= startRow)
        {
            selection.position = ccp(selection.position.x, 
                                     (touchRow * blockSize) + offset.y + blockSize);
        }
        
        // Play SFX
        [[SimpleAudioEngine sharedEngine] playEffect:@"mark.caf"];
    }
    
    // x-axis
    if (touchCol != previousCol)
    {
        selection.size = CGSizeMake(width * blockSize, selection.size.height);
        
        // Determine if necessary to just draw (normal) or draw & move left (left movement)
        if (touchCol <= startCol)
        {
            selection.position = ccp((touchCol * blockSize) + offset.x, 
                                     selection.position.y);
        }
        
        // Play SFX
        [[SimpleAudioEngine sharedEngine] playEffect:@"mark.caf"];
    }
    
    // Update the "area" label
    areaLabel.string = [NSString stringWithFormat:@"Area:\n   %i", width * height];
    
    // Store the "previous" value for each row/col
    previousCol = touchCol;
    previousRow = touchRow;
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    // Create new roundrect w/ same props as "selection"
    RoundRectNode *r = [RoundRectNode initWithRectSize:CGSizeMake(selection.size.width, selection.size.height)];
    r.position = selection.position;
    
    // "Eat" any squares that overlap the newly created one
    CGRect newRect = CGRectMake(r.position.x, r.position.y - r.size.height, r.size.width, r.size.height);
    for (int i = 0; i < [squares count]; i++) 
    {
        RoundRectNode *o = [squares objectAtIndex:i]; 
        CGRect oldRect = CGRectMake(o.position.x, o.position.y - o.size.height, o.size.width, o.size.height);
        
        // Remove old squares that overlap
        if (CGRectIntersectsRect(newRect, oldRect))
        {
            [self removeChild:o cleanup:NO];
            [squares removeObjectAtIndex:i];
            i--;
        }
    }
    
    // If player just tapped, simply remove the tapped square
    if (CGPointEqualToPoint(touchStart, touchPoint) == NO)
    {
        // Add new square to layer
        [self addChild:r z:1];
        
        // Store it in the "squares" array
        [squares addObject:r];
        
        areaLabel.string = @"Area:\n   -";
    }
    
    // Hide the original "selection" roundrect
    selection.visible = NO;
    
    // Check to see if the puzzle was completed successfully
    if ([self checkSolution])
    {
        NSLog(@"You win!");
        CCTransitionMoveInT *transition = [CCTransitionMoveInT transitionWithDuration:0.5 scene:[LevelSelectScene scene]];
        [[CCDirector sharedDirector] replaceScene:transition];
    }
}

/**
 * Determine if a puzzle has been completed by checking player-placed squares against clue objects
 */
- (BOOL)checkSolution
{
    /*
     Psuedo-code steps to check solution
     1. Iterate through player squares
     2. Iterate through clues
     3. Check to make sure that 
        A. a square's CGRect only contains one clue and
        B. the square's area is equal to that clue's value
     4. If those conditions are not met at any point, return false
     5. Otherwise, return true
     6. This (brute force) algorithm has O(n^2) complexity
     */
    
    // Fast fail
    if ([squares count] != [clues count])
    {
        return NO;
    }
    
    // Otherwise, do our iterations
    for (RoundRectNode *s in squares)
    {
        int cluesInSquare = 0;
        Clue *validClue;
        CGRect squareRect = CGRectMake(s.position.x, s.position.y - s.size.height, s.size.width, s.size.height);

        for (Clue *c in clues)
        {
           // Create rects to check here
            CGRect clueRect = CGRectMake(c.position.x - c.contentSize.width / 2, c.position.y - c.contentSize.height / 2, c.contentSize.width, c.contentSize.height);
            if (CGRectIntersectsRect(squareRect, clueRect))
            {
                cluesInSquare++;
                validClue = c;
            }
        }

        // No clue could be found for the square
        if (!validClue.value)
        {
            return NO;
        }
        
        // Fail if more than one clue in square
        if (cluesInSquare > 1)
        {
            return NO;
        }
        
        // Fail if the square's area doesn't match the clue's value
        if (validClue.value != s.area)
        {
            return NO;
        }
    }
    
    return YES;
}


// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	[squares release];
    [clues release];
    
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
