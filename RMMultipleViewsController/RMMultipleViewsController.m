//
//  RMMultipleViewsController.m
//  RMMultipleViewsController-Demo
//
//  Created by Roland Moers on 29.08.13.
//  Copyright (c) 2013 Roland Moers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "RMMultipleViewsController.h"

#pragma mark - Helper Categories

#import <objc/runtime.h>

static char const * const multipleViewsControllerKey = "multipleViewsControllerKey";

@implementation UIViewController (RMMultipleViewsController)

@dynamic multipleViewsController;

#pragma mark - Properties
- (RMMultipleViewsController *)multipleViewsController {
    return objc_getAssociatedObject(self, multipleViewsControllerKey);
}

- (void)setMultipleViewsController:(RMMultipleViewsController *)multipleViewsController {
    objc_setAssociatedObject(self, multipleViewsControllerKey, multipleViewsController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Helper
- (void)adaptToEdgeInsets:(UIEdgeInsets)newInsets {
    
}

@end

#import <QuartzCore/QuartzCore.h>

#pragma mark - Main Implementation
@interface RMMultipleViewsController ()

@property (nonatomic, strong) NSMutableArray *mutableViewController;
@property (nonatomic, strong) UIViewController *currentViewController;

@property (nonatomic, strong) UIView *contentPlaceholderView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@end

@implementation RMMultipleViewsController

@synthesize viewController = _viewController;
@synthesize mutableViewController = _mutableViewController;
@synthesize segmentedControl = _segmentedControl;

#pragma mark - Init and Dealloc
- (instancetype)initWithViewControllers:(NSArray *)someViewControllers {
    self = [super init];
    if(self) {
        self.viewController = someViewControllers;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.contentPlaceholderView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:self.contentPlaceholderView];
    
    if([self.mutableViewController count] <= 0) {
        [NSException raise:@"RMInvalidViewControllerException" format:@"When -[RMMultipleViewsController %@] is called a multiple views controller must have at least one view controller assigned.", NSStringFromSelector(_cmd)];
    }
    
    [self showViewController:[self.mutableViewController objectAtIndex:0] animated:NO];
    
    self.segmentedControl.selectedSegmentIndex = 0;
    self.navigationItem.titleView = self.segmentedControl;
}

#pragma mark - Orientation
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    self.currentViewController.view.frame = [self frameForViewController:self.currentViewController];
    [self updateContentInsetsForViewController:self.currentViewController];
}

#pragma mark - Persistency
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.viewController forKey:@"viewController"];
    [coder encodeInteger:[self.mutableViewController indexOfObject:self.currentViewController] forKey:@"selectedIndex"];
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    self.mutableViewController = [coder decodeObjectForKey:@"viewController"];
    self.segmentedControl.selectedSegmentIndex = 0;
    
    if([coder decodeIntegerForKey:@"selectedIndex"] != NSNotFound) {
        [self showViewController:[self.mutableViewController objectAtIndex:[coder decodeIntegerForKey:@"selectedIndex"]] animated:NO];
    } else {
        [self showViewController:[self.mutableViewController objectAtIndex:0] animated:NO];
    }
}

#pragma mark - Helper
- (BOOL)extendViewControllerBelowNavigationBar:(UIViewController *)aViewController {
    return (aViewController.extendedLayoutIncludesOpaqueBars || (aViewController.edgesForExtendedLayout & UIRectEdgeTop));
}

- (BOOL)extendViewControllerBelowBottomBars:(UIViewController *)aViewController {
    return (aViewController.extendedLayoutIncludesOpaqueBars || (aViewController.edgesForExtendedLayout & UIRectEdgeBottom));
}

