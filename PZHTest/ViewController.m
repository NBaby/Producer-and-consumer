//
//  ViewController.m
//  PZHTest
//
//  Created by nuo mi on 2021/5/22.
//

#import "ViewController.h"
#import <pthread.h>
#define maxStackNumber (20)
#define minPlayNumber (5)
@interface ViewController (){
    pthread_mutex_t lock;
    pthread_cond_t popCond;
    pthread_cond_t pushCond;
    pthread_cond_t loadingCond;
  
}

@property (strong,nonatomic) NSMutableArray <NSNumber *>* stack;

@property (assign,nonatomic) BOOL starting;

/// 当前数据
@property (assign,nonatomic) int currentNum;

@property (assign, nonatomic) BOOL  isLoading;
@property (weak, nonatomic) IBOutlet UILabel *label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.stack = [[NSMutableArray alloc] init];
    
    pthread_mutex_init(&lock,NULL);
    pthread_cond_init(&popCond,NULL);
    pthread_cond_init(&pushCond,NULL);
    pthread_cond_init(&loadingCond,NULL);
    num = 0;
    self.isLoading = NO;
    
    
}

- (IBAction)bengin:(id)sender {
    if (!self.starting) {
        self.starting = YES;
    }
    num = 0;
    self.isLoading = NO;
    [self startPushStack];
    
}

- (IBAction)beginCost:(id)sender {
    [self startPopStack];
}

- (IBAction)stop:(id)sender {
    
    if (self.starting) {
        self.starting = NO;
    }
    pthread_cond_signal(&self->popCond);
    pthread_cond_signal(&self->pushCond);
    pthread_cond_signal(&self->loadingCond);
}

static int num;

- (void)startPushStack{
    if (!self.starting) {
        self.starting = YES;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSThread * thread = [NSThread currentThread];
        thread.name = @"生产者线程";
        while (self.starting) {
            pthread_mutex_lock(&self->lock);
            if (self.stack.count < 20) {
                num ++;
                NSLog(@"***生产者 生产出数据 num:%@",@(num));
               
                [self.stack addObject:@(num)];
                if (self.stack.count >= minPlayNumber) {
                    self.isLoading = NO;
                    pthread_cond_signal(&self->loadingCond);
                    [self stopLoading];
                }
                pthread_cond_signal(&self->pushCond);
                
                pthread_mutex_unlock(&self->lock);
                usleep(0.5 *1000 * 1000);

            }
            else {
                NSLog(@"***生产者 栈数据满，等待消耗信号");
                pthread_cond_wait(&self->popCond, &self->lock);
                NSLog(@"***生产者 收到消耗信号");
                pthread_mutex_unlock(&self->lock);
            }
           
        }
        
        NSLog(@"***生产者 线程销毁");
    });
   
}

- (void)startPopStack{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSThread * thread = [NSThread currentThread];
        thread.name = @"消费者线程";
        while (self.starting) {
            pthread_mutex_lock(&self->lock);
            if (self.stack.count == 0){
                NSLog(@"***消费者 栈中没有数据，等待栈中加入数据");
                pthread_cond_wait(&self->pushCond, &self->lock);
                NSLog(@"***消费者 栈中加入数据成功");
                if (self.stack.count < minPlayNumber) {
                    self.isLoading = YES;
                    [self startLoading];
                    NSLog(@"***消费者 发现栈中数据没有达到起播需求,等待达到");
                    pthread_cond_wait(&self->loadingCond, &self->lock);
                    NSLog(@"***消费者 达到消费需求，开始消费");
                }
                pthread_mutex_unlock(&self->lock);
               
            }
            else  {
                int num = [self.stack.firstObject intValue];
                [self.stack removeObjectAtIndex:0];
                NSLog(@"***消费者 消费一个数据 num:%@",@(num));
                pthread_cond_signal(&self->popCond);
                pthread_mutex_unlock(&self->lock);
                usleep(0.3 *1000 * 1000);
            }
        }
        NSLog(@"***消费者 线程销毁");
    });
}

- (void)startLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.label.text = @"加载中";
    });
}

- (void)stopLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.label.text = @"正在播放";
    });
}

@end
