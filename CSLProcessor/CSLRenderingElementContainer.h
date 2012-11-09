//
//  CSLRenderingElementContainer.h
//  CSLProcessor
//
//  Created by Rönkkö Mikko on 11/9/12.
//  Copyright (c) 2012 Rönkkö Mikko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSLRenderingElement.h"

@interface CSLRenderingElementContainer : CSLRenderingElement{
    NSArray* childElements;
    NSString* delimiter;
}

-(NSArray*)childElements;

@end
