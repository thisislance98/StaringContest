//
//  RouletteViewController.h
//  RouletteTok
//
//  Created by mumm on 2/16/12.
//  Copyright (c) 2012 TokBox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SRWebSocket.h"
#import <Opentok/Opentok.h>

@interface RouletteViewController : UIViewController <SRWebSocketDelegate, OTSessionDelegate, OTPublisherDelegate, OTSubscriberDelegate>
- (IBAction)nextButton;
@property (weak, nonatomic) IBOutlet UILabel *statusField;

@end
