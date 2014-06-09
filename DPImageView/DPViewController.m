//
//  DPViewController.m
//  DPImageView
//
//  Created by chenlei on 14-6-9.
//  Copyright (c) 2014年 doplan. All rights reserved.
//

#import "DPViewController.h"
#import "DPImageView.h"

@interface DPViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation DPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1000;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d", indexPath.row];
    cell.imageView.url = [NSURL URLWithString:@"http://img0.bdstatic.com/img/image/shouye/mxty-11795402252.jpg"];
    
    return cell;
}

@end
