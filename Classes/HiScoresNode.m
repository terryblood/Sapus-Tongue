/*
 * Copyright (c) 2008-2011 Ricardo Quesada
 * Copyright (c) 2011-2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

//
// Code that shows the "high score" scene
//   * display world wide scores
//   * display scores by country
//   * display local scores
//
//  uses cocoslive to obtain the scores


#import "SapusConfig.h"
#import "HiScoresNode.h"
#import "MainMenuNode.h"
#import "SoundMenuItem.h"
#import "SapusTongueAppDelegate.h"
#import "LocalScore.h"
#import "GameNode.h"
#import "FloorNode.h"
#import "MountainNode.h"
#import "ScoreManager.h"

#ifdef __CC_PLATFORM_IOS
#import "GameCenterManager.h"
#elif defined(__CC_PLATFORM_MAC)
#import "BDSKOverlayWindow.h"
#endif


#define kCellHeight (30)
#define kMaxScoresToFetch (50)

#pragma mark -
#pragma mark HiScoresNode - Shared code between iOS and Mac

@interface HiScoresNode (Private)
-(void) setupBackground;
@end

@implementation HiScoresNode

+(id) sceneWithPlayAgain: (BOOL) again
{
	CCScene *s = [CCScene node];
	id node = [[HiScoresNode alloc] initWithPlayAgain:again];
	[s addChild:node];
	[node release];
	return s;
}

-(id) initWithPlayAgain: (BOOL) again
{
	if( (self=[super init]) ) {
	
		CGSize s = [[CCDirector sharedDirector] winSize];
		
		CCSprite *back = [CCSprite spriteWithFile:@"SapusScores.png"];
		back.anchorPoint = ccp(0.5f, 0.5f);
		back.position = ccp(s.width/2, s.height/2);
		[self addChild:back z:0];

		// CocosLive server is only supported on iOS
#ifdef __CC_PLATFORM_IOS

		CCMenuItem *gameCenter = nil;
		if( [GameCenterManager isGameCenterAvailable] ) {
			gameCenter = [SoundMenuItem itemWithNormalSpriteFrameName:@"btn-game_center-normal.png" selectedSpriteFrameName:@"btn-game_center-selected.png" target:self selector:@selector(gameCenterCB:)];
		}
		
		if ( gameCenter ) {
			CCMenu *menuV = [CCMenu menuWithItems: gameCenter, nil];
			menuV.position = ccp(s.width/2+192,s.height/2+80);		
			[self addChild: menuV z:0];
		}
		
#endif // __CC_PLATFORM_IOS

		CCMenu *menuH;
		CCMenuItem* menuItem = [SoundMenuItem itemWithNormalSpriteFrameName:@"btn-menumed-normal.png" selectedSpriteFrameName:@"btn-menumed-selected.png" target:self selector:@selector(menuCB:)];

		// Menu
		if( ! again ) {
			menuH = [CCMenu menuWithItems: menuItem, nil];
		}
		else {
			CCMenuItem* itemAgain = [SoundMenuItem itemWithNormalSpriteFrameName:@"btn-playagain-normal.png" selectedSpriteFrameName:@"btn-playagain-selected.png" target:self selector:@selector(playAgainCB:)];
			menuH = [CCMenu menuWithItems: itemAgain, menuItem, nil];
		}
		
		[menuH alignItemsHorizontally];
		if( ! again )
			menuH.position = ccp(s.width/2+180,s.height/2-143);
		else
			menuH.position = ccp(s.width/2+120,s.height/2-143);


		[self addChild: menuH z:0];
		
		[self setupBackground];

	}

	return self;
}

-(void) setupBackground
{	
	// Only iPad version
	
#ifdef __CC_PLATFORM_IOS
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#endif
	{
		// tree
		CCSprite *tree = [CCSprite spriteWithFile:@"tree1.png"];
		tree.anchorPoint = CGPointZero;
		[self addChild:tree z:-1];
		
		// tile map
		CCTMXTiledMap *tilemap = [CCTMXTiledMap tiledMapWithTMXFile:@"tilemap.tmx"];
		
		[self addChild:tilemap z:-5];
		
		//
		// TIP #1:release the internal map. Only needed if you are going
		// to read it or write it
		//
		// TIP #2: Since the tilemap was preprocessed using cocos2d's spritesheet-artifact-fixer.py
		// there is no need to use aliased textures, we can use antialiased textures.
		//
		
		for( CCTMXLayer *layer in [tilemap children] ) {
			[layer releaseMap];
			[[layer texture] setAntiAliasTexParameters];
		}
		
		// floor
		FloorNode *floor = [FloorNode node];
		[self addChild:floor z:-6];
		
		// mountains	
		MountainNode *mountain = [MountainNode node];
		CCParallaxNode *parallax = [CCParallaxNode node];
		[parallax addChild:mountain z:0 parallaxRatio:ccp(0.3f, 0.3f) positionOffset:ccp(0,0)];
		[self addChild:parallax z:-7];
	}

	
	// gradient
	CCLayerGradient *g = [CCLayerGradient layerWithColor:ccc4(0,0,0,255) fadingTo:ccc4(0,0,0,255) alongVector:ccp(0,1)];
	
#ifdef __CC_PLATFORM_IOS
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[g setStartColor:ccc3(0xb3, 0xe2, 0xe6)];
		[g setEndColor:ccc3(0,0,0)];
	} else {
		[g setStartColor:ccc3(0xb3, 0xe2, 0xe6)];
		[g setEndColor:ccc3(0x93,0xc2,0xc6)];
	}
#elif defined(__CC_PLATFORM_MAC)
	[g setStartColor:ccc3(0xb3, 0xe2, 0xe6)];
#endif
	
	[self addChild: g z:-10];	
}

-(void) dealloc
{
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];	

#ifdef __CC_PLATFORM_IOS
	[activityIndicator_ release];
	[myTableView_ release];	
#endif

	[super dealloc];
}

-(void) menuCB:(id) sender
{
#ifdef __CC_PLATFORM_IOS
	if( activityIndicator_ ) {
		[activityIndicator_ removeFromSuperview];
		[activityIndicator_ release];
		activityIndicator_ = nil;
	}
	
	if( myTableView_ ) {
		[myTableView_ removeFromSuperview];
		[myTableView_ release];
		myTableView_ = nil;
	}
#elif defined(__CC_PLATFORM_MAC)
	SapusTongueAppDelegate *delegate = [NSApp delegate];
	[[delegate overlayWindow] remove];
#endif
//	[[CCDirector sharedDirector] replaceScene: [CCTransitionSplitRows transitionWithDuration:1.0f scene: [MainMenuNode scene]]];
	[[CCDirector sharedDirector] replaceScene: [CCTransitionProgressHorizontal transitionWithDuration:1.0f scene: [MainMenuNode scene]]];

}

-(void) playAgainCB:(id) sender
{
#ifdef __CC_PLATFORM_IOS
	if( activityIndicator_ ) {
		[activityIndicator_ removeFromSuperview];
		[activityIndicator_ release];
		activityIndicator_ = nil;
	}
	
	if( myTableView_ ) {
		[myTableView_ removeFromSuperview];
		[myTableView_ release];
		myTableView_ = nil;
	}
#elif defined(__CC_PLATFORM_MAC)
	SapusTongueAppDelegate *delegate = [NSApp delegate];
	[[delegate overlayWindow] remove];
#endif
	
	[[CCDirector sharedDirector] replaceScene: [CCTransitionFade transitionWithDuration:1.0f scene: [GameNode scene]]];
}


#ifdef __CC_PLATFORM_IOS

#pragma mark -
#pragma mark HiScoresNode - iOS Only

// table view
-(UITableView*) newTableView
{
	CGSize s = [[CCDirector sharedDirector] winSize];
	UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero];
	tv.delegate = self;
	tv.dataSource = self;
	
	tv.opaque = YES;
	tv.frame = CGRectMake( s.width/2-234, s.height/2-86, 380, 210 );
		
	return tv;
}

//
// TIP:
// The heavy part of init and the UIKit controls are initialized after the transition is finished.
// This trick is used to:
//    * create a smooth transition (load heavy resources after the transition is finished)
//    * show UIKit controls after the transition to simulate that they transition like any other control
//
-(void) onEnterTransitionDidFinish
{
	[super onEnterTransitionDidFinish];

	SapusTongueAppDelegate *app = (SapusTongueAppDelegate*)[[UIApplication sharedApplication] delegate];
	UIViewController *ctl = [app navController];		

	// activity indicator
	if( ! activityIndicator_ ) {
		activityIndicator_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
		
//		CGSize s = [[CCDirector sharedDirector] winSize];
		activityIndicator_.frame = CGRectMake(10, 10, 40, 40);
		
		[ctl.view addSubview: activityIndicator_];

		activityIndicator_.hidesWhenStopped = YES;
		activityIndicator_.opaque = YES;
	}
	
	// table
	if( !myTableView_ )
		myTableView_ = [self newTableView];

	[ctl.view addSubview: myTableView_];	
}

-(void) localScoresCB: (id) sender
{	
	[myTableView_ reloadData];
}

-(void) gameCenterCB:(id) sender
{
	//
	// Display Achievements
	//
	GKAchievementViewController *achivementViewController = [[GKAchievementViewController alloc] init];
	if (achivementViewController != nil)
	{		
		// Obtain the Main Window
		SapusTongueAppDelegate *appDelegate = (SapusTongueAppDelegate*) [[UIApplication sharedApplication] delegate];		
		achivementViewController.achievementDelegate = self;
		
		[[appDelegate navController] presentModalViewController:achivementViewController animated:YES];
	}	
}


#pragma mark HiScoresNode - UITableViewDataSouce (iOS)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	ScoreManager *scoreMgr = [ScoreManager sharedManager];
	return [[scoreMgr scores] count];
}

-(void) setImage:(UIImage*)image inTableViewCell:(UITableViewCell*)cell
{
	cell.imageView.image = image;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	static NSString *MyIdentifier = @"HighScoreCell";
	
	UILabel *name, *score, *idx, *speed, *angle;
	UIView *view;
	UIImageView *imageView;

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
//		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
		cell.opaque = YES;

		// Position
		idx = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 24, kCellHeight-2)];
		idx.tag = 3;
		//		name.font = [UIFont boldSystemFontOfSize:16.0f];
		idx.font = [UIFont fontWithName:@"Marker Felt" size:16.0f];
		idx.adjustsFontSizeToFitWidth = YES;
		idx.textAlignment = UITextAlignmentRight;
		idx.textColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
		idx.autoresizingMask = UIViewAutoresizingFlexibleRightMargin; 
		[cell.contentView addSubview:idx];
		[idx release];
		
		// Name
		name = [[UILabel alloc] initWithFrame:CGRectMake(65.0f, 0.0f, 150, kCellHeight-2)];
		name.tag = 1;
//		name.font = [UIFont boldSystemFontOfSize:16.0];
		name.font = [UIFont fontWithName:@"Marker Felt" size:16.0f];
		name.adjustsFontSizeToFitWidth = YES;
		name.textAlignment = UITextAlignmentLeft;
		name.textColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
		name.autoresizingMask = UIViewAutoresizingFlexibleRightMargin; 
		[cell.contentView addSubview:name];
		[name release];
		
		// Score
		score = [[UILabel alloc] initWithFrame:CGRectMake(200, 0.0f, 70.0f, kCellHeight-2)];
		score.tag = 2;
		score.font = [UIFont systemFontOfSize:16.0f];
		score.textColor = [UIColor darkGrayColor];
		score.adjustsFontSizeToFitWidth = YES;
		score.textAlignment = UITextAlignmentRight;
		score.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[cell.contentView addSubview:score];
		[score release];

		// Speed
		speed = [[UILabel alloc] initWithFrame:CGRectMake(275, 0.0f, 40.0f, kCellHeight-2)];
		speed.tag = 5;
		speed.font = [UIFont systemFontOfSize:16.0f];
		speed.textColor = [UIColor darkGrayColor];
		speed.adjustsFontSizeToFitWidth = YES;
		speed.textAlignment = UITextAlignmentRight;
		speed.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[cell.contentView addSubview:speed];
		[speed release];
		
		// Angle
		angle = [[UILabel alloc] initWithFrame:CGRectMake(315, 0.0f, 35.0f, kCellHeight-2)];
		angle.tag = 6;
		angle.font = [UIFont systemFontOfSize:16.0f];
		angle.textColor = [UIColor darkGrayColor];
		angle.adjustsFontSizeToFitWidth = YES;
		angle.textAlignment = UITextAlignmentRight;
		angle.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[cell.contentView addSubview:angle];
		[angle release];
				
		// Flag
		view = [[UIImageView alloc] initWithFrame:CGRectMake(360, 10.0f, 16, kCellHeight-2)];
		view.opaque = YES;
		imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fam.png"]];
		imageView.opaque = YES;
		imageView.tag = 1;
		[view addSubview:imageView];
		[cell.contentView addSubview:view];		
		view.tag = 4;
		[view release];
		[imageView release];
		
	} else {
		name = (UILabel *)[cell.contentView viewWithTag:1];
		score = (UILabel *)[cell.contentView viewWithTag:2];
		idx = (UILabel *)[cell.contentView viewWithTag:3];
		view = (UIView*)[cell.contentView viewWithTag:4];
		imageView = (UIImageView*)[view viewWithTag:1];
		speed = (UILabel *)[cell.contentView viewWithTag:5];
		angle = (UILabel *)[cell.contentView viewWithTag:6];

	}
	
	int i = indexPath.row;
	ScoreManager *scoreMgr = [ScoreManager sharedManager];
	idx.text = [NSString stringWithFormat:@"%d", indexPath.row + 1];

	LocalScore *s = [[scoreMgr scores] objectAtIndex: i];
	name.text = s.playername;
	score.text = [s.score stringValue];
	speed.text = [s.speed stringValue];
	angle.text = [s.angle stringValue];

	if( [s.playerType intValue] == 1 )
		[self setImage:[UIImage imageNamed:@"MonusHead.png"] inTableViewCell:cell];
	else
		[self setImage:[UIImage imageNamed:@"SapusHead.png"] inTableViewCell:cell];

	imageView.image = nil;	

	return cell;
}

#pragma mark UIAlertView Delegate (iOS)

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
}

#pragma mark GameCenter Delegate (iOS)

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	SapusTongueAppDelegate *appDelegate = (SapusTongueAppDelegate*) [[UIApplication sharedApplication] delegate];
	[[appDelegate navController] dismissModalViewControllerAnimated:YES];
}

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	SapusTongueAppDelegate *appDelegate = (SapusTongueAppDelegate*) [[UIApplication sharedApplication] delegate];
	[[appDelegate navController] dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark HiScoresNode - Mac Only

#elif defined(__CC_PLATFORM_MAC)

-(void) onEnterTransitionDidFinish
{
	[super onEnterTransitionDidFinish];
	
	SapusTongueAppDelegate *delegate = [NSApp delegate];
	
	// Overlay Window
	[[delegate overlayWindow] overlayView:[[CCDirector sharedDirector] view] ];

	NSTableView *tv = [delegate displayScoresTableView];
	tv.delegate = self;
	tv.dataSource = self;
	
	[tv reloadData];

}

#pragma mark HiScoresNode - NSTableViewDelegate (Mac)


#pragma mark HiScoresNode - NSTableViewDataSource (Mac)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[[ScoreManager sharedManager] scores] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSCell *cell = nil;

	LocalScore *s = [[[ScoreManager sharedManager] scores] objectAtIndex: rowIndex];
	
	NSString *type = [aTableColumn identifier];
	
	if( [type isEqualToString:@"position"] ) {
		cell = [[NSCell alloc] initTextCell: [NSString stringWithFormat:@"%ld", rowIndex]];
		
	} else if( [type isEqualToString:@"image"] ) {

		NSString *imageName = @"MonusHead.png";
		if( [s.playerType intValue] == 1 )
			imageName = @"SapusHead.png";

		NSImage *image = [NSImage imageNamed:imageName];
		cell = [[NSCell alloc] initImageCell:image];
		
	} else if( [type isEqualToString:@"name"] ) {
		
		cell = [[NSCell alloc] initTextCell: s.playername];


	} else if( [type isEqualToString:@"score"] ) {
		cell = [[NSCell alloc] initTextCell: [s.score stringValue]];
		
	} else if( [type isEqualToString:@"speed"] ) {
		cell = [[NSCell alloc] initTextCell: [s.speed stringValue]];

	} else if( [type isEqualToString:@"angle"] ) {
		cell = [[NSCell alloc] initTextCell: [s.angle stringValue]];

	}
	
	[cell autorelease];
	return cell;
}


#endif // __CC_PLATFORM_MAC

@end
