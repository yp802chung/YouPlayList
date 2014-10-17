//
//  ViewController.m
//  YouPlayList
//
//  Created by Stronger Shen on 2013/11/6.
//  Copyright (c) 2013年 MobileIT. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    UIWebView *videoView;
}

@end

@implementation ViewController


#pragma mark - Added methods

- (void)embedYouTube:(NSString*)url frame:(CGRect)frame {
    NSString* embedHTML = @"\
<html><head>\
<style type=\"text/css\">\
body {\
background-color: transparent;\
color: white;\
}\
</style>\
</head><body style=\"margin:0\">\
<embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \
width=\"%0.0f\" height=\"%0.0f\"></embed>\
</body></html>";
    NSString* html = [NSString stringWithFormat:embedHTML, url, frame.size.width, frame.size.height];
    if(videoView == nil) {
        videoView = [[UIWebView alloc] initWithFrame:frame];
        // 這兩句是可以給 html5 <video src="MyVideo.mp4" autoplay></video> 的 autoplay 用的
        videoView.allowsInlineMediaPlayback = YES;
        videoView.mediaPlaybackRequiresUserAction = NO;
        
        [self.view addSubview:videoView];
    }
    [videoView loadHTMLString:html baseURL:nil];
}


#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    NSString *href = [[self.playDict objectForKey:@"content"] objectForKey:@"src"];
            self.title = [[_playDict objectForKey:@"title"] objectForKey:@"$t"];
    [self embedYouTube:href frame:CGRectMake(0, 60, 320, 240)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
