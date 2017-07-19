//
//  ViewController.m
//  测试Socket通信-群聊客户端实现
//
//  Created by 任波 on 2017/7/18.
//  Copyright © 2017年 renb. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<UITableViewDataSource, GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@property (nonatomic, strong) NSMutableArray *dataArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 实现聊天室
    // 1. 连接到服务器
    NSError *error = nil;
    [self.clientSocket connectToHost:@"192.168.1.95" onPort:5288 error:&error];
    if (error) {
        NSLog(@"error:%@", error);
    }
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)clientSock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"与服务器连接成功！");
    // 监听读取数据（在读数据的时候，要监听有没有数据可读，目的是保证数据读取到）
    [clientSock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"与服务器断开连接：%@", err);
}

// 读取数据(接收消息)
- (void)socket:(GCDAsyncSocket *)clientSock didReadData:(NSData *)data withTag:(long)tag {
    NSString *messageStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"接收到消息：%@", messageStr);
    messageStr = [NSString stringWithFormat:@"【匿名】：%@", messageStr];
    [self.dataArr addObject:messageStr];
    // 刷新UI要在主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
    // 监听读取数据（读完数据后，继续监听有没有数据可读，目的是保证下一次数据可以读取到）
    [clientSock readDataWithTimeout:-1 tag:0];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.dataArr[indexPath.row];
    return cell;
}

- (IBAction)clickSenderBtn:(UIButton *)sender {
    NSLog(@"发送消息");
    [self.view endEditing:YES];
    NSString *senderStr = self.textField.text;
    if (senderStr.length == 0) {
        return;
    }
    // 发送数据
    [self.clientSocket writeData:[senderStr dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    
    senderStr = [NSString stringWithFormat:@"【我】：%@", senderStr];
    [self.dataArr addObject:senderStr];
    [self.tableView reloadData];
}

- (GCDAsyncSocket *)clientSocket {
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    return _clientSocket;
}

- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        _dataArr = [[NSMutableArray alloc]init];
    }
    return _dataArr;
}

@end
