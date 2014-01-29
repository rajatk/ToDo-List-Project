//
//  ViewController.m
//  ToDo List
//
//  Created by Rajat on 1/23/14.
//  Copyright (c) 2014 Codetastic. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>
#import "NSDate+Helper.h"

#define scrH self.view.frame.size.height
#define scrW self.view.frame.size.width

@interface ViewController ()

@end

@implementation ViewController

NSMutableArray *doneList, *undoneList, *offlineChanges;
UITableView *todoTable;
UILabel *syncStatus, *lastSyncedTime, *lastSyncedItem;
NSTimer *refreshTimer;
float refreshFreq = 5.0;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	todoTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 65, scrW, scrH - 150)];
	[todoTable setDataSource:self];
	[todoTable setDelegate:self];
	[self.view addSubview:todoTable];
	
	//[self.view setBackgroundColor:[UIColor lightGrayColor]];
	UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(0, scrH - 150 + 65, scrW, 2)];
	[divider setBackgroundColor:[UIColor lightGrayColor]];
	[self.view addSubview:divider];
	
	lastSyncedTime = [[UILabel alloc] initWithFrame:CGRectMake(20, divider.frame.origin.y + 5, scrW - 40, 20)];
	lastSyncedTime.text = [NSString stringWithFormat:@"Last synced %@", [NSDate stringForDisplayFromDate:[NSDate date] prefixed:YES]];
	lastSyncedTime.textAlignment = NSTextAlignmentCenter;
	lastSyncedTime.adjustsFontSizeToFitWidth = YES;
	lastSyncedTime.minimumScaleFactor = 0.5;
	lastSyncedTime.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
	[self.view addSubview:lastSyncedTime];
	
	lastSyncedItem = [[UILabel alloc] initWithFrame:CGRectMake(20, lastSyncedTime.frame.origin.y + 25, scrW - 40, 20)];
	lastSyncedItem.text = @"...";
	lastSyncedItem.adjustsFontSizeToFitWidth = YES;
	lastSyncedItem.minimumScaleFactor = 0.5;
	lastSyncedItem.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
	lastSyncedItem.textAlignment = NSTextAlignmentCenter;
	[self.view addSubview:lastSyncedItem];
	
	syncStatus = [[UILabel alloc] initWithFrame:CGRectMake(20, lastSyncedItem.frame.origin.y + 25, scrW - 40, 20)];
	syncStatus.text = @"...";
	syncStatus.textAlignment = NSTextAlignmentCenter;
	syncStatus.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
	[self.view addSubview:syncStatus];
	
	//add left menu button
	UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Add Item" style:UIBarButtonItemStylePlain target:self action:@selector(addNewTodoItem)];
	[self.navigationController.navigationBar.topItem setRightBarButtonItem:rightButton];
	
	doneList = [[NSMutableArray alloc] init];
	undoneList = [[NSMutableArray alloc] init];
	
	syncStatus.text = @"syncing...";
	PFQuery *query = [PFQuery queryWithClassName:@"CP_Todo"];
	[query orderByAscending:@"updatedAt"];
	query.cachePolicy = kPFCachePolicyCacheThenNetwork;
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (!error) {
			NSLog(@"Successfully retrieved %d todo items.", objects.count);
			
			[doneList removeAllObjects];
			[undoneList removeAllObjects];
			
			for (PFObject *object in objects) {
				//NSLog(@"got object = %@", object);
				
				if([[object objectForKey:@"completed"] intValue] == NO)
				{
					if([undoneList containsObject:object])
						NSLog(@"dup item. don't add: %@", [object objectForKey:@"text"]);
					else
						[undoneList addObject:object];
				}
				else
				{
					if([doneList containsObject:object])
						NSLog(@"dup item. don't add: %@", [object objectForKey:@"text"]);
					else
						[doneList addObject:object];
				}
			}
			
			[todoTable reloadData];
			
			[refreshTimer invalidate];
			refreshTimer = [NSTimer scheduledTimerWithTimeInterval:refreshFreq target:self selector:@selector(refreshTableQuery) userInfo:nil repeats:YES];
			syncStatus.text = nil;
			
		} else {
			NSLog(@"Error with initial query: %@ %@", error, [error userInfo]);
		}
	}];
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addNewTodoItem{
	UIAlertView *newItemAlert = [[UIAlertView alloc] initWithTitle:@"Add Item" message:@"Please enter a task." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
	newItemAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[newItemAlert show];
}

-(void)refreshTableQuery{
	
	NSLog(@"refreshing...");
	syncStatus.text = @"syncing...";
	
	PFQuery *query = [PFQuery queryWithClassName:@"CP_Todo"];
	[query orderByAscending:@"updatedAt"];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		
		if (!error) {
//			[refreshTimer invalidate];
//			NSLog(@"Successfully retrieved %d todo items.", objects.count);
			[doneList removeAllObjects];
			[undoneList removeAllObjects];
			
			for (PFObject *object in objects) {
//				NSLog(@"got object = %@", object);
				

				if([[object objectForKey:@"completed"] intValue] == NO)
				{
					if([undoneList containsObject:object])
						NSLog(@"dup item. don't add: %@", [object objectForKey:@"text"]);
					else
						[undoneList addObject:object];
				}
				else
				{
					if([doneList containsObject:object])
						NSLog(@"dup item. don't add: %@", [object objectForKey:@"text"]);
					else
						[doneList addObject:object];
				}
			}
			
			if([objects count] > 0)
			lastSyncedItem.text = [NSString stringWithFormat:@"Last synced item was '%@'",
								   [[objects objectAtIndex:[objects count] - 1] objectForKey:@"text"]];
			[todoTable reloadData];
			
//			refreshTimer = [NSTimer scheduledTimerWithTimeInterval:refreshFreq target:self selector:@selector(refreshTableQuery) userInfo:nil repeats:YES];
			lastSyncedTime.text = [NSString stringWithFormat:@"Last synced %@", [NSDate stringForDisplayFromDate:[NSDate date] prefixed:YES]];
			syncStatus.text = nil;
			
		} else {
			NSLog(@"Error with initial query: %@ %@", error, [error userInfo]);
		}
	}];
}

