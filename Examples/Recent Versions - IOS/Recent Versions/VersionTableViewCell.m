//
//  VersionTableViewCell.m
//  Example Recent Versions
//
//  Created by Rob Blau on 6/13/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "VersionTableViewCell.h"


@implementation VersionTableViewCell
@synthesize image1;
@synthesize image2;
@synthesize image3;
@synthesize image4;
@synthesize image5;
@synthesize label1;
@synthesize label2;
@synthesize label3;
@synthesize label4;
@synthesize label5;
@synthesize images;
@synthesize labels;

- (void)awakeFromNib {
    images = [[[NSArray alloc] initWithObjects:image1, image2, image3, image4, image5, nil] retain];
    labels = [[[NSArray alloc] initWithObjects:label1, label2, label3, label4, label5, nil] retain];    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)dealloc
{
    [image1 release];
    [image2 release];
    [image3 release];
    [image4 release];
    [image5 release];
    [label1 release];
    [label2 release];
    [label3 release];
    [label4 release];
    [label5 release];
    [labels release];
    [images release];
    [super dealloc];
}

@end
