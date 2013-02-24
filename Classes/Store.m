//
//  Store.m
//  Darken
//
//  Created by Robert Lummis on 7/16/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import "Store.h"
#import "PopUpView.h"
#import "MessageManager.h"
#import "Model.h"

@implementation Store

-(void) purchaseStar {
    ANNOUNCE
    
    appStoreAvailable = YES;
    if ( [[SKPaymentQueue defaultQueue].transactions count] > 0 ) {
        [[MessageManager sharedManager] enqueueMessageWithText:@"Please try again after the pending purchase transaction completes." title:@"A Purchase is Pending" delay:0.0f onQueue:X.boardSceneMessageQueue];
        [[MessageManager sharedManager] showQueuedMessages];
        return;
    }
    
    if ( [X.starProductArray count] > 0 ) {
        productType = starProduct;
        [self selectProduct];
    } else {
        appStoreAvailable = NO;
        if (X.tutorialsEnabled && X.level == 2) {
            [[MessageManager sharedManager] enqueueMessageWithText:@"You would normally see a price list for stars here, but the price list can not be obtained because the network is not available or the App Store did not respond. You can view the price list on the web at darkengame.com." title:@"No App Store access" delay:0.0f onQueue:X.boardSceneMessageQueue];
            [self doCancel:self];
        } else {
            [[MessageManager sharedManager] enqueueMessageWithText:@"The network is not available or the App store did not respond. Please try again the next time you play Darken." title:@"App Store not available" delay:0.0f onQueue:X.boardSceneMessageQueue];
        }
        [[MessageManager sharedManager] showQueuedMessages];
        return;
    }
}

-(void) purchaseBomb {
    ANNOUNCE
    
    appStoreAvailable = YES;
    if ( [[SKPaymentQueue defaultQueue].transactions count] > 0 ) {
        [[MessageManager sharedManager] enqueueMessageWithText:@"Please try again after the pending purchase transaction completes." title:@"A Purchase is Pending" delay:0.0f onQueue:X.boardSceneMessageQueue];
        [[MessageManager sharedManager] showQueuedMessages];
        return;
    }
    
    if ( [X.bombProductArray count] > 0 ) {
        productType = bombProduct;
        [self selectProduct];
    } else {
        appStoreAvailable = NO;
        if (X.tutorialsEnabled && X.level == 2) {
            [[MessageManager sharedManager] enqueueMessageWithText:@"You would normally see a price list for bombs here, but the price list can not be obtained because the network is not available or the App Store did not respond. You can view the price list on the web at darkengame.com." title:@"No App Store access" delay:0.0f onQueue:X.boardSceneMessageQueue];
            [self doCancel:self];
        } else {
            [[MessageManager sharedManager] enqueueMessageWithText:@"The network is not available or the App store did not respond. Please try again the next time you play Darken." title:@"App Store not available" delay:0.0f onQueue:X.boardSceneMessageQueue];
        }
        [[MessageManager sharedManager] showQueuedMessages];
        return;
    }
}

-(void) selectProduct {
    ANNOUNCE
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    width = 220.f;  //size of 'store' view
    height = 200.f; //height of 'store' view
    CGFloat x = (winSize.width - width) / 2;
    CGFloat y = (winSize.height - height) / 2;
    CGRect frame = CGRectMake(x, y, width, height);
    host = [PopUpView viewWithFrame:frame backgroundColor:[UIColor colorWithWhite:0.9f alpha:1.0f]];
    X.messageIsShowing = YES;
    leftMargin = 5.f;
    rightMargin = leftMargin;
    clearance = 3.f;
    titleH = 27.f + 10.f;   //original size + adjustment for border
    bottomMarginH = 30.f + 2 * clearance + 10.f;  //20.f is cancel button height; 10.f is adjustment for border
    bottomMarginY = height - bottomMarginH;
    
    tableW = width; //fills the host view
    tableH = bottomMarginY - titleH;
    tableX = 0.f;
    tableY = titleH;

    [self productViewAddTitle];
    [self productViewAddCancelButton];
    [self productViewAddBuyButton];
    [self productViewAddTable];
//    [self productViewAddBorder];
}

-(void) productViewAddTitle {
    CGRect titleFrame = CGRectMake(0, 0, width, titleH);
    UILabel *title = [[UILabel alloc] initWithFrame:titleFrame];
    title.backgroundColor = [UIColor clearColor];
    switch (productType) {
        case starProduct:
            title.text = @"Get More Stars";
            break;
        case bombProduct:
            title.text = @"Get More Bombs";
            break;
        default:
            CCLOG(@"bad productType: %d", productType);
            kill( getpid(), SIGABRT );  //crash
            break;
    }
    title.textAlignment = UITextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textColor = [UIColor darkTextColor];
    [host addSubview:title];
    [title release];
}

