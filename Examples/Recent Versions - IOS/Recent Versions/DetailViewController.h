//
//  DetailViewController.h
//  Recent Versions
//
//  Created by Rob Blau on 6/14/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Shotgun;
@class ShotgunEntity;
@class VersionTableViewCell;

@interface DetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    Shotgun *shotgun;
    NSArray *versions;
    ShotgunEntity *_detailItem;
    NSMutableDictionary *imageMap;
    VersionTableViewCell *versCell;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) ShotgunEntity *detailItem;
@property (nonatomic, retain) IBOutlet UITableView *versionsTable;
@property (nonatomic, assign) IBOutlet VersionTableViewCell *versCell;
@property (readwrite, assign) Shotgun *shotgun;

@end