- (CGRect)frameForViewController:(UIViewController *)aViewController {
    CGFloat top = 0;
    if(![self extendViewControllerBelowNavigationBar:aViewController]) {
        top += 20;
        
        if(self.navigationController) {
            if(!self.navigationController.navigationBarHidden) {
                top += self.navigationController.navigationBar.frame.size.height;
            }
        }
    }
    
    CGFloat bottom = 0;
    if(![self extendViewControllerBelowBottomBars:aViewController]) {
        if(self.navigationController) {
            if((self.useToolbarItemsOfCurrentViewController && [aViewController.toolbarItems count] > 0) ||
               (!self.useToolbarItemsOfCurrentViewController && [self.toolbarItems count] > 0)) {
                bottom += self.navigationController.toolbar.frame.size.height;
            }
            
            if(self.navigationController.tabBarController) {
                bottom += self.navigationController.tabBarController.tabBar.frame.size.height;
            }
        }
    }
    
    return CGRectMake(0, top, self.contentPlaceholderView.frame.size.width, self.contentPlaceholderView.frame.size.height-top-bottom);
}

- (void)updateContentInsetsForViewController:(UIViewController *)aViewController {
    if([self extendViewControllerBelowNavigationBar:aViewController] || [self extendViewControllerBelowBottomBars:aViewController]) {
        UIEdgeInsets insets = UIEdgeInsetsZero;
        
        if([self extendViewControllerBelowNavigationBar:aViewController]) {
            insets.top += 20;
            
            if(self.navigationController) {
                if(!self.navigationController.navigationBarHidden) {
                    insets.top += self.navigationController.navigationBar.frame.size.height;
                }
            }
        }
        
        if([self extendViewControllerBelowBottomBars:aViewController]) {
            if(self.navigationController) {
                if((self.useToolbarItemsOfCurrentViewController && [aViewController.toolbarItems count] > 0) ||
                   (!self.useToolbarItemsOfCurrentViewController && [self.toolbarItems count] > 0)) {
                    insets.bottom += self.navigationController.toolbar.frame.size.height;
                }
                
                if(self.navigationController.tabBarController) {
                    insets.bottom += self.navigationController.tabBarController.tabBar.frame.size.height;
                }
            }
        }
        
        if([self extendViewControllerBelowBottomBars:aViewController]) {
            insets.bottom += self.bottomLayoutGuide.length;
        }
        
        [aViewController adaptToEdgeInsets:insets];
    }
}

- (void)showViewControllerWithoutAnimation:(UIViewController *)aViewController {
    if(self.currentViewController) {
        [self.currentViewController willMoveToParentViewController:nil];
        
        [self.currentViewController removeFromParentViewController];
        [self.currentViewController.view removeFromSuperview];
        
        [self.currentViewController didMoveToParentViewController:nil];
    }
    
    aViewController.view.frame = [self frameForViewController:aViewController];
    
    [aViewController willMoveToParentViewController:self];
    [self.contentPlaceholderView addSubview:aViewController.view];
    [self addChildViewController:aViewController];
    [aViewController didMoveToParentViewController:self];
}

- (void)showViewControllerWithFlipAnimation:(UIViewController *)aViewController {
    NSInteger oldIndex = self.currentViewController ? [self.mutableViewController indexOfObject:self.currentViewController] : NSNotFound;
    NSInteger newIndex = [self.mutableViewController indexOfObject:aViewController];
    
    UIViewAnimationOptions transition = UIViewAnimationOptionTransitionFlipFromRight;
    if(oldIndex < newIndex)
        transition = UIViewAnimationOptionTransitionFlipFromRight;
    else
        transition = UIViewAnimationOptionTransitionFlipFromLeft;
    
    aViewController.view.frame = [self frameForViewController:aViewController];
    
    [self.currentViewController willMoveToParentViewController:nil];
    [aViewController willMoveToParentViewController:self];
    
    [self.contentPlaceholderView addSubview:aViewController.view];
    [self addChildViewController:aViewController];
    
    UIViewController *oldViewController = self.currentViewController;
    [UIView transitionFromView:self.currentViewController.view toView:aViewController.view duration:0.5 options:transition | UIViewAnimationOptionBeginFromCurrentState completion:^(BOOL finished) {
        [oldViewController removeFromParentViewController];
        if(finished)
            [oldViewController.view removeFromSuperview];
        
        [oldViewController didMoveToParentViewController:nil];
        [self.currentViewController didMoveToParentViewController:self];
    }];
}

