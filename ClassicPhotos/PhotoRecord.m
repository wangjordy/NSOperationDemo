//
//  PhotoRecord.m
//  ClassicPhotos
//
//  Created by 王兴朝 on 13-5-29.
//  Copyright (c) 2013年 bitcar. All rights reserved.
//

#import "PhotoRecord.h"

@implementation PhotoRecord
@synthesize name = _name;
@synthesize image = _image;
@synthesize URL = _URL;
@synthesize hasImage = _hasImage;
@synthesize filtered = _filtered;
@synthesize failed = _failed;

- (BOOL)hasImage
{
    return _image != nil;
}

- (BOOL)isFailed
{
    return _failed;
}

- (BOOL)isFiltered
{
    return _filtered;
}

@end
