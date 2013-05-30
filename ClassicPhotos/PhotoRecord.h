//
//  PhotoRecord.h
//  ClassicPhotos
//
//  Created by 王兴朝 on 13-5-29.
//  Copyright (c) 2013年 bitcar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhotoRecord : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, readonly) BOOL hasImage;
@property (nonatomic, getter = isFiltered) BOOL filtered;
@property (nonatomic, getter = isFailed) BOOL failed;

@end
