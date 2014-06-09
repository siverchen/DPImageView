//
//  UIImageView+DPImageView.h
//  DPImageView
//
//  Created by chenlei on 14-6-9.
//  Copyright (c) 2014年 doplan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (DPImageView)

@property (nonatomic, strong) NSURL *url;

/**
 *	@brief	设定一次获取的最大图片数量 默认为无限制
 *
 *	@param 	count 	图片数量
 */
+ (void)setMaxLoadCount:(NSUInteger)count;

/**
 *	@brief	手动设定缓存目录
 *
 *	@param 	path 	缓存目录
 */
+ (void)setCachePath:(NSString *)path;


/**
 *	@brief	清除缓存 此清除只清楚硬盘缓存 不清除内存缓存
 */
+ (void)clearCache;


@end