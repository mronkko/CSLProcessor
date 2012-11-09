//
//  CSLLocaleTerm.m
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLLocaleTerm.h"

@implementation CSLLocaleTerm

@synthesize single, multiple, shortForm, symbolForm, verbForm, verbShortForm;

-(id)initWithXMLElement:(CXMLElement*)element{
    self = [super init];
    if([element childCount]>1){
        for(CXMLNode* child in element.children){
            if([child isKindOfClass:[CXMLElement class]]){
                CXMLElement* childElement = (CXMLElement*) child;
                if([childElement.name isEqualToString:@"single"]){
                    self.single = childElement.stringValue;
                }
                else if([childElement.name isEqualToString:@"multiple"]){
                    self.multiple = childElement.stringValue;
                }
            }
        }
    }
    else{
        self.single = [element stringValue];
        self.multiple = self.single;
    }
    return self;
}



@end
