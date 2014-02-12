#import <Foundation/Foundation.h>

@interface YLSUploadAndDownloadComponent : NSObject<NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, NSURLSessionDataDelegate>

-(void) uploadFileAt:(NSString*)uploadFilePath toURL:(NSURL*)url ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSDictionary*))completionHandler;

-(void) downloadFileAt:(NSString*)downloadFilePath ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSString*))completionHandler;

@end
