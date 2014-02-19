#import <Foundation/Foundation.h>

@interface YLSUploadAndDownloadComponent : NSObject<NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, NSURLSessionDataDelegate>

// upload method
-(void) uploadFileAt:(NSString*)uploadFilePath toURL:(NSURL*)url ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSData*))completionHandler;

// download method
-(void) downloadFileAt:(NSString*)downloadFilePath ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSString*))completionHandler;

@end
