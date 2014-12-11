//
//  ViewController.swift
//  lostfaces
//
//  Created by Aleksandr Salo on 12/9/14.
//  Copyright (c) 2014 Aleksandr Salo. All rights reserved.
//

import UIKit
import Photos

let reuseIdentifier = "PhotoCell"
let albumName = "lostFaces"

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate{
    
    var albumFound: Bool = false
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult!
    
//Actions and Outlets

    @IBAction func btnCamera(sender: AnyObject) {
        println("Camera")
        if UIImagePickerController.isSourceTypeAvailable(.Camera){
            //load camera interface
            var picker: UIImagePickerController = UIImagePickerController()
            picker.sourceType = UIImagePickerControllerSourceType.Camera
            picker.delegate = self
            picker.allowsEditing = true
            self.presentViewController(picker, animated: true, completion: nil)
            
        }else{
            //no camera available
            var alert = UIAlertController(title: "Error", message: "No camera available", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default,
                handler: {(alertAction) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnPhotoAlbum(sender: AnyObject) {
        println("Album")
        var picker: UIImagePickerController = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBOutlet var collectionView: UICollectionView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //check if the folder exists, if doesn't - create it
        let fetchOption = PHFetchOptions()
        fetchOption.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOption)
        if collection.firstObject != nil{
            //found the album
            self.albumFound = true
            self.assetCollection = collection.firstObject as PHAssetCollection
        }else{
            //Album placeholder for the asset collection, used to reference collection in completion handler
            var albumPlaceholder:PHObjectPlaceholder!
            //create the folder
            NSLog("\nFolder \"%@\" does not exist\nCreating now...", albumName)
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumName)
                albumPlaceholder = request.placeholderForCreatedAssetCollection
                },
                completionHandler: {(success:Bool, error:NSError!)in
                    NSLog("Creation of folder -> %@", (success ? "Success":"Error!"))
                    self.albumFound = (success ? true:false)
                    if(success){
                        let collection = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([albumPlaceholder.localIdentifier], options: nil)
                        self.assetCollection = collection?.firstObject as PHAssetCollection
                    }
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        //fetch the photos from collection
        self.navigationController?.hidesBarsOnTap = false
        self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: nil)
        
        //Handle no photos in the assetCollection
        //..have a label that says no photos
        
        self.collectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "viewLargePhoto"){
            let controller: ViewPhotoViewController = segue.destinationViewController as ViewPhotoViewController
            let indexPath: NSIndexPath = self.collectionView.indexPathForCell(sender as UICollectionViewCell)!
            
            controller.photosAsset = self.photosAsset
            controller.assetCollection = self.assetCollection
            controller.index = indexPath.item            
        }
    }

//UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        var count = 0
        if self.photosAsset != nil{
            count = self.photosAsset.count
        }
        
        return count
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell: PhotoThumbnailCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as PhotoThumbnailCollectionViewCell
        
        //modify cell
        let asset: PHAsset = self.photosAsset[indexPath.item] as PHAsset
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: PHImageManagerMaximumSize, contentMode: .AspectFill, options: nil, resultHandler: {(result, info) in
            cell.setThumbnailImage(result)
        })
        return cell
    }
    
//UICollectionViewDelegateFlowLayout methods
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat{
        return 4
    }
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat{
        return 1
    }

//UIImagePickerControllerDelegate Methods
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!){
        let image = info.objectForKey("UIImagePickerControllerOriginalImage") as UIImage
        
        //Implement if allowing user to edit the selected image
        //let editedImage = info.objectForKey("UIImagePickerControllerEditedImage") as UIImage
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0), {
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
                let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection, assets: self.photosAsset)
                albumChangeRequest.addAssets([assetPlaceholder])
                }, completionHandler: {(success, error)in
                    dispatch_async(dispatch_get_main_queue(), {
                        NSLog("Adding Image to Library -> %@", (success ? "Sucess":"Error!"))
                        picker.dismissViewControllerAnimated(true, completion: nil)
                    })
            })
            
        })
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

}




