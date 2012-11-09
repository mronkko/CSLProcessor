//
//  CSLLocale.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TouchXML.h"
#import "CSLFormatter.h"
@interface CSLLocale : NSObject{
    NSDictionary* terms;
}

-(id)initWithXMLElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter;
-(void)addTermsFromElement:(CXMLElement*)element formatter:(CSLFormatter*)formatter;

-(NSString*)localizedStringForTerm:(NSString*)term plural:(BOOL)plural form:(NSInteger)form;

@end
