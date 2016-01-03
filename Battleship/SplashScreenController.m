//
//  SplashScreenController.m
//  Battleship
//
//  Created by Eric Lewis on 1/2/16.
//  Copyright © 2016 Eric Lewis. All rights reserved.
//

#import "SplashScreenController.h"
#import "ViewController.h"

@implementation SplashScreenController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    ViewController *controller = (ViewController*)[segue destinationViewController];

    if ([[segue identifier] isEqualToString:@"HostGame"]) {
        [controller setIsPlayer1:YES];
    }else{
        [controller setIsPlayer1:NO];
    }
}

@end
