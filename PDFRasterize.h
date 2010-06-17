//
//  PDFRasterize.h
//  pdfrasterize
//
//  Created by Cédric Luthi on 14.12.09.
//  Copyright 2009 Cédric Luthi. All rights reserved.
//

#import "DDCommandLineInterface.h"

@interface PDFRasterize : NSObject <DDCliApplicationDelegate>
{
	// options
	NSString *outputDir;
	NSString *format;
	BOOL transparent;
	float scale;
	NSMutableSet *pages;

	NSMutableDictionary *bitmapFormatUTIs;
}

- (BOOL) rasterizePage:(CGPDFPageRef)page toURL:(NSURL *)outputURL;

@end
