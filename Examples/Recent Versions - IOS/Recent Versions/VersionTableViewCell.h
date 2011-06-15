//
//  VersionTableViewCell.h
//  Example Recent Versions
//
//  Created by Rob Blau on 6/13/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VersionTableViewCell : UITableViewCell {
    UIImageView *image1;
    UIImageView *image2;
    UIImageView *image3;
    UIImageView *image4;
    UIImageView *image5;
    UILabel *label1;
    UILabel *label2;
    UILabel *label3;
    UILabel *label4;
    UILabel *label5;
    NSArray *images;
    NSArray *labels;
}

@property (nonatomic, retain) IBOutlet UIImageView *image1;
@property (nonatomic, retain) IBOutlet UIImageView *image2;
@property (nonatomic, retain) IBOutlet UIImageView *image3;
@property (nonatomic, retain) IBOutlet UIImageView *image4;
@property (nonatomic, retain) IBOutlet UIImageView *image5;
@property (nonatomic, retain) IBOutlet UILabel *label1;
@property (nonatomic, retain) IBOutlet UILabel *label2;
@property (nonatomic, retain) IBOutlet UILabel *label3;
@property (nonatomic, retain) IBOutlet UILabel *label4;
@property (nonatomic, retain) IBOutlet UILabel *label5;
@property (readonly) NSArray *images;
@property (readonly) NSArray *labels;

@end
