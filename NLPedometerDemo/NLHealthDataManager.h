//
//  NLHealthDataManager.h
//  NLPedometerDemo
//
//  Created by yj_zhang on 2018/3/20.
//  Copyright © 2018年 yj_zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLStepModel.h"

@interface NLHealthDataManager : NSObject

+(NLHealthDataManager *)shareHealthDataManager;

/**
 * 获取苹果健康权限
 */
-(void)getHealthDataAvailableWith:(void(^)(BOOL res))result;

/**
 * 插入数据
 */
-(void)insertDataWithModel:(NLStepModel *)model;

/**
 * 更新数据
 */
-(void)updataDataWithModel:(NLStepModel *)model;

/**
 * 获取今天步数数据
 */
-(void)searchTodayDataWithResArray:(void(^)(NSMutableArray *resArr))resArray;

@end