- (void)showViewControllerWithSlideInAnimation:(UIViewController *)aViewController {
    NSInteger oldIndex = self.currentViewController ? [self.mutableViewController indexOfObject:self.currentViewController] : NSNotFound;
    NSInteger newIndex = [self.mutableViewController indexOfObject:aViewController];
    BOOL slideFromLeft = oldIndex >= newIndex;
    BOOL animationsRunning = [self.contentPlaceholderView.layer.animationKeys count] > 0 ? YES : NO;
    
    [self.currentViewController willMoveToParentViewController:nil];
    [aViewController willMoveToParentViewController:self];
    
    [self.contentPlaceholderView addSubview:aViewController.view];
    [self addChildViewController:aViewController];
    
    [aViewController didMoveToParentViewController:self];
    
    __block CGRect aViewControllerRect = [self frameForViewController:aViewController];
    if(slideFromLeft)
        aViewControllerRect.origin.x = -self.currentViewController.view.frame.size.width;
    else
        aViewControllerRect.origin.x = self.view.frame.size.width;
    
    aViewController.view.frame = aViewControllerRect;
    
    __block CGRect currentViwControllerRect = [self frameForViewController:self.currentViewController];
    if(slideFromLeft) {
        currentViwControllerRect.origin.x = self.view.frame.size.width;
    } else {
        currentViwControllerRect.origin.x = -self.currentViewController.view.frame.size.width;
    }
    
    __block UIViewController *oldViewController = self.currentViewController;
    [UIView animateWithDuration:0.3 delay:0 options:(animationsRunning ? UIViewAnimationOptionBeginFromCurrentState : 0) animations:^{
        self.currentViewController.view.frame = currentViwControllerRect;
        
        aViewControllerRect.origin.x = 0;
        aViewController.view.frame = aViewControllerRect;
    } completion:^(BOOL finished) {
        [oldViewController removeFromParentViewController];
        if(finished) {
            [oldViewController.view removeFromSuperview];
        }
        
        [oldViewController didMoveToParentViewController:nil];
    }];
}

- (void)showViewController:(UIViewController *)aViewController animated:(BOOL)animated {
    if(!aViewController) {
        [NSException raise:@"RMInvalidCurrentViewController" format:@"-[RMMultipleViewsController %@] has been called with nil as view controller parameter. This is not possible!", NSStringFromSelector(_cmd)];
    } else if([self.mutableViewController indexOfObject:aViewController] == NSNotFound) {
        [NSException raise:@"RMInvalidCurrentViewController" format:@"-[RMMultipleViewsController %@] has been called with a view controller as parameter that does not exist in the view controller array. This is not possible!", NSStringFromSelector(_cmd)];
    }
    
    if(aViewController != self.currentViewController) {
        aViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self updateContentInsetsForViewController:aViewController];
        
        __weak RMMultipleViewsController *blockself = self;
        void(^switchViewController)(void) = ^() {
            if(!animated || blockself.animationStyle == RMMultipleViewsControllerAnimationNone) {
                [blockself showViewControllerWithoutAnimation:aViewController];
            } else if(blockself.animationStyle == RMMultipleViewsControllerAnimationFlip) {
                [blockself showViewControllerWithFlipAnimation:aViewController];
            } else if(blockself.animationStyle == RMMultipleViewsControllerAnimationSlideIn) {
                [blockself showViewControllerWithSlideInAnimation:aViewController];
            } else {
                [blockself showViewControllerWithoutAnimation:aViewController];
            }
            
            blockself.currentViewController = aViewController;
            blockself.segmentedControl.selectedSegmentIndex = [blockself.mutableViewController indexOfObject:aViewController];
            
            if(blockself.useNavigationBarButtonItemsOfCurrentViewController) {
                [blockself.navigationItem setLeftBarButtonItems:aViewController.navigationItem.leftBarButtonItems animated:animated];
                [blockself.navigationItem setRightBarButtonItems:aViewController.navigationItem.rightBarButtonItems animated:animated];
            }
            
            if(blockself.useToolbarItemsOfCurrentViewController)
                [blockself setToolbarItems:aViewController.toolbarItems animated:YES];
            
            if([blockself.toolbarItems count] > 0) {
                [blockself.navigationController setToolbarHidden:NO animated:animated];
            } else {
                [blockself.navigationController setToolbarHidden:YES animated:animated];
            }
        };
        
        if(self.currentViewController && [aViewController isViewLoaded] && animated) {
            switchViewController();
        } else {
            aViewController.view.frame = CGRectMake(0, 0, blockself.view.frame.size.width, blockself.view.frame.size.height);
            switchViewController();
        }
    }
}

