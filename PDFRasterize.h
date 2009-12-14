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
	NSString *format;
	NSString *outputDir;
	BOOL help;
	
	NSMutableDictionary *bitmapFormatUTIs;
}

- (int) rasterize:(NSString *)pdfPath;

@end
