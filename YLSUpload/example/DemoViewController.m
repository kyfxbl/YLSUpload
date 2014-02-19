#import "DemoViewController.h"

@implementation DemoViewController

{
    YLSUploadAndDownloadComponent *component;
    UILabel *label;
}

-(id) init
{
    self = [super init];
    if(self){
        component = [[YLSUploadAndDownloadComponent alloc] init];
    }
    return self;
}

-(void) loadView
{
    UIView *rootView = [[UIView alloc] init];
    
    label = [[UILabel alloc] init];
    label.frame = CGRectMake(234, 100, 300, 400);
    label.text = @"result";
    label.textAlignment = NSTextAlignmentCenter;
    
    UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    uploadButton.frame = CGRectMake(234, 400, 80, 30);
    [uploadButton setTitle:@"upload" forState:UIControlStateNormal];
    [uploadButton addTarget:self action:@selector(doUpload) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    downloadButton.frame = CGRectMake(454, 400, 80, 30);
    [downloadButton setTitle:@"download" forState:UIControlStateNormal];
    [downloadButton addTarget:self action:@selector(doDownload) forControlEvents:UIControlEventTouchUpInside];
    
    [rootView addSubview:label];
    [rootView addSubview:uploadButton];
    [rootView addSubview:downloadButton];
    
    self.view = rootView;
}

-(void) doUpload
{
    NSString *documentsDirectory = [self resolveDocumentDirectory];
    NSString *tempFilePath = [documentsDirectory stringByAppendingPathComponent:@"for_upload.zip"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:tempFilePath]){
        [fileManager createFileAtPath:tempFilePath contents:[@"hello world" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    
    NSURL *url = [NSURL URLWithString:@"http://www.yilos.com/svc/mobileFile-upload"];
    
    [component uploadFileAt:tempFilePath toURL:url ProcessHandler:^(float done, float total){
        NSLog(@"uploaded size: %f, totally size: %f", done, total);
    } CompletionHandler:^(NSData* response){
        NSString *res = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        [fileManager removeItemAtPath:tempFilePath error:nil];
        
        NSLog(@"upload done, server response: %@", res);
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            label.text = @"upload success";
        });
    }];
}

-(void) doDownload
{
    NSString *url = @"http://www.yilos.com/svc/backup/downloadResumeFile/100009108165500300";
    
    [component downloadFileAt:url ProcessHandler:^(float done, float total){
        NSLog(@"uploaded size: %f, totally size: %f", done, total);
    } CompletionHandler:^(NSString* tempDownloadPath){
        
        NSString *documentsDirectory = [self resolveDocumentDirectory];
        NSString *localFilePath = [documentsDirectory stringByAppendingPathComponent:@"download_moved.zip"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:tempDownloadPath]){
            [fileManager copyItemAtPath:tempDownloadPath toPath:localFilePath error:nil];
        }
        
        NSLog(@"download done, file put at: %@", localFilePath);
        
        dispatch_async(dispatch_get_main_queue(), ^(void){

            label.text = @"download success";
        });
    }];
}

-(NSString*) resolveDocumentDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

@end
