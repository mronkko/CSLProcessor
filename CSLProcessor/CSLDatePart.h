//
//  CSLDatePart.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLRenderingElement.h"

@interface CSLDatePart : CSLRenderingElement{
    NSInteger form;
    NSInteger datePart;
}
-(NSString*) _parseDate:(NSString*)dateValue part:(NSInteger)part;

@property (retain, nonatomic) NSString* variable;

@end