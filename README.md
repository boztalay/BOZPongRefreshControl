BOZPongRefreshControl
=====================

A pull-down-to-refresh control for iOS that plays pong

<p align="center"><img src="http://i.imgur.com/cdh7eVE.gif"/></p>

Installation
------------

It's on CocoaPods! Put ```pod 'BOZPongRefreshControl'``` in your Podfile.

Alternatively, just place ```BOZPongRefreshControl.h``` and ```BOZPongRefreshControl.m``` in your project anywhere you'd like.

Usage
--------

Attach it to a ```UITableView``` or ```UIScrollView``` like so:

```objective-c
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* NOTE: Do NOT attach the refresh control in viewDidLoad!
     * If you do this here, it'll act very funny if you have
     * a navigation bar or other such similar thing that iOS
     * automatically offsets content for. You have to wait for
     * the subviews to get laid out first so the refresh
     * control knows how big that offset is!
     */
}

- (void)viewDidLayoutSubviews
{
    self.pongRefreshControl = [BOZPongRefreshControl attachToTableView:self.tableView
                                                     withRefreshTarget:self
                                                      andRefreshAction:@selector(refreshTriggered)];
}
```

Then, implement ```UIScrollViewDelegate``` in your ```UIViewController``` if you haven't already, and pass the calls through to the refresh control:

```objective-c
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.pongRefreshControl scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.pongRefreshControl scrollViewDidEndDragging];
}
```

Lastly, make sure you've implemented the ```refreshAction``` you passed it earlier to listen for refresh triggers:

```objective-c
- (void)refreshTriggered
{
    //Go and load some data

    //Finshed loading the data, reset the refresh control
    [self.pongRefreshControl finishedLoading];
}
```

For more details, check out the demo app's code. It has examples for using the refresh control on a ```UIScrollView``` and outside of a ```UITableViewController```.

Configuration
-------------

- Set the foreground color with the ```foregroundColor``` property
- Set the background color with the ```backgroundColor``` property
- Adjust how fast it plays by changing the ```totalHorizontalTravelTimeForBall``` property

Known Issues/To Do
------------------

- It'll interfere with ```UIScrollView``` content that's above ```y = 0.0f```
- I haven't tested it, but I'd be willing to bet it looks a bit silly on iPads
- Test it out on a physical iPhone 6/+
- The behavior of the paddles needs a little work
- Tests!
