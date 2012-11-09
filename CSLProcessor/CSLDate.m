//
//  CSLDate.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLDate.h"
#import "CSLDatePart.h"

@implementation CSLDate

-(id) initWithXMLElement:(CXMLElement *)element formatter:(CSLFormatter *)formatter{
    self= [super initWithXMLElement:element formatter:formatter];
    
    for(CSLDatePart* child in childElements){
        child.variable = variable;
    }
    return self;
}

-(void) configureWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue formatter:(CSLFormatter*)formatter{
    if([attributeName isEqualToString:@"variable"]){
        variable = attributeValue;
    }
    else{
        [super configureWithAttribute:attributeName value:attributeValue formatter:formatter];
    }
}

@end
