//
//  main.m
//  pdfrasterize
//
//  Created by Cédric Luthi on 14.12.09.
//  Copyright 2009 Cédric Luthi. All rights reserved.
//

#import "DDCommandLineInterface.h"
#import "PDFRasterize.h"

int main (int argc, const char * argv[])
{
	return DDCliAppRunWithClass([PDFRasterize class]);
}
