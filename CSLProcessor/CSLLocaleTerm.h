//
//  CSLLocaleTerm.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TouchXML.h"


static const NSInteger FORM_LONG = 0;
static const NSInteger FORM_SHORT = 1;
static const NSInteger FORM_VERB = 2;
static const NSInteger FORM_VERB_SHORT = 3;
static const NSInteger FORM_SYMBOL = 4;


@interface CSLLocaleTerm : NSObject{
}

@property (retain, nonatomic) NSString* single;
@property (retain, nonatomic) NSString* multiple;
@property (retain, nonatomic) CSLLocaleTerm* shortForm;
@property (retain, nonatomic) CSLLocaleTerm* symbolForm;
@property (retain, nonatomic) CSLLocaleTerm* verbForm;
@property (retain, nonatomic) CSLLocaleTerm* verbShortForm;

-(id)initWithXMLElement:(CXMLElement*)element;

@end
