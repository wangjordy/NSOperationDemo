//
//  ListViewController.m
//  ClassicPhotos
//
//  Created by 王兴朝 on 13-5-29.
//  Copyright (c) 2013年 bitcar. All rights reserved.
//

#import "ListViewController.h"

@interface ListViewController ()

@end

@implementation ListViewController
@synthesize photos = _photos;
@synthesize pendingOperations = _pendingOperations;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark -
#pragma mark - Lazy instantiation

- (NSMutableArray *)photos
{
    if (!_photos) {
        
        //1
        NSURL *datasourceURL = [NSURL URLWithString:kDataSourceURLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:datasourceURL];
        
        //2
        AFHTTPRequestOperation *datasource_download_operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        //3
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        //4
        [datasource_download_operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
           
            //5
            NSData *datasource_data = (NSData *)responseObject;
            CFPropertyListRef plist = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)datasource_data, kCFPropertyListImmutable, NULL);
            
            NSDictionary *datasource_dictionary = (__bridge NSDictionary *) plist;

            //6
            NSMutableArray *records = [NSMutableArray array];
            for (NSString *key in datasource_dictionary) {
                PhotoRecord *record = [[PhotoRecord alloc] init];
                record.URL = [NSURL URLWithString:[datasource_dictionary objectForKey:key]];
                record.name = key;
                [records addObject:record];
                record = nil;
            }
            
            //7
            self.photos = records;
            
            CFRelease(plist);
            
            [self.tableView reloadData];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            //8
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            alert = nil;
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }];
        
        [self.pendingOperations.downloadQueue addOperation:datasource_download_operation];
    }
    return _photos;
}

- (PendingOperations *)pendingOperations
{
    if (!_pendingOperations) {
        _pendingOperations = [[PendingOperations alloc] init];
    }
    return _pendingOperations;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Classic Photos";
    
    self.tableView.rowHeight = 80.0f;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = self.photos.count;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        cell.accessoryView = activityIndicatorView;
    }
    
    
    PhotoRecord *aRecord = [self.photos objectAtIndex:indexPath.row];

    if (aRecord.hasImage) {
        [(UIActivityIndicatorView *)cell.accessoryView stopAnimating];
        cell.imageView.image = aRecord.image;
        cell.textLabel.text = aRecord.name;
    }else if (aRecord.isFailed){
        [(UIActivityIndicatorView *)cell.accessoryView stopAnimating];
        cell.imageView.image = [UIImage imageNamed:@"Failed.png"];
        cell.textLabel.text = @"Failed to load";
    }else{
        [(UIActivityIndicatorView *)cell.accessoryView startAnimating];
        cell.imageView.image = [UIImage imageNamed:@"Placeholder.png"];
        cell.textLabel.text = @"";

        if (!tableView.dragging && !tableView.decelerating) {
            [self startOperationsForPhotoRecord:aRecord atIndexPath:indexPath];
        }
    }
    
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.0f;
}


#pragma mark -
#pragma mark - UIScrollView delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // 1
    [self suspendAllOperations];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // 2
    if (!decelerate) {
        [self loadImagesForOnscreenCells];
        [self resumeAllOperations];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 3
    [self loadImagesForOnscreenCells];
    [self resumeAllOperations];
}

#pragma mark -
#pragma mark - Cancelling, suspending, resuming queues / operations

- (void)suspendAllOperations {
    [self.pendingOperations.downloadQueue setSuspended:YES];
    [self.pendingOperations.filtrationQueue setSuspended:YES];
}


- (void)resumeAllOperations {
    [self.pendingOperations.downloadQueue setSuspended:NO];
    [self.pendingOperations.filtrationQueue setSuspended:NO];
}


- (void)cancelAllOperations {
    [self.pendingOperations.downloadQueue cancelAllOperations];
    [self.pendingOperations.filtrationQueue cancelAllOperations];
}


