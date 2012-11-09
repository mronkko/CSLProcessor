//
//  CSLBibliographyOrCitation.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import "CSLRenderingElement.h"

@interface CSLBibliographyOrCitation : CSLRenderingElement{
    CSLRenderingElement* child;
}

@property (assign, nonatomic) NSInteger etAlUseFirst;
@property (assign, nonatomic) BOOL etAlUseLast;

@end