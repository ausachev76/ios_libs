/****************************************************************************
 *                                                                           *
 *  Copyright (C) 2014-2015 iBuildApp, Inc. ( http://ibuildapp.com )         *
 *                                                                           *
 *  This file is part of iBuildApp.                                          *
 *                                                                           *
 *  This Source Code Form is subject to the terms of the iBuildApp License.  *
 *  You can obtain one at http://ibuildapp.com/license/                      *
 *                                                                           *
 ****************************************************************************/

#import <UIKit/UIKit.h>
#import "urlloader.h"

typedef enum {
  DM_COMPLETE_DOWNLOAD_LIST = 1,
  DM_FAILURE_DOWNLOAD_LIST  = (1 << 1),
}TDownloadListType;

@interface TDownloadManager : NSObject <IURLLoaderDelegate>
{
  @private
    NSMutableArray         *m_targetList;
  
    /** 
     * List of uploaded successfully links.
     */
    NSMutableArray         *m_downloadCompleteUrlList;
  
    /** 
     * A list of references that could not be pumped.
     */
    NSMutableArray         *m_downloadFailureUrlList;
  
    /** 
     * List of current downloads.
     */
    NSMutableArray         *m_currentDownloadList;
  
    NSTimeInterval          m_timeout;
    NSURLRequestCachePolicy m_cachePolicy;
    TURLLoader             *m_currentLoader;
  
    /** 
     * Download manager is in processing requests or is inactive.
     */
    BOOL                    m_bRunning;
  
    /** 
     * Including LED all the tasks placed in the download manager are running again.
     */
    BOOL                    m_bRunAll;
}

+(TDownloadManager *) instance;

@property (nonatomic, readonly) NSMutableArray         *downloadCompleteUrlList;
@property (nonatomic, readonly) NSMutableArray         *downloadFailureUrlList;
@property (nonatomic, readonly) NSMutableArray         *currentDownloadList;
@property (nonatomic, readonly) NSMutableArray         *targetList;
@property (nonatomic, assign)   NSTimeInterval          timeout;
@property (nonatomic, assign)   NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, readonly) TURLLoader             *currentLoader;
@property (nonatomic, readonly, getter = isRunning ) BOOL bRunning;
@property (nonatomic, readonly, getter = isRunAll  ) BOOL bRunAll;

-(void)removeTarget:(TURLLoader *)loader_;

/** 
 * Adding a new boot loader to load the queue
 *
 * @param loader_ - loader which is added to the queue
 *
 * @return nil - if the loading at the URL has been previously made
 * TURLLoader != loader_, It means that the object is already in the pending download
 * TURLLoader = loader_,  It means that the object loader_ was added to the upload queue
 */
-(TURLLoader *)appendTarget:(TURLLoader *)loader_;
-(TURLLoader *)appendTargetWithHiPriority:(TURLLoader *)loader_;


-(void)clearDownloadList:(TDownloadListType)listType;

-(BOOL)run;
-(BOOL)runAll;
-(BOOL)stop;

@end
