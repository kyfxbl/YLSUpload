#import "YLSUploadAndDownloadComponent.h"

@implementation YLSUploadAndDownloadComponent

{
    NSString *boundary;
    NSString *fileParam;
    
    void (^uploadProcessHandler)(float, float);
    void (^uploadCompletionHandler)(NSDictionary*);
    
    void (^downloadProcessHandler)(float, float);
    void (^downloadCompletionHandler)(NSString*);
    
    NSDictionary *uploadResponse;// 上传服务响应
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
    
    NSString* tempFilePath = [location path];// 临时文件路径
    
    downloadCompletionHandler(tempFilePath);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    float done = (float)totalBytesWritten;
    float total = (float)totalBytesExpectedToWrite;
    
    downloadProcessHandler(done, total);
}

#pragma mark - upload method

-(void) uploadFileAt:(NSString*)uploadFilePath toURL:(NSURL*)url ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSDictionary*))completionHandler;
{
    // 设置实例变量，在delegate method中调用
    uploadProcessHandler = processHandler;
    uploadCompletionHandler = completionHandler;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSData *body = [self prepareDataForUpload:uploadFilePath];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    
    // 以下2行是关键，NSURLSessionUploadTask不会自动添加Content-Type头
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

#pragma mark - NSURLSessionTaskDelegate method

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // DownloadTask也会触发此回调，直接返回
    if(![task isKindOfClass:[NSURLSessionUploadTask class]]){
        return;
    }
    
    [session invalidateAndCancel];
    
    uploadCompletionHandler(uploadResponse);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    float done = (float)totalBytesSent;
    float total = (float)totalBytesExpectedToSend;
    
    uploadProcessHandler(done, total);
}

#pragma mark - NSURLSessionDataDelegate method

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    uploadResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}

@end
