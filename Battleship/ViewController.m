//
//  ViewController.m
//  Battleship
//
//  Created by Eric Lewis on 1/1/16.
//  Copyright © 2016 Eric Lewis. All rights reserved.
//

#import "ViewController.h"
#import "KRLCollectionViewGridLayout.h"
#import "JFMinimalNotification.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *opponentGridView;
@property (weak, nonatomic) IBOutlet UICollectionView *playerGridView;
@property (strong, nonatomic) NSMutableArray *playerGridMatrix;
@property (strong, nonatomic) NSMutableArray *opponentGridMatrix;

@property (strong, nonatomic) NSMutableArray *playerUnplacedShipArray;
@property (strong, nonatomic) NSMutableDictionary *playerShipDictionary;

@property (strong, nonatomic) NSMutableArray *opponentUnplacedShipArray;
@property (strong, nonatomic) NSMutableDictionary *opponentShipDictionary;

@property (strong, nonatomic) UILabel *passToNextPlayerView;
@property (strong, nonatomic) JFMinimalNotification *minimalNotification;

@property (nonatomic) BOOL isFirstPlayersTurn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.playerGridView.backgroundColor = [UIColor lightGrayColor];
    self.opponentGridView.backgroundColor = [UIColor whiteColor];
    
    [self.opponentGridView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"boobs"];
    [self.opponentGridView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:@"UICollectionElementKindSectionFooter" withReuseIdentifier:@"fag"];
    [self.playerGridView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"boobs"];
    [self.playerGridView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:@"UICollectionElementKindSectionFooter" withReuseIdentifier:@"fag"];
    
    KRLCollectionViewGridLayout *opponentLayout = (KRLCollectionViewGridLayout*)self.opponentGridView.collectionViewLayout;
    opponentLayout.numberOfItemsPerLine = 10;
    opponentLayout.aspectRatio = 1;
    opponentLayout.lineSpacing = 1;
    opponentLayout.interitemSpacing = 1;
    opponentLayout.footerReferenceLength = 46;

    KRLCollectionViewGridLayout *playerLayout = (KRLCollectionViewGridLayout*)self.playerGridView.collectionViewLayout;
    playerLayout.numberOfItemsPerLine = 10;
    playerLayout.lineSpacing = 1;
    playerLayout.interitemSpacing = 1;
    playerLayout.footerReferenceLength = 46;
    
    [self setupGame];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.delegate = self;
    lpgr.delaysTouchesBegan = YES;
    [self.playerGridView addGestureRecognizer:lpgr];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideOverlay)];
    
    self.isFirstPlayersTurn = YES;

    self.passToNextPlayerView = [[UILabel alloc] initWithFrame:self.view.frame];
    [self.passToNextPlayerView setBackgroundColor:[UIColor blackColor]];
    [self.passToNextPlayerView setNumberOfLines:0];
    [self.passToNextPlayerView setTextColor:[UIColor whiteColor]];
    [self.passToNextPlayerView setTextAlignment:NSTextAlignmentCenter];
    [self.passToNextPlayerView setHidden:YES];
    [self.passToNextPlayerView setUserInteractionEnabled:YES];
    [self.passToNextPlayerView addGestureRecognizer:tapGesture];
    [self.view addSubview:self.passToNextPlayerView];
    
    /**
     * Create the notification
     */
    self.minimalNotification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleSuccess
                                                                      title:@"BOOM!"
                                                                   subTitle:@"You sunk a ship"
                                                                    dismissalDelay:1.0];
    /**
     * Add the notification to a view
     */
    [self.view addSubview:self.minimalNotification];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 10 * 10;
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"fag" forIndexPath:indexPath];
    
    KRLCollectionViewGridLayout *playerLayout = (KRLCollectionViewGridLayout*)self.playerGridView.collectionViewLayout;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame)/2, playerLayout.footerReferenceLength)];

    BOOL addSub = YES;
    
    for (id view in cell.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            label = view;
            addSub = NO;
        }
    }
    
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    
    if (self.isFirstPlayersTurn && collectionView == self.playerGridView) {
        [label setText:[NSString stringWithFormat:@"Player 1 - Ships Remaining: %lu", (unsigned long)self.playerShipDictionary.count]];
        [label setTextColor:[UIColor greenColor]];
    }
    
    if (self.isFirstPlayersTurn && collectionView == self.opponentGridView) {
        [label setText:[NSString stringWithFormat:@"Player 2 - Ships Remaining: %lu", (unsigned long)self.opponentShipDictionary.count]];
        [label setTextColor:[UIColor redColor]];
    }
    
    if (!self.isFirstPlayersTurn && collectionView == self.playerGridView) {
        [label setText:[NSString stringWithFormat:@"Player 2 - Ships Remaining: %lu", (unsigned long)self.playerShipDictionary.count]];
        [label setTextColor:[UIColor greenColor]];
    }
    
    if (!self.isFirstPlayersTurn && collectionView == self.opponentGridView) {
        [label setText:[NSString stringWithFormat:@"Player 1 - Ships Remaining: %lu", (unsigned long)self.opponentShipDictionary.count]];
        [label setTextColor:[UIColor redColor]];
    }
    
    if (addSub) {
        [cell addSubview:label];
    }

    [cell setBackgroundColor:[UIColor darkGrayColor]];
    
    return cell;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"boobs" forIndexPath:indexPath];
    
    NSInteger column = [[[self rowAndColumnForIndexPath:indexPath] objectAtIndex:0] integerValue];
    NSInteger row    = [[[self rowAndColumnForIndexPath:indexPath] objectAtIndex:1] integerValue];
    
    if (collectionView == self.opponentGridView) {
        NSNumber *point = [[self.opponentGridMatrix objectAtIndex:row] objectAtIndex:column];

        switch (point.integerValue) {
            case 0:
                [cell setBackgroundColor:[UIColor blackColor]];
                break;
            case 1:
                [cell setBackgroundColor:[UIColor redColor]];
                break;
            case 2:
                [cell setBackgroundColor:[UIColor grayColor]];
                break;
            case 3:
                [cell setBackgroundColor:[UIColor orangeColor]];
                break;
            default:
                [cell setBackgroundColor:[UIColor blackColor]]; // hide the ship! change to a diff color if you wanna see them.
                break;
        }
    }else{
        NSNumber *point = [[self.playerGridMatrix objectAtIndex:row] objectAtIndex:column];
        
        switch (point.integerValue) {
            case 0:
                [cell setBackgroundColor:[UIColor whiteColor]];
                break;
            case 1:
                [cell setBackgroundColor:[UIColor redColor]];
                break;
            case 2:
                [cell setBackgroundColor:[UIColor grayColor]];
                break;
            case 3:
                [cell setBackgroundColor:[UIColor orangeColor]];
                break;
            default:
                [cell setBackgroundColor:[UIColor greenColor]];
                break;
        }
    }

    cell.layer.cornerRadius = 2;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger column = [[[self rowAndColumnForIndexPath:indexPath] objectAtIndex:0] integerValue];
    NSInteger row    = [[[self rowAndColumnForIndexPath:indexPath] objectAtIndex:1] integerValue];

    // handle firing upon the enemy!!
    if (collectionView == self.opponentGridView && self.playerUnplacedShipArray.count == 0) {
        [self handleFiringWith:row andColumn:column];
    }else if(collectionView == self.playerGridView && self.playerUnplacedShipArray.count > 0){
        // handle placing ships.
        [self placeShip:[self.playerUnplacedShipArray.firstObject integerValue] AtRow:row withColumn:column horizontal:YES];
    }
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.playerGridView];
    
    NSIndexPath *indexPath = [self.playerGridView indexPathForItemAtPoint:p];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        NSInteger column = [[[self rowAndColumnForIndexPath:indexPath] objectAtIndex:0] integerValue];
        NSInteger row    = [[[self rowAndColumnForIndexPath:indexPath] objectAtIndex:1] integerValue];
        
        if (self.playerUnplacedShipArray.count > 0) {
            [self placeShip:[self.playerUnplacedShipArray.firstObject integerValue] AtRow:row withColumn:column horizontal:NO];
        }
    }
}