#pragma mark - Properties
- (NSMutableArray *)mutableViewController {
    if(!_mutableViewController) {
        self.mutableViewController = [NSMutableArray array];
    }
    
    return _mutableViewController;
}

- (void)setMutableViewController:(NSMutableArray *)newMutableViewController {
    if(newMutableViewController != _mutableViewController) {
        NSMutableArray *items = [NSMutableArray array];
        
        for(id aViewController in newMutableViewController) {
            if(![aViewController isKindOfClass:[UIViewController class]]) {
                [NSException raise:@"RMInvalidViewControllerException" format:@"Tried to set invalid objects as view controllers of RMMultipleViewsController. Object at index %lu is of Class %@ although it should be of Class UIViewController.", (unsigned long)[newMutableViewController indexOfObject:aViewController], NSStringFromClass([aViewController class])];
            } else {
                UIViewController *validViewController = (UIViewController *)aViewController;
                validViewController.multipleViewsController = self;
                
                if(validViewController.title)
                    [items addObject:validViewController.title];
                else
                    [items addObject:@"Unknown"];
            }
        }
        
        _mutableViewController = newMutableViewController;
        
        if(_segmentedControl) {
            [_segmentedControl removeAllSegments];
            for(NSString *aTitle in [items reverseObjectEnumerator]) {
                [_segmentedControl insertSegmentWithTitle:aTitle atIndex:0 animated:NO];
            }
        }
        
        if(_segmentedControl.frame.size.width < 130)
            _segmentedControl.frame = CGRectMake(_segmentedControl.frame.origin.x, _segmentedControl.frame.origin.y, 130, _segmentedControl.frame.size.height);
    }
}

- (NSMutableArray *)viewController {
    return self.mutableViewController;
}

- (void)setViewController:(NSMutableArray *)newViewController {
    self.mutableViewController = [newViewController mutableCopy];
}

- (UIView *)contentPlaceholderView {
    if(!_contentPlaceholderView) {
        self.contentPlaceholderView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentPlaceholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _contentPlaceholderView.backgroundColor = [UIColor whiteColor];
    }
    
    return _contentPlaceholderView;
}

- (UISegmentedControl *)segmentedControl {
    if(!_segmentedControl) {
        NSMutableArray *items = [NSMutableArray array];
        
        if(_mutableViewController) {
            for(UIViewController *aViewController in _mutableViewController) {
                if(aViewController.title)
                    [items addObject:aViewController.title];
                else
                    [items addObject:@"Unknown"];
            }
        } else {
            [items addObjectsFromArray:@[@"Test1", @"Test2", @"Test3"]];
        }
        
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
        [_segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
        
        if(_segmentedControl.frame.size.width < 130)
            _segmentedControl.frame = CGRectMake(_segmentedControl.frame.origin.x, _segmentedControl.frame.origin.y, 130, _segmentedControl.frame.size.height);
    }
    
    return _segmentedControl;
}

#pragma mark - Actions
- (void)segmentedControlTapped:(UISegmentedControl *)aSegmentedControl {
    if(aSegmentedControl == self.segmentedControl) {
        [self showViewController:[self.mutableViewController objectAtIndex:aSegmentedControl.selectedSegmentIndex] animated:YES];
    }
}

@end
