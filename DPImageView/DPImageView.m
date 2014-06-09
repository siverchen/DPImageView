//
//  UIImageView+DPImageView.m
//  DPImageView
//
//  Created by chenlei on 14-6-9.
//  Copyright (c) 2014年 doplan. All rights reserved.
//

#import "DPImageView.h"

#pragma mark - Cache for Image

#define DPDEFAULT_CACHE_PATH [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ImageCache"]

@interface DPImageCache : NSObject {
    NSCache *_cache;
}

@property (nonatomic, strong) NSString *cachePath;

- (void)writeData:(NSData *)data forKey:(NSString *)key;
- (NSData *)getDataForKey:(NSString *)key;
- (void)clear;

+ (instancetype)shareInstance;

@end

@implementation DPImageCache

- (id)init{
    if (self = [super init]){
        _cache = [[NSCache alloc] init];
        self.cachePath = DPDEFAULT_CACHE_PATH;
    }
    return self;
}

- (void)writeData:(NSData *)data
           forKey:(NSString *)key{
    BOOL dir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.cachePath isDirectory:&dir] || dir){
        [[NSFileManager defaultManager] createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [_cache setObject:data forKey:key];
    
    NSString *newKey = [key stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [data writeToFile:[self.cachePath stringByAppendingPathComponent:newKey] atomically:YES];
    });
    
}

- (NSData *)getDataForKey:(NSString *)key{
    NSString *newKey = [key stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    
    if ([_cache objectForKey:newKey]){
        return [_cache objectForKey:newKey];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.cachePath stringByAppendingPathComponent:newKey]]){
        return [NSData dataWithContentsOfFile:[self.cachePath stringByAppendingPathComponent:newKey]];
    }
    
    return nil;
}

+ (instancetype)shareInstance{
    static DPImageCache *cache = nil;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        cache = [[DPImageCache alloc] init];
    });
    
    return cache;
}

- (void)clear{
    BOOL dir = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.cachePath isDirectory:&dir] && dir){
        [[NSFileManager defaultManager] removeItemAtPath:self.cachePath error:nil];
    }
}


@end


/* ------------ 图片下载任务 -----------*/

@interface DPImageLoadTask : NSOperation

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) UInt32 taskid;
@property (nonatomic, copy) void (^completeBlock)(NSData * data);
@property (nonatomic, copy) void (^failedBlock)(NSError * error);

@end

@implementation DPImageLoadTask

- (void)start{
    NSData *result = [[DPImageCache shareInstance] getDataForKey:self.url.absoluteString];
    if (!result){
        NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:nil
                                                         error:&error];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (error){
                if (self.failedBlock){
                    self.failedBlock(error);
                }
            }else if (data && self.completeBlock){
                self.completeBlock(data);
                [[DPImageCache shareInstance] writeData:data forKey:self.url.absoluteString];
            }
        });
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.completeBlock(result);
        });
    }
}

@end

/* ------------ 图片下载器 ------------*/

@interface DPImageLoader : NSObject {
    UInt32 _currentTaskID;
    NSOperationQueue *_operationQueue;
    NSMutableDictionary *_mapTasks;
}

@end

@implementation DPImageLoader

- (id)init{
    if (self = [super init]){
        _currentTaskID = 0;
        _operationQueue = [[NSOperationQueue alloc] init];
        _mapTasks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (instancetype)shareInstance{
    static DPImageLoader *loader = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        loader = [[DPImageLoader alloc] init];
    });
    return loader;
}

- (void)setMaxCount:(NSUInteger)count{
    [_operationQueue setMaxConcurrentOperationCount:count];
}

- (void)addTask:(DPImageLoadTask *)task{
    task.taskid = _currentTaskID++;
    NSString *key = task.url.absoluteString;
    [task setCompleteBlock:^(NSData *data) {
        @synchronized(self){
            for (DPImageLoadTask *atask in [_mapTasks objectForKey:key]){
                [atask.imageView setImage:[UIImage imageWithData:data]];
            }
            [_mapTasks removeObjectForKey:key];
        }
    }];
    
    @synchronized(self){
        NSMutableArray *tasks = [_mapTasks objectForKey:key];
        BOOL hasTasks = (tasks != nil);
        if (!tasks){
            tasks = [NSMutableArray array];
            [_mapTasks setObject:tasks forKey:key];
        }
        [tasks addObject:task];
        
        if (!hasTasks){
            [_operationQueue addOperation:task];
        }
    }
}

@end


@implementation UIImageView (DPImageView)

@dynamic url;

- (void)setUrl:(NSURL *)url{
    DPImageLoadTask *task = [[DPImageLoadTask alloc] init];
    task.url = url;
    task.imageView = self;
    [[DPImageLoader shareInstance] addTask:task];
}

+ (void)setMaxLoadCount:(NSUInteger)count{
    [[DPImageLoader shareInstance] setMaxCount:count];
}

+ (void)setCachePath:(NSString *)path{
    [[DPImageCache shareInstance] setCachePath:path];
}

+ (void)clearCache{
    [[DPImageCache shareInstance] clear];
}



@end