#pragma mark table view method

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	static NSString *tableIdentifier = @"todoCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
	
	if(cell==nil){
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableIdentifier];
	}
	
	PFObject *itemTitle;
	if(indexPath.section == 0){
		itemTitle = [undoneList objectAtIndex:indexPath.row];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else{
		itemTitle = [doneList objectAtIndex:indexPath.row];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
	cell.textLabel.text = [itemTitle objectForKey:@"text"];
	
	return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	if(section == 0)
		return [undoneList count];
	else
		return [doneList count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	if(section == 0)
		return @"Incomplete Tasks";
	else
		return @"Completed Tasks";
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	//move task to appropriate list
	NSMutableArray *srcList, *destList;
	bool completionState;
	if(indexPath.section == 0){
		srcList = undoneList;
		destList = doneList;
		completionState = YES;
	}
	else
	{
		srcList = doneList;
		destList = undoneList;
		completionState = NO;
	}
	
	
	PFObject *movingItem = [srcList objectAtIndex:indexPath.row];
	[movingItem setObject:[NSNumber numberWithBool:completionState] forKey:@"completed"];
	[movingItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
		if(!error)
		{
			[self parseFinishedSavingObject:movingItem];
		}
		else
		{
			NSLog(@"Error saving new item: %@ error: %@", [movingItem objectForKey:@"text"], error);
		}
	}];
	
	[destList addObject:movingItem];
	[srcList removeObject:movingItem];
	[todoTable reloadData];
	
	//deselect cell
	[todoTable deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//if user tapped Add, add item to uncompleted section
	if(buttonIndex)
	{
		UITextField *newItemText = [alertView textFieldAtIndex:0];
		NSLog(@"User added new item: %@", newItemText.text);
		
		PFObject *newTodoObject = [PFObject objectWithClassName:@"CP_Todo"];
		[newTodoObject setObject:[NSString stringWithString:newItemText.text] forKey:@"text"];
		[newTodoObject setObject:[NSNumber numberWithBool:NO] forKey:@"completed"];
		[newTodoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			if(!error)
			{
				[self parseFinishedSavingObject:newTodoObject];
			}
			else
			{
				NSLog(@"Error saving new item: %@ error: %@", newItemText.text, error);
			}
		}];
		
		[undoneList addObject:newTodoObject];
		[todoTable reloadData];
	}
}


-(void)parseFinishedSavingObject:(PFObject*)object{
	NSLog(@"last synced item: %@", [object objectForKey:@"text"]);
	
	lastSyncedTime.text = [NSString stringWithFormat:@"Last synced %@", [NSDate stringForDisplayFromDate:[NSDate date] prefixed:YES]];
	lastSyncedItem.text = [NSString stringWithFormat:@"Last synced item was '%@'",
						   [object objectForKey:@"text"]];
}
@end
