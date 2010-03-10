//
//  CalendarViewController.m
//  iWVU
//
//  Created by Jared Crawford on 3/5/10.
//  Copyright Jared Crawford 2010. All rights reserved.
//

/*
 Copyright (c) 2009 Jared Crawford
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 The trademarks owned or managed by the West Virginia 
 University Board of Governors (WVU) are used under agreement 
 between the above copyright holder(s) and WVU. The West 
 Virginia University Board of Governors maintains ownership of all 
 trademarks. Reuse of this software or software source code, in any 
 form, must remove all references to any trademark owned or 
 managed by West Virginia University.
 */ 

#import "CalendarViewController.h"
#import "CJSONDeserializer.h"
#import "NSString+MD5.h"
#import "NSDate+Helper.h"
#import "EventViewManager.h"


@implementation CalendarViewController

@synthesize calendarKey;

////////Calendar Data Values//////
//startTime 
//title 
//endTime
////////Optional//////////////////
//contactPhone 
//contactEmail
//location
//contactName 
//description
//eventLink
//////////////////////////////////

-(void)viewDidLoad{
	[super viewDidLoad];
	
	downloadThread = [[NSThread alloc] initWithTarget:self selector:@selector(downloadCalendarData) object:nil];
	[downloadThread start];

}

-(void)viewWillDisappear:(BOOL)animated{
	[downloadThread cancel];
	[downloadThread release];
	downloadThread = nil;
}


-(void)downloadCalendarData{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(calendarKey){
		NSString *calendarDataURL = [NSString stringWithFormat:@"http://m.wvu.edu/calendar/json/index.php?id=%@",calendarKey];
		NSError *err;
		NSData *jsonData = [NSData dataWithContentsOfURL:[NSURL URLWithString:calendarDataURL]];
		if(![[NSThread currentThread] isCancelled]){
			calendarItems = [[[CJSONDeserializer deserializer] deserializeAsArray:jsonData error:&err] retain];
			[self.monthView performSelectorOnMainThread:@selector(reload) withObject:nil waitUntilDone:NO];
		}
		[downloadThread release];
		downloadThread = nil;
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}


- (BOOL) calendarMonthView:(TKCalendarMonthView*)monthView markForDay:(NSDate*)date{
	for (NSDictionary *dict in calendarItems) {
		NSDate *eventTime = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"startTime"] doubleValue]];
		double secondsBetween = [eventTime timeIntervalSinceDate:date];
		if ((secondsBetween>=0)&&(secondsBetween<86400)) {//in the same calendar day
			return YES;
		}
	}
	return NO;
}


- (void) calendarMonthView:(TKCalendarMonthView*)monthView dateWasSelected:(NSDate*)date{
	[eventsForCurrentDay release];
	NSMutableArray *currentDaysEvents = [NSMutableArray arrayWithCapacity:1];
	for (NSDictionary *dict in calendarItems) {
		NSDate *eventTime = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"startTime"] doubleValue]];
		double secondsBetween = [eventTime timeIntervalSinceDate:date];
		if ((secondsBetween>=0)&&(secondsBetween<86400)) {//in the same calendar day
			[currentDaysEvents addObject:dict];
		}
	}
	eventsForCurrentDay = [[NSArray arrayWithArray:currentDaysEvents] retain];
	[tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [eventsForCurrentDay count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

	UITableViewCell *cell;
	cell = [tableView dequeueReusableCellWithIdentifier:@"CalendarDay"];
	if(cell==nil){
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CalendarDay"] autorelease];
	} 
	
	NSDictionary *event = [eventsForCurrentDay objectAtIndex:indexPath.row];
	
	cell.textLabel.text = [[event valueForKey:@"title"] stringByDecodingXMLEntities];
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:[[event valueForKey:@"startTime"] floatValue]];
	cell.detailTextLabel.text = [[NSDate stringFromDate:startTime withFormat:@"h:mm a"] uppercaseString];
	cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSDictionary *dict = [eventsForCurrentDay objectAtIndex:indexPath.row];
	
	UIViewController *viewController = [EventViewManager loadEventViewWithDictionary:dict];
	[self.navigationController pushViewController:viewController animated:YES];
	
}

@end
