#import "SEGStoreKitTracker.h"


@interface SEGStoreKitTracker ()

@property (nonatomic, readonly) SEGAnalytics *analytics;
@property (nonatomic, readonly) NSMutableDictionary *transactions;
@property (nonatomic, readonly) NSMutableDictionary *productRequests;

@end


@implementation SEGStoreKitTracker

+ (instancetype)trackTransactionsForAnalytics:(SEGAnalytics *)analytics
{
    return [[SEGStoreKitTracker alloc] initWithAnalytics:analytics];
}

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics
{
    if (self = [self init]) {
        _analytics = analytics;
        _productRequests = [NSMutableDictionary dictionaryWithCapacity:1];
        _transactions = [NSMutableDictionary dictionaryWithCapacity:1];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - SKPaymentQueue Observer
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        if (transaction.transactionState != SKPaymentTransactionStatePurchased) {
            continue;
        }
        
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:transaction.payment.productIdentifier]];
        @synchronized(self)
        {
            [self.transactions setObject:transaction forKey:transaction.payment.productIdentifier];
            [self.productRequests setObject:request forKey:transaction.payment.productIdentifier];
        }
        request.delegate = self;
        [request start];
    }
}

#pragma mark - SKProductsRequest delegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (SKProduct *product in response.products) {
        @synchronized(self)
        {
            SKPaymentTransaction *transaction = [self.transactions objectForKey:product.productIdentifier];
            [self trackTransaction:transaction forProduct:product];
            [self.transactions removeObjectForKey:product.productIdentifier];
            [self.productRequests removeObjectForKey:product.productIdentifier];
        }
    }
}

#pragma mark - Track
- (void)trackTransaction:(SKPaymentTransaction *)transaction forProduct:(SKProduct *)product
{
    NSString *currency = [product.priceLocale objectForKey:NSLocaleCurrencyCode];
    
    [self.analytics track:@"Order Completed" properties:@{
                                                          @"orderId" : transaction.transactionIdentifier,
                                                          @"affiliation" : @"App Store",
                                                          @"currency" : currency,
                                                          @"products" : @[
                                                                  @{
                                                                      @"productId" : product.productIdentifier,
                                                                      @"quantity" : @(transaction.payment.quantity),
                                                                      @"sku" : transaction.transactionIdentifier,
                                                                      @"price" : product.price,
                                                                      @"name" : product.localizedTitle
                                                                      }
                                                                  ]
                                                          }];
}

@end