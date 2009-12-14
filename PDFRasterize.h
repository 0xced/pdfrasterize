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
	BOOL help;
	NSString *outputDir;
	NSString *format;
	BOOL transparent;
	
	NSMutableDictionary *bitmapFormatUTIs;
}

- (int) rasterize:(NSString *)pdfPath;

@end
