//
//  ViewController.swift
//  ParkenDD
//
//  Created by Kilian Koeltzsch on 18/01/15.
//  Copyright (c) 2015 Kilian Koeltzsch. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet weak var tableView: UITableView!

	// FIXME: This is definitely not the right way of doing this...
	let refreshControl = UIRefreshControl()

	// Store the single parking lots once they're retrieved from the server
	// a single subarray for each section
	var parkinglots: [Parkinglot] = []
	var defaultSortedParkinglots: [Parkinglot] = []
	var sectionNames: [String] = []

	override func viewDidLoad() {
		super.viewDidLoad()

		// display the standard reload button
		showReloadButton()

		// pretty blue navbar with white buttons
		let navBar = self.navigationController?.navigationBar
		navBar!.barTintColor = UIColor(hue: 0.58, saturation: 1.0, brightness: 0.33, alpha: 1.0)
		navBar!.translucent = true
		navBar!.tintColor = UIColor.whiteColor()

		// pretty shadowy fat title
		let shadow = NSShadow()
		shadow.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
		shadow.shadowOffset = CGSizeMake(0, 1)
		let color = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
		let font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 21.0)
		var attrsDict = [NSObject: AnyObject]()
		attrsDict[NSForegroundColorAttributeName] = color
		attrsDict[NSShadowAttributeName] = shadow
		attrsDict[NSFontAttributeName] = font
		navBar!.titleTextAttributes = attrsDict

		// Call this here to prevent the UIRefreshControl sometimes looking messed up when waking the app
		self.refreshControl.endRefreshing()

		// FIXME: For some reason the UI freezes up when it tries to update itself on start with a failing internet connection
		// Maybe because it tries to fire an alert on a ViewController that isn't ready yet?
		updateData()

		refreshControl.addTarget(self, action: "updateData", forControlEvents: UIControlEvents.ValueChanged)
		tableView.insertSubview(refreshControl, atIndex: 0)
	}

	override func viewWillAppear(animated: Bool) {
		sortLots()
		tableView.reloadData()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showParkinglotMap" {
			let indexPath = tableView.indexPathForSelectedRow()
			let selectedParkinglot = parkinglots[indexPath!.row]
			let mapVC: MapViewController = segue.destinationViewController as! MapViewController
			mapVC.detailParkinglot = selectedParkinglot
			mapVC.allParkinglots = parkinglots
		}
	}

	func updateData() {
		showActivityIndicator()
		ServerController.sendParkinglotDataRequest() {
			(secNames, plotList, updateError) in
			if let error = updateError {

				if error == "requestError" {
					// Give the user a notification that new data can't be fetched
					var alertController = UIAlertController(title: NSLocalizedString("REQUEST_ERROR_TITLE", comment: "Connection Error"), message: NSLocalizedString("REQUEST_ERROR", comment: "Couldn't fetch data. You appear to be disconnected from the internet."), preferredStyle: UIAlertControllerStyle.Alert)
					alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
					self.presentViewController(alertController, animated: true, completion: nil)
					if self.parkinglots.isEmpty {
						// TODO: The app has just tried updating on "an empty stomach"
						// It is now stuck in a state where it displays "Refreshing..." on the tableview and the pull-to-refresh works awkwardly
						// Do something about this
					}
				} else if error == "serverError" {
					// Give the user a notification that data from the server can't be read
					var alertController = UIAlertController(title: NSLocalizedString("SERVER_ERROR_TITLE", comment: "Server Error"), message: NSLocalizedString("SERVER_ERROR", comment: "Couldn't read data from server. Please try again in a few moments."), preferredStyle: UIAlertControllerStyle.Alert)
					alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
					self.presentViewController(alertController, animated: true, completion: nil)
				}

				// Stop the UIRefreshControl without updating the date
				self.refreshControl.endRefreshing()
				self.showReloadButton()

			} else if let secNames = secNames, plotList = plotList {
				self.sectionNames = secNames
				self.parkinglots = plotList
				self.defaultSortedParkinglots = plotList
				self.sortLots()

				// Reload the tableView on the main thread, otherwise it will only update once the user interacts with it
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					self.tableView.reloadData()

					// Update the displayed "Last update: " time in the UIRefreshControl
					let formatter = NSDateFormatter()
					formatter.dateFormat = "dd.MM. HH:mm"
					let updateString = NSLocalizedString("LAST_UPDATE", comment: "Last update:")
					let title = "\(updateString) \(formatter.stringFromDate(NSDate()))"
					let attributedTitle = NSAttributedString(string: title, attributes: nil)
					self.refreshControl.attributedTitle = attributedTitle

					// Stop the UIRefreshControl
					self.refreshControl.endRefreshing()
					self.showReloadButton()
				})
			}
		}
	}

	func sortLots() {
		let sortingType = NSUserDefaults.standardUserDefaults().stringForKey("SortingType")
		switch sortingType! {
		case "location":
			println("sorting after location")
		case "alphabetical":
			parkinglots.sort({
				$0.name < $1.name
			})
		case "free":
			parkinglots.sort({
				$0.free > $1.free
			})
		default:
			parkinglots = defaultSortedParkinglots
		}
	}

	// MARK: - IBActions

	@IBAction func settingsButtonTapped(sender: UIBarButtonItem) {
		performSegueWithIdentifier("showSettingsView", sender: self)
	}

	// MARK: - Reload Button Stuff

	func showReloadButton() {
		let refreshButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "updateData")
		self.navigationItem.rightBarButtonItem = refreshButton
	}

	func showActivityIndicator() {
		let activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 20, 20))
		activityIndicator.startAnimating()
		let activityItem = UIBarButtonItem(customView: activityIndicator)
		self.navigationItem.rightBarButtonItem = activityItem
	}

	// MARK: - UITableViewDataSource

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if parkinglots.count == 0 {
			let messageLabel = UILabel(frame: CGRectMake(0, 0, view.bounds.width, view.bounds.height))
			messageLabel.text = NSLocalizedString("NO_DATA", comment: "Refreshing...")
			messageLabel.textColor = UIColor.blackColor()
			messageLabel.numberOfLines = 0
			messageLabel.textAlignment = NSTextAlignment.Center
			messageLabel.font = UIFont(name: "HelveticaNeue-LightItalic", size: 20)
			messageLabel.sizeToFit()

			tableView.backgroundView = messageLabel
			tableView.separatorStyle = UITableViewCellSeparatorStyle.None
			return 0
		}
		// TODO: tableView.backgroundView is still set to messageLabel... Can be seen if dragged down far enough. Damn.
		tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine

		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return parkinglots.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: ParkinglotTableViewCell = tableView.dequeueReusableCellWithIdentifier("parkinglotCell") as! ParkinglotTableViewCell

		let thisLot = parkinglots[indexPath.row]

		cell.parkinglotNameLabel.text = thisLot.name
		cell.parkinglotLoadLabel.text = "\(thisLot.free)"

		if let thisLotAddress = parkinglotData[thisLot.name] {
			cell.parkinglotAddressLabel.text = thisLotAddress
		} else {
			cell.parkinglotAddressLabel.text = NSLocalizedString("UNKNOWN_ADDRESS", comment: "unknown address")
		}

		var load: Int = Int(round(100 - (Double(thisLot.free) / Double(thisLot.count) * 100)))
		if load < 0 {
			// Apparently there can be 52 empty spots on a 50 spot parking lot...
			load = 0
		}

		// Maybe a future version of the scraper will be able to read the tendency as well
		if thisLot.state == lotstate.nodata && thisLot.free == -1 {
			cell.parkinglotTendencyLabel.text = NSLocalizedString("UNKNOWN_LOAD", comment: "unknown")
		} else if thisLot.state == lotstate.closed {
			cell.parkinglotTendencyLabel.text = NSLocalizedString("CLOSED", comment: "closed")
		} else {
			let localizedOccupied = NSLocalizedString("OCCUPIED", comment: "occupied")
			cell.parkinglotTendencyLabel.text = "\(load)% \(localizedOccupied)"
		}

		// Normalize all label colors to black, otherwise weird things happen with placeholder cells
		cell.parkinglotNameLabel.textColor = UIColor.blackColor()
		cell.parkinglotAddressLabel.textColor = UIColor.blackColor()
		cell.parkinglotLoadLabel.textColor = UIColor.blackColor()
		cell.parkinglotTendencyLabel.textColor = UIColor.blackColor()

		switch parkinglots[indexPath.row].state {
		case lotstate.many:
			cell.parkinglotStateImage.image = UIImage(named: "parkinglotStateMany")
		case lotstate.few:
			cell.parkinglotStateImage.image = UIImage(named: "parkinglotStateFew")
		case lotstate.full:
			cell.parkinglotStateImage.image = UIImage(named: "parkinglotStateFull")
		case lotstate.closed:
			cell.parkinglotStateImage.image = UIImage(named: "parkinglotStateClosed")
		default:
			cell.parkinglotStateImage.image = UIImage(named: "parkinglotStateNodata")
			cell.parkinglotLoadLabel.text = "?"
			cell.parkinglotNameLabel.textColor = UIColor.grayColor()
			cell.parkinglotAddressLabel.textColor = UIColor.grayColor()
			cell.parkinglotLoadLabel.textColor = UIColor.grayColor()
			cell.parkinglotTendencyLabel.textColor = UIColor.grayColor()
		}

		return cell
	}

	// MARK: - UITableViewDelegate

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		performSegueWithIdentifier("showParkinglotMap", sender: self)
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

}

