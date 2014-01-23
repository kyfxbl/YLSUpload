#import <Foundation/Foundation.h>

@interface YLSUploadAndDownloadComponent : NSObject<NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

-(void) uploadFileAt:(NSString*)uploadFilePath toURL:(NSURL*)url ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)())completionHandler;

-(void) downloadFileAt:(NSString*)downloadFilePath ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSString*))completionHandler;

@end
