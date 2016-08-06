//
//  MoviesViewController.swift
//  Flicks
//
//  Created by tianhe_wang on 8/4/16.
//  Copyright © 2016 tianhe_wang. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var gridView: UICollectionView!
    @IBOutlet weak var viewSwitch: UISegmentedControl!
    @IBOutlet weak var errorView: UIView!


    var movies: [NSDictionary]?
    var endpoint: String!
    var refreshControl: UIRefreshControl?

    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        gridView.dataSource = self
        gridView.delegate = self
        
        loadMovieData()
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refreshControlAction(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl!, atIndex: 0)
        super.viewDidLoad()
    }

    func refreshControlAction(refreshControl: UIRefreshControl) {
        loadMovieData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movies = movies {
            return movies.count
        } else {
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = movies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        let baseUrl = "https://image.tmdb.org/t/p/w500"

        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL (string: baseUrl + posterPath)
            cell.posterView.setImageWithURL(imageUrl!)
        }

        cell.titleLabel.text = title
        cell.overviewLabel.text = overview

        cell.accessoryType = UITableViewCellAccessoryType.None
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    @IBAction func onViewSwitch(sender: AnyObject) {
        print(viewSwitch.selectedSegmentIndex)
        if viewSwitch.selectedSegmentIndex == 0 {
            tableView.hidden = false
            gridView.hidden = true
        } else {
            tableView.hidden = true
            gridView.hidden = false
        }
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let movies = movies {
            return movies.count
        } else {
            return 0
        }
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = gridView.dequeueReusableCellWithReuseIdentifier("GridCell", forIndexPath: indexPath) as! GridViewCell
        let movie = movies![indexPath.row]
        let baseUrl = "https://image.tmdb.org/t/p/w500"
        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL (string: baseUrl + posterPath)
            cell.posterView.setImageWithURL(imageUrl!)
        }
        return cell
    }

    //     MARK: - Navigation
    //     In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        let detailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.movie = movie
    }
    
    private func loadMovieData() {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(
            URL: url!,
            cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval: 10)
        
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,
                                                                     completionHandler: { (dataOrNil, response, error) in
                                                                        if let data = dataOrNil {
                                                                            if self.viewSwitch.selectedSegmentIndex == 0 {
                                                                                self.tableView.hidden = false
                                                                                self.gridView.hidden = true
                                                                            } else {
                                                                                self.gridView.hidden = false
                                                                                self.tableView.hidden = true
                                                                            }
                                                                            self.errorView.hidden = true
                                                                            if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                                                                                data, options:[]) as? NSDictionary {
                                                                                self.movies = responseDictionary["results"] as! [NSDictionary]
                                                                                self.tableView.reloadData()
                                                                                self.gridView.reloadData()
                                                                            }
                                                                        } else {
                                                                            self.tableView.hidden = true
                                                                            self.gridView.hidden = true
                                                                            self.errorView.hidden = false
                                                                        }
                                                                        self.refreshControl!.endRefreshing()
                                                                        MBProgressHUD.hideHUDForView(self.view, animated: true)
        })
        task.resume()
    }
}
