//
//  PlayLists_TableViewController.m
//  YouPlayList
//
//  Created by Stronger Shen on 2013/11/6.
//  Copyright (c) 2013年 MobileIT. All rights reserved.
//

#import "PlayLists_TableViewController.h"
#import "Lists_TableViewController.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"

@interface PlayLists_TableViewController ()
{
    NSMutableArray *playlists;
    NSString *nextURL;
}

@end

@implementation PlayLists_TableViewController


#pragma mark - Added Methods

- (void)DownloadNext:(NSDictionary *)nextDict
{
    //繼續下載
    nextURL = @"";
    NSMutableArray *links = [nextDict valueForKeyPath:@"feed.link"];
    //    NSLog(@"%@", links);
    for (NSDictionary *dict in links) {
        if ([[dict objectForKey:@"rel"] isEqualToString:@"next"]) {
            nextURL = [dict objectForKey:@"href"];
//            NSLog(@"%@", nextURL);
        }
    }
}


- (void)getPlaylistsByID:(NSString *)userID
{
    //從 YouTube 取得 userID 頻道的播放清單
    NSString *listURL = [NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/users/%@/playlists?v=2&alt=json", userID];
    
    NSURL *url = [NSURL URLWithString:listURL];
//    NSData *data = [NSData dataWithContentsOfURL:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation  = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        playlists = [NSMutableArray arrayWithArray:[[responseObject objectForKey:@"feed"] objectForKey:@"entry"]];
        [self DownloadNext:responseObject];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
    }];
    
    [operation start];
}

-(void)refreshData
{
    if ([nextURL length]>0) {
        //非同步 Block (Async Block)
        NSURL *url = [NSURL URLWithString:nextURL];
        NSURLRequest *request = [NSURLRequest requestWithURL: url];
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:queue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if ([data length]>0 && error==nil) {
                                       //確定資料完整接收完成，而且沒有錯誤
                                       NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                                       NSMutableArray *entrys = [[jsonDictionary objectForKey:@"feed"] objectForKey:@"entry"];
                                       [playlists addObjectsFromArray:entrys];

                                       [self DownloadNext:jsonDictionary];
                                       
                                       if (self.refreshControl.refreshing) {
                                           [self.refreshControl endRefreshing];
                                       }
                                       
                                       [self.tableView reloadData];
                                       
                                   } else if ([data length]==0 && error==nil) {
                                       //沒有接收到資料，連線也沒有錯誤
                                       NSLog(@"Nothing to download");
                                   } else if (error != nil) {
                                       //有連線錯誤
                                       NSLog(@"Error: %@", error);
                                   }
                               }];
    } else {
        if (self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
    }

}

#pragma mark - View

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor magentaColor];
    [refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Pull To Refresh"];
    [refreshString addAttributes:@{NSForegroundColorAttributeName:[UIColor grayColor],NSUnderlineStyleAttributeName:[NSNumber numberWithInt:1]}
        range:NSMakeRange(0, refreshString.length)];
    refreshControl.attributedTitle = refreshString;
    self.refreshControl = refreshControl;
    self.title = [NSString stringWithFormat:@"柯Ｐ新政微電影"];
    [self getPlaylistsByID:@"UCllMvuz1DIPIoqNnur7_Pig"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [playlists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [NSString stringWithFormat:@"%ld:(%ld)%@",
                           (long)indexPath.row,
                           (long)
    [[[playlists objectAtIndex:indexPath.row] valueForKeyPath:@"yt$countHint.$t"] integerValue],
    [[playlists objectAtIndex:indexPath.row] valueForKeyPath:@"title.$t"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",
    [[playlists objectAtIndex:indexPath.row] valueForKeyPath:@"yt$playlistId.$t"] ];
    
    NSString *imageString = [[[[playlists objectAtIndex:indexPath.row] valueForKeyPath:@"media$group.media$thumbnail"] objectAtIndex:0] objectForKey:@"url"];

//1.使用 UIImage imageWithData 同步下載圖片
//    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageString]]];
    
//2.使用 AFImageResponseSerializer 非同步下載圖片，記得 [cell setNeedsLayout]
/*
    NSURL *url = [NSURL URLWithString:imageString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        cell.imageView.image = responseObject;
        [cell setNeedsLayout];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Image error: %@", error);
    }];
    
    [operation start];
*/

//3.使用 UIImageView+AFNetworking category
    NSURL *url = [NSURL URLWithString:imageString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    UIImage *placeholderImage = [UIImage imageNamed:@"fb001.png"];
    __weak UITableViewCell *weakCell = cell;
    [cell.imageView
     setImageWithURLRequest:request
           placeholderImage:placeholderImage
      success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {weakCell.imageView.image = image;
             [weakCell setNeedsLayout];}
           failure:^(NSURLRequest *request, NSHTTPURLResponse *response,
                     NSError *error) {}];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSString *href = [[[[playlists objectAtIndex:indexPath.row] objectForKey:@"link"] objectAtIndex:1] objectForKey:@"href"];
    NSURL *url = [NSURL URLWithString:href];
    [[UIApplication sharedApplication] openURL:url];
}



#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    
    Lists_TableViewController *vc = [segue destinationViewController];
    vc.listDict = [playlists objectAtIndex:indexPath.row];
}


- (IBAction)btnRefresh:(id)sender {
    [playlists removeAllObjects];
    [self getPlaylistsByID:@"UCllMvuz1DIPIoqNnur7_Pig"];
//    [self.tableView reloadData];
}
@end
