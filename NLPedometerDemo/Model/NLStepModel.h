//
//  NLStepModel.h
//  NLPedometerDemo
//
//  Created by yj_zhang on 2018/3/21.
//  Copyright © 2018年 yj_zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NLStepModel : NSObject
/**
 * 0-未上传, 1-上传
 */
@property(nonatomic,assign)NSInteger isUpload;
@property(nonatomic,assign)NSInteger count;
@property(nonatomic,assign)NSInteger startTime;
@property(nonatomic,assign)NSInteger endTime;
@property(nonatomic,copy)NSString *userid;


@end
