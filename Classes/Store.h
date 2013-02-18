//
//  Store.h
//  Darken
//
//  Created by Robert Lummis on 7/16/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "RLButton.h"

@class PopUpView;
@interface Store : NSObject <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
{
//    NSIndexPath *oldIndexPath;
    
    enum {
        starProduct,
        bombProduct
    } productType;
    
    PopUpView *host;
    CGFloat width, height;  //dimensions of host view
    CGFloat leftMargin;
    CGFloat rightMargin;
    CGFloat clearance;
    CGFloat titleH;
    CGFloat bottomMarginH;   //its height not its location
    CGFloat bottomMarginY;  //its location
    CGFloat cancelButtonW;
    RLButton *buyButton;
    UITableView *productTable;
    UIFont *originalProductLabelFont;
    UIFont *selectedProductLabelFont;
    
    CGFloat tableX, tableY, tableW, tableH;
    CGFloat productTableRows;
    NSInteger oldRow;
    
    SKProduct *productSelected;
    BOOL appStoreAvailable;
}

-(void) productViewAddTitle;
-(void) productViewAddCancelButton;
-(void) productViewAddBuyButton;
-(void) purchaseStar;
-(void) purchaseBomb;
-(void) selectProduct;
-(void) doCancel:(id)sender;    //called by the 'Cancel' button
-(void) doBuy:(id)sender;   //called by the 'Buy' button
-(void) productViewAddTable;
//-(void) productViewAddBorder;
-(void) whitenTextInTable:(UITableView *)tableView newIndexPath:(NSIndexPath *)newIndexPath;

@end
