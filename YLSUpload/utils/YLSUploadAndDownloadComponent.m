#import "YLSUploadAndDownloadComponent.h"

@implementation YLSUploadAndDownloadComponent

{
    NSString *boundary;
    NSString *fileParam;
    
    void (^uploadProcessHandler)(float, float);
    void (^uploadCompletionHandler)(NSData*);
    
    void (^downloadProcessHandler)(float, float);
    void (^downloadCompletionHandler)(NSString*);
    
    NSData *uploadResponse;// server response when upload
}

-(id) init
{
    self = [super init];
    if(self){
        boundary = @"----------V2ymHFg03ehbqgZCaKO6jy";
        fileParam = @"file";
    }
    return self;
}

#pragma mark - download method

-(void) downloadFileAt:(NSString*)downloadFilePath ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSString*))completionHandler
{
    downloadProcessHandler = processHandler;
    downloadCompletionHandler = completionHandler;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSURL *url = [NSURL URLWithString:downloadFilePath];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    
    [downloadTask resume];
}

#pragma mark - NSURLSessionDownloadDelegate method

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    [session invalidateAndCancel];
    
    NSString* tempFilePath = [location path];// download file temp path
    
    downloadCompletionHandler(tempFilePath);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    float done = (float)totalBytesWritten;
    float total = (float)totalBytesExpectedToWrite;
    
    downloadProcessHandler(done, total);
}

#pragma mark - upload method

-(void) uploadFileAt:(NSString*)uploadFilePath toURL:(NSURL*)url ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSData*))completionHandler;
{
    // instance method, to use in delegate method
    uploadProcessHandler = processHandler;
    uploadCompletionHandler = completionHandler;
    
    uploadResponse = nil;// a new upload task, so reset upload response
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSData *body = [self prepareDataForUpload:uploadFilePath];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    
    // add Content-Type for HTTP Header
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:body];
    
    [uploadTask resume];
}

-(NSData*) prepareDataForUpload:(NSString*)uploadFilePath
{
    NSString *fileName = [uploadFilePath lastPathComponent];
    
    NSMutableData *body = [NSMutableData data];
    
    NSData *dataOfFile = [[NSData alloc] initWithContentsOfFile:uploadFilePath];
    
    if (dataOfFile) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fileParam, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/zip\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:dataOfFile];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return body;
}

#pragma mark - NSURLSessionDataDelegate method

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    uploadResponse = data;// this method will not be invoked, if server doesn't return any response
}

#pragma mark - NSURLSessionTaskDelegate method

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // DownloadTask invoke this method too, return in this case
    if(![task isKindOfClass:[NSURLSessionUploadTask class]]){
        return;
    }
    
    [session invalidateAndCancel];
    
    if(error){
        NSLog(@"upload error: %@", [error localizedDescription]);
    }
    
    uploadCompletionHandler(uploadResponse);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    float done = (float)totalBytesSent;
    float total = (float)totalBytesExpectedToSend;
    
    uploadProcessHandler(done, total);
}

@end
