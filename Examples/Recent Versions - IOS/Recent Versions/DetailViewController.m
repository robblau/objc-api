//
//  DetailViewController.m
//  Recent Versions
//
//  Created by Rob Blau on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Shotgun.h"
#import "VersionTableViewCell.h"
#import "ASIHTTPRequest.h"
#import "DetailViewController.h"

#import "RootViewController.h"

@implementation DetailViewController

@synthesize toolbar=_toolbar;
@synthesize detailItem=_detailItem;
@synthesize shotgun;
@synthesize versionsTable;
@synthesize versCell;

#pragma mark - Managing the detail item

/*
 When setting the detail item, update the view and dismiss the popover controller if it's showing.
 */
- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        [_detailItem release];
        _detailItem = [newDetailItem retain];
        
        // Update the view.
        [versions release];
        versions = [[shotgun findEntitiesOfType:@"Version"
                                    withFilters:[NSString stringWithFormat:
                                                 @"[[\"project\", \"is\", {\"type\": \"Project\", \"id\": %@}]]",
                                                 [_detailItem objectForKey:@"id"]]
                                      andFields:@"[\"code\", \"sg_status_list\", \"image\", \"created_at\"]" 
                                       andOrder:@"[{\"field_name\": \"created_at\", \"direction\": \"desc\"}]"
                              andFilterOperator:Nil andLimit:50 andPage:0 retiredOnly:NO] retain];
        [versionsTable reloadData];
    }
}

- (void) awakeFromNib {
    imageMap = [[[NSMutableDictionary alloc] init] retain];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
 */

- (void)viewDidUnload
{
	[super viewDidUnload];

	// Release any retained subviews of the main view.
}

#pragma mark - Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int count = [versions count];
    return (count == 0) ? 0 : (count+4)/5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VersionCell";
    
    VersionTableViewCell *cell = (VersionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"VersionTableViewCell" owner:self options:nil];
        cell = versCell;
        self.versCell = nil;
    }
    
    // Configure the cell.
    int start = 5*[indexPath row];
    int count = [versions count];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"d/M/yyyy H:mm"];
    for (int x=0; x<5 && (start+x)<count; x++) {
        NSDictionary *version = [versions objectAtIndex:(start+x)];
        [[[cell labels] objectAtIndex:x] setText:[NSString stringWithFormat:@"%@\n%@",
                                                  [version objectForKey:@"code"],
                                                  [formatter stringFromDate:[version objectForKey:@"created_at"]]]];
        UIImage *thumbnail = [imageMap objectForKey:[version objectForKey:@"image"]];
        if (thumbnail) {
            [[[cell images] objectAtIndex:x] setImage:thumbnail];
        } else {
            __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[version objectForKey:@"image"]]];
            [request setCompletionBlock:^{
                UIImage *thumbnail = [UIImage imageWithData:[request responseData]];
                [imageMap setObject:thumbnail forKey:[version objectForKey:@"image"]];
                [[[cell images] objectAtIndex:x] setImage:thumbnail];
            }];
            [request startAsynchronous];
        }
    }
    [formatter release];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here -- for example, create and push another view controller.
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [_toolbar release];
    [_detailItem release];
    [versions release];
    [imageMap release];
    [super dealloc];
}

@end