- (void)loadImagesForOnscreenCells {
    
    // 1
    NSSet *visibleRows = [NSSet setWithArray:[self.tableView indexPathsForVisibleRows]];
    
    // 2
    NSMutableSet *pendingOperations = [NSMutableSet setWithArray:[self.pendingOperations.downloadsInProgress allKeys]];
    [pendingOperations addObjectsFromArray:[self.pendingOperations.filtrationsInProgress allKeys]];
    
    NSMutableSet *toBeCancelled = [pendingOperations mutableCopy];
    NSMutableSet *toBeStarted = [visibleRows mutableCopy];
    
    // 3
    [toBeStarted minusSet:pendingOperations];
    // 4
    [toBeCancelled minusSet:visibleRows];
    
    // 5
    for (NSIndexPath *anIndexPath in toBeCancelled) {
        
        ImageDownloader *pendingDownload = [self.pendingOperations.downloadsInProgress objectForKey:anIndexPath];
        [pendingDownload cancel];
        [self.pendingOperations.downloadsInProgress removeObjectForKey:anIndexPath];
        
        ImageFiltration *pendingFiltration = [self.pendingOperations.filtrationsInProgress objectForKey:anIndexPath];
        [pendingFiltration cancel];
        [self.pendingOperations.filtrationsInProgress removeObjectForKey:anIndexPath];
    }
    toBeCancelled = nil;
    
    // 6
    for (NSIndexPath *anIndexPath in toBeStarted) {
        
        PhotoRecord *recordToProcess = [self.photos objectAtIndex:anIndexPath.row];
        [self startOperationsForPhotoRecord:recordToProcess atIndexPath:anIndexPath];
    }
    toBeStarted = nil;
    
}


- (void)startOperationsForPhotoRecord:(PhotoRecord *)record atIndexPath:(NSIndexPath *)indexPath
{
    if (!record.hasImage) {
        [self startImageDownloadingForRecord:record atIndexPath:indexPath];
    }
    
    if (!record.isFiltered) {
        [self startImageFiltrationForRecord:record atIndexPath:indexPath];
    }
}


- (void)startImageDownloadingForRecord:(PhotoRecord *)record atIndexPath:(NSIndexPath *)indexPath
{
    if (![self.pendingOperations.downloadsInProgress.allKeys containsObject:indexPath]) {
        
        ImageDownloader *imageDownloader = [[ImageDownloader alloc] initWithPhotoRecord:record AtIndexPath:indexPath delegate:self];
        [self.pendingOperations.downloadsInProgress setObject:imageDownloader forKey:indexPath];
        [self.pendingOperations.downloadQueue addOperation:imageDownloader];
    }
}

- (void)startImageFiltrationForRecord:(PhotoRecord *)record atIndexPath:(NSIndexPath *)indexPath
{
    if (![self.pendingOperations.filtrationsInProgress.allKeys containsObject:indexPath]) {
        
        ImageFiltration *imageFilltration = [[ImageFiltration alloc] initWithPhotoRecord:record atIndexPath:indexPath delegate:self];
        
        ImageDownloader *dependency = [self.pendingOperations.downloadsInProgress objectForKey:indexPath];
        if (dependency) {
            [imageFilltration addDependency:dependency];
        }
        
        [self.pendingOperations.filtrationsInProgress setObject:imageFilltration forKey:indexPath];
        [self.pendingOperations.filtrationQueue addOperation:imageFilltration];
    }
}


- (void)imageDownloaderDidFinish:(ImageDownloader *)downloader
{
    // 1
    NSIndexPath *indexPath = downloader.indexPathInTableView;
    // 2
//    PhotoRecord *theRecord = downloader.photoRecord;
    // 3
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    // 4
    [self.pendingOperations.downloadsInProgress removeObjectForKey:indexPath];
}

- (void)imageFiltrationDidFinish:(ImageFiltration *)filtration
{
    NSIndexPath *indexPath = filtration.indexPathInTableView;
//    PhotoRecord *theRecord = filtration.photoRecord;
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.pendingOperations.filtrationsInProgress removeObjectForKey:indexPath];
}

@end