-(void) productViewAddCancelButton {
    cancelButtonW = 72.f;
    CGFloat cancelButtonH = 28.f;
    CGFloat cancelButtonX = leftMargin + 4.f;   //4.f for border
    CGFloat cancelButtonY = height - cancelButtonH - clearance - 10.f;  //10.f for border
    CGRect cancelButtonFrame = CGRectMake(cancelButtonX, cancelButtonY, cancelButtonW, cancelButtonH);
    RLButton *cancelButton = [RLButton buttonWithStyle:RLButtonStyleGray 
                                                 target:self 
                                                 action:@selector(doCancel:) 
                                                  frame:cancelButtonFrame];
        //debug - added retain above
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:17];
    cancelButton.text = @"Cancel";
    cancelButton.titleLabel.textAlignment = UITextAlignmentCenter;
    [host addSubview:cancelButton];
}

-(void) productViewAddBuyButton {
    CGFloat buyButtonW = width - leftMargin - rightMargin - cancelButtonW - 14.f;
    CGFloat buyButtonH = 28.f;
    CGFloat buyButtonX = width - buyButtonW - rightMargin - 4.f;    //4.f for border
    CGFloat buyButtonY = height - buyButtonH - clearance - 10.f;    //10.f for border
    CGRect buyButtonFrame = CGRectMake(buyButtonX, buyButtonY, buyButtonW, buyButtonH);
    
    buyButton = [RLButton buttonWithStyle:RLButtonStyleGray 
                                              target:self 
                                              action:@selector(doBuy:) 
                                               frame:buyButtonFrame];
    buyButton.titleLabel.font = [UIFont systemFontOfSize:17];
    buyButton.text = @"Tap an item";
    buyButton.titleLabel.textAlignment = UITextAlignmentCenter;
    buyButton.enabled = NO;
    [host addSubview:buyButton];
}

-(void) doCancel:(id)sender {
    ANNOUNCE
    X.messageIsShowing = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didCancelPurchase" object:self];
    [host remove];
}

-(void) doBuy:(id)sender {
    ANNOUNCE
        //the button should not be enabled until user selects a row so the following should never happen
    NSAssert(productSelected != nil, @"doBuy called with productSelected == nil");
    if (X.tutorialsEnabled && X.level == 2) {
        return; //Don't allow buy during tutorial. The product will be lost at the end of the tutorial.
    }
    
    if ( [SKPaymentQueue canMakePayments] == NO ) {
        CCLOG(@"[SKPaymentQueue canMakePayments] is NO");  //debug
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
                                                        message:@"Purchases are not permitted with this device"
                                                       delegate:self 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    } else {
        SKPayment *payment = [SKPayment paymentWithProduct:productSelected];
        SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
        [paymentQueue addPayment:payment];
//        NSArray *transactions = [SKPaymentQueue defaultQueue].transactions;
        X.messageIsShowing = NO;
        [host remove];
    }
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    CCLOG(@"alertView:%@ clickedButtonAtIndex:%d", alertView, buttonIndex);
}

-(void) productViewAddTable {
    ANNOUNCE
    productTableRows = 3.2;
    CGRect productTableFrame = CGRectMake(tableX, tableY, tableW, tableH);
    productTable = [[UITableView alloc] initWithFrame:productTableFrame style:UITableViewStylePlain];
    productTable.scrollEnabled = NO;
    productTable.rowHeight = tableH / productTableRows;
    productTable.separatorColor = [UIColor whiteColor];
    productTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    productTable.delegate = self;
    productTable.dataSource = self;
    productTable.allowsSelection = YES;   //default 
    productTable.backgroundColor = [UIColor whiteColor];
    [host addSubview:productTable];
    [productTable release];
    oldRow = 99;
    
    originalProductLabelFont = [UIFont systemFontOfSize:16];
    selectedProductLabelFont = [UIFont systemFontOfSize:18];
}

