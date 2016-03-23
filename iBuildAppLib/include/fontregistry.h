//
//  FontRegistry.h
//  Tabris
//
//  Created by Jordi Böhme López on 25.07.12.
//  Copyright (c) 2012 EclipseSource.
//  All rights reserved. This program and the accompanying materials
//  are made available under the terms of the Eclipse Public License v1.0
//  which accompanies this distribution, and is available at
//  http://www.eclipse.org/legal/epl-v10.html
//

// Modified by iBuildApp

#import <Foundation/Foundation.h>

@interface TFontRegistry : NSObject
{
  NSMutableDictionary *fonts;
}

+(TFontRegistry *)instance;
-(NSString *)fontForFamily:(NSString *)fontFamily
                   forBold:(BOOL)isBold
                 andItalic:(BOOL)isItalic;
@end
