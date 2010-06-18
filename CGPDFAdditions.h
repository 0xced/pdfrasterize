/*
 *  CGPDFAdditions.h
 *  pdfrasterize
 *
 *  Created by Cédric Luthi on 2010-06-18
 *  Copyright 2010 Cédric Luthi. All rights reserved.
 *
 */

#import <ApplicationServices/ApplicationServices.h>

/* Return a normalized rotation between 0 and 3

      -------                             ------- 
     |       |        -----------        |       |        ----------- 
     |   ^   |       |           |       |   |   |       |           |
  0: |   |   |    1: |    -->    |    2: |   |   |    3: |    <--    |
     |       |       |           |       |   ˇ   |       |           |
      -------         -----------         -------         ----------- 

*/

int PDFPageGetRotation(CGPDFPageRef page);