#pragma mark - product table delegate methods

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    ANNOUNCE
    CCLOG(@"                   oldRow: %d", oldRow);
    cell.backgroundColor = [UIColor orangeColor];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ANNOUNCE
    CCLOG(@"             new row: %d", indexPath.row);
    if (oldRow < 90) {
        UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:oldRow inSection:0]];
        [oldCell setSelected:NO animated:NO];
    }
    
    UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *productLabel = (UILabel *)[newCell viewWithTag:PRODUCTLABELTAG];
    NSCharacterSet *chars = [NSCharacterSet punctuationCharacterSet];   //includes period
    NSArray *fields = [productLabel.text componentsSeparatedByCharactersInSet:chars];
    buyButton.text = [[@"Buy " stringByAppendingString:[fields objectAtIndex:0]] 
                      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    buyButton.enabled = YES;
    
    [self whitenTextInTable:tableView newIndexPath:indexPath];
    oldRow = indexPath.row;
    
    NSArray *productArray = productType == starProduct ? X.starProductArray : X.bombProductArray;
    productSelected = [productArray objectAtIndex:indexPath.row];
}

    // whiten text in selected cell
-(void) whitenTextInTable:(UITableView *)table newIndexPath:(NSIndexPath *)newIndexPath {
    ANNOUNCE

    UITableViewCell *oldCell = [table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:oldRow inSection:0]];
    UILabel *oldProductLabel = (UILabel *)[oldCell viewWithTag:PRODUCTLABELTAG];
    oldProductLabel.font = originalProductLabelFont;
    oldProductLabel.textColor = [UIColor darkTextColor];
    oldCell.backgroundColor = [UIColor whiteColor];

    UITableViewCell *newCell = [table cellForRowAtIndexPath:newIndexPath];
    newCell.backgroundColor = [UIColor blueColor];
    UILabel *productLabel = (UILabel *)[newCell viewWithTag:PRODUCTLABELTAG];
    productLabel.font = selectedProductLabelFont;
    productLabel.textColor = [UIColor whiteColor];
    
}

#pragma mark - product table data source methods

-(NSInteger) numberOfSectionsInTableView:(UITableView *)productTable {
    return 1;
}

-(NSInteger) tableView:(UITableView *)productTable numberOfRowsInSection:(NSInteger)section {
    ANNOUNCE
    return productTableRows;
}

-(UITableViewCell *) tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    /* === */
    ANNOUNCE
    CCLOG(@"indexPath.row: %d", indexPath.row);
    CGFloat cellLeftMargin = 5.f;
    CGFloat cellRightMargin = cellLeftMargin;
    CGFloat cellW = width - cellLeftMargin - cellRightMargin;
    UITableViewCell *cell = nil;
    cell = [table dequeueReusableCellWithIdentifier:@"cell"];
    UILabel *productLabel;
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:@"cell"] autorelease];
            //setting backgroundColor here doesn't work. set it in tableView:willDisplayCell:forIndexPath:
        productLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLeftMargin, 
                                                                0.f, 
                                                                cellW - cellLeftMargin - cellRightMargin,
                                                                table.rowHeight)];
        productLabel.backgroundColor = [UIColor clearColor];
        productLabel.textColor = [UIColor darkTextColor];
        productLabel.font = originalProductLabelFont;
        productLabel.textAlignment = UITextAlignmentCenter;
        productLabel.tag = PRODUCTLABELTAG;
        [cell.contentView addSubview:productLabel];
        [productLabel release];
            //I'm naming the product differently at each stage of its construction because NSString is immutable
        
        NSArray *productArray = productType == starProduct ? X.starProductArray : X.bombProductArray;
        SKProduct *product = [productArray objectAtIndex:indexPath.row];
        
            //localizedTitle is like "pack of 20 stars"
        NSString *productFullDescription = product.localizedTitle;
        NSCharacterSet *spaceSet = [NSCharacterSet whitespaceCharacterSet];

        NSString *productQuantity = [[productFullDescription componentsSeparatedByCharactersInSet:spaceSet] objectAtIndex:0];   //new style
        NSString *productKind = [[productFullDescription componentsSeparatedByCharactersInSet:spaceSet] objectAtIndex:1];   //new style
        NSString *productNameWithEllipsis = [productQuantity stringByAppendingFormat:@" %@ ... ", productKind];
        
//        NSString *productNameWithEllipsis = [product.localizedTitle stringByAppendingString:@" ...  "];
        
            //price formatting follows Apple's prototype code in SKProduct Class Reference
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        NSString *productPrice = [numberFormatter stringFromNumber:product.price];
        [numberFormatter release];
        
        productLabel.text = [productNameWithEllipsis stringByAppendingString:productPrice];
                
    } else {
            //the table is not scrollable so this part is not used -- it is NG
        productLabel = (UILabel *) [cell.contentView viewWithTag:PRODUCTLABELTAG];
        productLabel.text = [NSString stringWithFormat:@"%d stars", 10 + 15 * indexPath.row];
        
    }
    
    return cell;
}


@end
