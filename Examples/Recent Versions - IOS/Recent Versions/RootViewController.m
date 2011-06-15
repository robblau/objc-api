//
//  RootViewController.m
//  Recent Versions
//
//  Created by Rob Blau on 6/14/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "Shotgun.h"
#import "RootViewController.h"

#import "DetailViewController.h"

@implementation RootViewController
		
@synthesize detailViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
    // Load shotgun connection information from the config plist
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *config = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];

    // Create the shotgun connection
    shotgun = [[[Shotgun alloc] initWithUrl:[config objectForKey:@"url"]
                                 scriptName:[config objectForKey:@"script"] 
                                     andKey:[config objectForKey:@"key"]] retain];

    // Share the connection with the detail controller
    detailViewController.shotgun = shotgun;

    // Pull down all the projects from the servers
    projects = [[shotgun findEntitiesOfType:@"Project" withFilters:@"[]" andFields:@"[\"name\", \"image\"]"] retain];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

		
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [projects count];    		    		
}

		
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    // Configure the cell.  Standard table cell with the name of the project and its thumbnail.
    NSDictionary *project = [projects objectAtIndex:[indexPath row]];
    [[cell textLabel] setText:[project objectForKey:@"name"]];
    if ([project objectForKey:@"image"]) {
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[project objectForKey:@"image"]]]];
        [[cell imageView] setImage:image];        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get selected project and tell the detail view
    ShotgunEntity *project = [projects objectAtIndex:[indexPath row]];
    [detailViewController setDetailItem:project];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {}

- (void)dealloc
{
    [detailViewController release];
    [projects release];
    [shotgun release];
    [super dealloc];
}

@end
