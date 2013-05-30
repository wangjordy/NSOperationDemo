//
//  ImageDownloader.m
//  ClassicPhotos
//
//  Created by 王兴朝 on 13-5-29.
//  Copyright (c) 2013年 bitcar. All rights reserved.
//

#import "ImageDownloader.h"



@implementation ImageDownloader
@synthesize delegate = _delegate;
@synthesize indexPathInTableView = _indexPathInTableView;
@synthesize photoRecord = _photoRecord;


#pragma mark -
#pragma mark - Life Cycle
- (id)initWithPhotoRecord:(PhotoRecord *)record AtIndexPath:(NSIndexPath *)indexPath delegate:(id)theDelegate
{
    if (self = [super init]) {
        self.delegate = theDelegate;
        self.indexPathInTableView = indexPath;
        self.photoRecord = record;
    }
    return self;
}


- (void)main
{
    @autoreleasepool {
        
        if (self.isCancelled) {
            return;
        }
        
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:self.photoRecord.URL];
        
        if (self.isCancelled) {
            imageData = nil;
            return;
        }
        
        if (imageData) {
            UIImage *downloadImage = [UIImage imageWithData:imageData];
            self.photoRecord.image = downloadImage;
        }else {
            self.photoRecord.failed = YES;
        }
        
        imageData = nil;
        
        if (self.isCancelled) {
            return;
        }
        
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(imageDownloaderDidFinish:) withObject:self waitUntilDone:NO];
        
    }
}



@end
