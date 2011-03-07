/*
 *  CGPDFAdditions.h
 *  pdfrasterize
 *
 *  Created by Cédric Luthi on 2010-06-18
 *  Copyright 2010 Cédric Luthi. All rights reserved.
 *
 */

#import <QuartzCore/QuartzCore.h>

/* Return a normalized rotation between 0 and 3

      -------                             ------- 
     |       |        -----------        |       |        ----------- 
     |   ^   |       |           |       |   |   |       |           |
  0: |   |   |    1: |    -->    |    2: |   |   |    3: |    <--    |
     |       |       |           |       |   ˇ   |       |           |
      -------         -----------         -------         ----------- 

*/

int PDFPageGetRotation(CGPDFPageRef page);

CGSize PDFPageGetSize(CGPDFPageRef page, CGPDFBox box);

CGAffineTransform PDFPageGetDrawingTransform(CGPDFPageRef page, CGPDFBox box, float scale);

CGImageRef CreatePDFPageImage(CGPDFPageRef page, CGFloat scale, bool transparentBackground);
