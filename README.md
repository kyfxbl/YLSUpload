YLSUpload
=====================

a common upload/download component for ios app. it's based on native NSURLSession APIs.

# Introduce

in my opinion, the cocoa touch native NSURLSession API family is quite confusion. not only the inherit hierarchical, but also the many delegate methods, which tangle together

this component encapsulate the underneath APIs and relative delegate methods, only expose 2 simple interface to invoke

compared to other famous ios network library (AFNetworking for example), this util is not that complete, cover everything about networking, but more easy to use, if you just want to get upload/download job done.

# Getting Started

## import
```
#import "YLSUploadAndDownloadComponent.h"
```

## call the method

### upload

for upload, call this:
```
-(void) uploadFileAt:(NSString*)uploadFilePath toURL:(NSURL*)url ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSData*))completionHandler;
```
it expects 4 arguments

uploadFilePath: the file local path to upload, something like: /path/to/your/file

url: your server url which handle the upload request, and maybe send a response

processHandler: a callback block, will be invoked periodly. this callback receive 2 arguments, done bytes and totally bytes, you can implement this block to do log, or show a UIProgressView in your app

completionHandler: a callback block, will be invoked when upload done or an error occurs. the job after upload should be written here

### download

for download, call this:
```
-(void) downloadFileAt:(NSString*)downloadFilePath ProcessHandler:(void(^)(float, float))processHandler CompletionHandler:(void(^)(NSString*))completionHandler;
```
it takes 3 arguments

downloadFilePath: that's your server URL for download the target file, something like, http://192.168.1.111:5000/svc/backup/downloadResumeFile

processHandler: as same as upload method's

completionHandler: will be invoked after download task done, or an error occurs. will call it with a NSString*, tell the temporary full path of the downloaded file, normally it should be tmp/xxx.xxx. in this block, you can (and you should) copy it from temporary directory to your destination path

# about the thread

both callback block will running in a sub thread, not main thread. i didn't change this default active, to give the client code more freedom. however, if you will do some UI stuff (for example, to refresh your UIProgressView in processHandler block), you should change the thread by you own
```
[component downloadFileAt:url ProcessHandler:^(float done, float total){

dispatch_async(dispatch_get_main_queue(), ^(void){
// run in main thread
});

} CompletionHandler:^(NSString* tempDownloadPath){
// something after download done
}];
```
# series

both methods are async invoke, it means the following code is wrong:
```
NSString *destFilePath;

[component downloadFileAt:url ProcessHandler:^(float done, float total){
// log or something else...
} CompletionHandler:^(NSString* tempDownloadPath){

// copy file from temporary path to destination path
}];

// unzip the downloaded file at path: destFilePath
```
the downloadFileAt:ProcessHandler:CompletionHandler: method is non-block, so when you try to unzip the downloaded file, actually the download task is not done yet, so the zip file is not exists at the moment.

instead, you should put the code in the completionHandler. the same as upload method

# example
you can see example code in YLSUpload/example, or run the demo in XCode directly

# contact me

welcome to contact me: kyfxbl@gmail.com

your PR would be appreciated