//
//  CURLFTPSession.h
//  CURLHandle
//
//  Created by Mike Abdullah on 04/03/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import <CURLHandle/CURLHandle.h>


@protocol CURLFTPSessionDelegate;


@interface CURLFTPSession : NSObject <CURLHandleDelegate>
{
  @private
    CURLHandle          *_handle;
    NSURLRequest        *_request;
    NSURLCredential     *_credential;
    
    id <CURLFTPSessionDelegate> _delegate;
    
    NSMutableData   *_data;
}

// Returns nil if not a supported FTP URL
- (id)initWithRequest:(NSURLRequest *)request;

- (void)useCredential:(NSURLCredential *)credential;

- (NSArray *)contentsOfDirectory:(NSString *)path error:(NSError **)error;
// like -contentsOfDirectory:error: but returns an array of dictionaries, with keys like kCFFTPResourceName
- (NSArray *)parsedResourceListingsOfDirectory:(NSString *)path error:(NSError **)error;

- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data permissions:(NSNumber *)permissions withIntermediateDirectories:(BOOL)createIntermediates error:(NSError **)error;

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates error:(NSError **)error;

- (BOOL)removeFileAtPath:(NSString *)path error:(NSError **)error;

@property(nonatomic, assign) id <CURLFTPSessionDelegate> delegate;

@end


@protocol CURLFTPSessionDelegate <NSObject>
- (void)FTPSession:(CURLFTPSession *)session didReceiveDebugInfo:(NSString *)info ofType:(curl_infotype)type;
@end