// all the repetitive stuff here could be rolled into a loop, but im lazy. and this is easy. c+p FTW..
- (void)placeShip:(NSInteger)ship AtRow:(NSInteger)row withColumn:(NSInteger)column horizontal:(BOOL)horizontal{
    NSNumber *point = [[self.playerGridMatrix objectAtIndex:row] objectAtIndex:column];
    NSMutableArray *columns = [self.playerGridMatrix objectAtIndex:row];
    NSInteger shipHP = [[[self.playerShipDictionary objectForKey:@(ship)] valueForKey:@"HP"] integerValue];
    NSInteger *number = 0;

    if (point.integerValue == 0) {
        if (horizontal) {
            if (row+shipHP > self.playerGridMatrix.count) {
                return;
            }
            
            for (int i = 1; i < shipHP; i++) {
                number += [[[self.playerGridMatrix objectAtIndex:row+i] objectAtIndex:column] integerValue];
            }
            
            if (number == 0) {
                for (int i = 0; i < shipHP; i++) {
                    [[self.playerGridMatrix objectAtIndex:row+i] replaceObjectAtIndex:column withObject:@(ship)];
                }
                
                [self.playerUnplacedShipArray removeObjectAtIndex:0];
            }
        }else{
            if (column+shipHP > columns.count) {
                return;
            }
            
            for (int i = 1; i < shipHP; i++) {
                number += [[columns objectAtIndex:column+i] integerValue];
            }
            
            if (number == 0) {
                for (int i = 0; i < shipHP; i++) {
                    [columns replaceObjectAtIndex:column+i withObject:@(ship)];
                }
                
                [self.playerUnplacedShipArray removeObjectAtIndex:0];
            }
        }
    }
    
    if (self.playerUnplacedShipArray.count == 0) {
        [self performSelector:@selector(swapMatrixGrid) withObject:nil afterDelay:0.45];
    }
    
    [self reloadGrids];
}

