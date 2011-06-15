//
//  RootViewController.h
//  Recent Versions
//
//  Created by Rob Blau on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Shotgun;
@class DetailViewController;

@interface RootViewController : UITableViewController {
    NSArray *projects;
    Shotgun *shotgun;
}
		
@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;

@end
