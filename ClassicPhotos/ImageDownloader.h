//
//  ImageDownloader.h
//  ClassicPhotos
//
//  Created by 王兴朝 on 13-5-29.
//  Copyright (c) 2013年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoRecord.h"

@interface ImageDownloader : NSOperation

@property (nonatomic, assign) id delegate;

@property (nonatomic, readwrite, strong) NSIndexPath *indexPathInTableView;
@property (nonatomic, readwrite, strong) PhotoRecord *photoRecord;

- (id)initWithPhotoRecord:(PhotoRecord *)record AtIndexPath:(NSIndexPath *)indexPath delegate:(id)theDelegate;


@end


@protocol ImageDownloaderDelegate <NSObject>

- (void)imageDownloaderDidFinish:(ImageDownloader *)downloader;

@end