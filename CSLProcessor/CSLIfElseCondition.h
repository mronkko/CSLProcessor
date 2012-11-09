//
//  CSLIfElseCondition.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLRenderingElementContainer.h"

@interface CSLIfElseCondition : CSLRenderingElementContainer{
    NSString* typeFieldName;
    NSInteger matchType;
    NSInteger matchCriterion;
    NSArray* matchValues;
    BOOL isElse;
}
-(BOOL) matchesWithFields:(NSDictionary*) fields;
@end