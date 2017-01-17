//
//  DictionaryViewController.m
//  Dictionary
//
//  Created by nagarani konda on 1/16/17.
//  Copyright © 2017 nagarani konda. All rights reserved.
//

#import "DictionaryViewController.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "Constants.h"

@interface DictionaryViewController ()
{
    __weak IBOutlet UILabel *displayLabelText;
    __weak IBOutlet UITextField *searchTextField;
    NSMutableArray *dicListArray;
    __weak IBOutlet UITableView *dicTableview;
    NSString *networkStatus;
}

@end

@implementation DictionaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    dicListArray = [[NSMutableArray alloc]init];
    dicTableview.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.35];
    displayLabelText.text = EnterAcronymORInitialism;

    // Do any additional setup after loading the view.
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if([networkStatus isEqualToString:NotReachable])
    {
        if([dicListArray count] >0)
        {
            [dicListArray removeAllObjects];
        }
        displayLabelText.text = NetworkConnection;
        [dicTableview setSeparatorColor:[UIColor clearColor]];
    }
    else{
        if([dicListArray count] == 0 && searchTextField.text.length > 0)
        {
            displayLabelText.text = NoResultsFound;
            [dicTableview setSeparatorColor:[UIColor clearColor]];
        }
        else if([dicListArray count] == 0 && searchTextField.text.length == 0)
        {
            displayLabelText.text = EnterAcronymORInitialism;
            [dicTableview setSeparatorColor:[UIColor clearColor]];
            
        }
        else{
            displayLabelText.text = @"";
            [dicTableview setSeparatorColor:[UIColor whiteColor]];
            
        }

    }
    return   [dicListArray count];
    
}
-(UITableViewCell *)tableView:(UITableView *)tableView1 cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    UITableViewCell *cell = [tableView1 dequeueReusableCellWithIdentifier:@"MyIdentifier"];
    
        if (cell == nil) {
        
            
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    
    cell.textLabel.text = [dicListArray objectAtIndex:indexPath.row];
    cell.textLabel.numberOfLines = 0;
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField1
{
    [searchTextField resignFirstResponder];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
            if([AFStringFromNetworkReachabilityStatus(status) isEqualToString:@"Not Reachable"])
            {
                networkStatus = NotReachable;
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [dicTableview reloadData];

            }
            else{
                networkStatus = NetworkReachable;
             [self searchAcronymORIntialism];
            }
        }];
        
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        });
    });
    
    
    
    return NO;
}
-(void)searchAcronymORIntialism{
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    [manager setResponseSerializer:[AFJSONResponseSerializer serializer]];
    
    
    NSURL *UR1L = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.nactem.ac.uk/software/acromine/dictionary.py?sf=%@", searchTextField.text]];
    
    NSURLRequest *request1 = [NSURLRequest requestWithURL:UR1L];
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request1 completionHandler:^(NSURLResponse *response, id responseObject, NSError *error)
                                      {
                                          if (error) {
                                              NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                                              
                                              
                                              if([dicListArray count] >0)
                                              {
                                                  [dicListArray removeAllObjects];
                                              }
                                              
                                              NSData *data = [ErrorResponse dataUsingEncoding:NSUTF8StringEncoding];
                                              
                                              NSArray *dataJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                              
                                              
                                              
                                              [dataJSON enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop)
                                               {
                                                   // do something with object
                                                   
                                                   NSDictionary *userName = [dataJSON objectAtIndex:idx];
                                                 
                                                   if ([[userName allKeys] containsObject:@"lfs"])
                                                   {
                                                       [[userName valueForKey:@"lfs"]  enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
                                                           
                                                           NSDictionary *userName1 = [[userName valueForKey:@"lfs"] objectAtIndex:idx];
                                                           if ([[userName1 allKeys] containsObject:@"lf"])
                                                           {
                                                               [dicListArray addObject:[userName1 valueForKey:@"lf"]];
                                                               
                                                               
                                                           }
                                                           
                                                           
                                                       }];
                                                   }
                                                   
                                                   
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [dicTableview reloadData];
                                                       [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                       
                                                   });
                                                   
                                               }];
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [dicTableview reloadData];
                                                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                  
                                              });
                                              
                                          } else {
                                              
                                              NSLog(@"%@ %@", response, responseObject);
                                              
                                          }
                                      }];
    [dataTask resume];
}


- (IBAction)searchBtnAction:(id)sender {
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
            if([AFStringFromNetworkReachabilityStatus(status) isEqualToString:@"Not Reachable"])
            {
                networkStatus = NotReachable;
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [dicTableview reloadData];
                
            }
            else{
                networkStatus = NetworkReachable;
                [self searchAcronymORIntialism];
            }
        }];
        
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];

        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        });
    });

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