- (void)handleFiringWith:(NSInteger)row andColumn:(NSInteger)column{
    NSNumber *point = [[self.opponentGridMatrix objectAtIndex:row] objectAtIndex:column];

    if (point.integerValue == 0) {
        [[self.opponentGridMatrix objectAtIndex:row] replaceObjectAtIndex:column withObject:@(2)];
    }else{
        if (point.integerValue == 1 || point.integerValue == 2 || point.integerValue == 3) {
            return;
        }else{
            NSMutableDictionary *ship = [self.opponentShipDictionary objectForKey:point];
            NSInteger HP = [[ship objectForKey:@"HP"] integerValue];
            
            if (--HP > 0) {
                [ship setObject:@(HP) forKey:@"HP"];
            }else{
                // TODO:
                // need to mark dead!
                [self.opponentShipDictionary removeObjectForKey:@(point.integerValue)];
                [self.minimalNotification show];
                
                // WON
                if (self.opponentShipDictionary.count == 0) {
                    [self setupGame];
                    return;
                }
            }
            
            [[self.opponentGridMatrix objectAtIndex:row] replaceObjectAtIndex:column withObject:@(1)];
        }
    }
    
    [self performSelector:@selector(swapMatrixGrid) withObject:nil afterDelay:0.45];
    [self reloadGrids];
}

- (void)setupGame{
    
    self.playerUnplacedShipArray = [NSMutableArray arrayWithArray:@[@(4), @(5), @(6), @(7), @(8)]];
    self.playerShipDictionary = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @(4): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                      @"HP": @(5)
                                                                                                                                      }],
                                                                                @(5): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                      @"HP": @(4)
                                                                                                                                      }],
                                                                                @(6): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                      @"HP": @(3)
                                                                                                                                      }],
                                                                                @(7): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                      @"HP": @(3)
                                                                                                                                      }],
                                                                                @(8): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                      @"HP": @(2)
                                                                                                                                      }],
                                                                                }];
    
    self.opponentUnplacedShipArray = [NSMutableArray arrayWithArray:@[@(4), @(5), @(6), @(7), @(8)]];
    self.opponentShipDictionary = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                  @(4): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                        @"HP": @(5)
                                                                                                                                        }],
                                                                                  @(5): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                        @"HP": @(4)
                                                                                                                                        }],
                                                                                  @(6): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                        @"HP": @(3)
                                                                                                                                        }],
                                                                                  @(7): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                        @"HP": @(3)
                                                                                                                                        }],
                                                                                  @(8): [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                        @"HP": @(2)
                                                                                                                                        }],
                                                                                  }];
    
    int numberOfRows = 10;
    int numberOfColumns = 10;
    
    NSMutableArray *matrix = [NSMutableArray new];
    NSMutableArray *matrix2 = [NSMutableArray new];

    for (int i = 0; i < numberOfRows; i++) {
        
        NSMutableArray *row = [NSMutableArray new];
        NSMutableArray *row2 = [NSMutableArray new];
        
        for (int i = 0; i < numberOfColumns; i++) {
            [row addObject:@(0)];
            [row2 addObject:@(0)];
        }
        
        [matrix addObject:row];
        [matrix2 addObject:row2];
    }
    
    self.playerGridMatrix = matrix;
    self.opponentGridMatrix = matrix2;
    
    [self reloadGrids];
}

- (NSArray*)rowAndColumnForIndexPath:(NSIndexPath*)indexPath{
    NSNumber *number = [NSNumber numberWithFloat:(indexPath.row / 10.f)];
    
    NSInteger column;
    NSInteger row;
    
    // divisible by 10 evenly, so the column will always be 0
    if ((indexPath.row % 10) == 0) {
        column = 0;
        row = number.integerValue;
    }else{
        column = [[number.stringValue componentsSeparatedByString:@"."] lastObject].integerValue;
        row = [[number.stringValue componentsSeparatedByString:@"."] firstObject].integerValue;
    }
    
    return @[@(row), @(column)];
}

- (void)swapMatrixGrid{
    [self.passToNextPlayerView setText:[NSString stringWithFormat:@"Pass to %@.\nNow tap.", !self.isFirstPlayersTurn ? @"Player 1" : @"Player 2"]];
    [self.passToNextPlayerView setHidden:NO];
    self.isFirstPlayersTurn = !self.isFirstPlayersTurn;
    
    NSMutableArray *swap = self.opponentGridMatrix;
    self.opponentGridMatrix = self.playerGridMatrix;
    self.playerGridMatrix = swap;
    
    NSMutableArray *swap2 = self.opponentUnplacedShipArray;
    self.opponentUnplacedShipArray = self.playerUnplacedShipArray;
    self.playerUnplacedShipArray = swap2;
    
    NSMutableDictionary *swap3 = self.opponentShipDictionary;
    self.opponentShipDictionary = self.playerShipDictionary;
    self.playerShipDictionary = swap3;
    
    [self reloadGrids];
}

- (void)reloadGrids{
    [self.playerGridView reloadData];
    [self.opponentGridView reloadData];
}

- (void)hideOverlay{
    [self.passToNextPlayerView setHidden:YES];
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

@end
