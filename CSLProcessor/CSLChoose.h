//
//  CSLChoose.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLRenderingElement.h"
#import "CSLIfElseCondition.h"

@interface CSLChoose : CSLRenderingElement{
    NSArray* conditions;
}

-(CSLIfElseCondition*) _elementToRenderBasedOnFields:(NSMutableDictionary*)fields;


@end