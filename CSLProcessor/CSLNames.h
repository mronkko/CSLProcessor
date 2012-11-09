//
//  CSLNames.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSLRenderingElement.h"
#import "CSLRenderingElementContainer.h"
#import "CSLLabel.h"

@interface CSLNames : CSLRenderingElement{
    NSArray* variables;
    CSLRenderingElementContainer* substitutes;
    NSString* delimiter;
    NSString* initializeWith;
    NSInteger andMode;
    NSString* nameDelimiter;
    NSInteger nameAsSortOrder;
    NSString* sortSeparator;
    NSInteger delimiterPrecedesLast;
    NSInteger nameForm;
    CSLLabel* label;
}

@end
