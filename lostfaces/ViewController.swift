//
//  ViewController.swift
//  lostfaces
//
//  Created by Aleksandr Salo on 12/9/14.
//  Copyright (c) 2014 Aleksandr Salo. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

let reuseIdentifier = "PhotoCell"
let albumName = "lostFaces"

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate{
    
    var albumFound: Bool = false
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult!
    var assetThumbnailSize:CGSize!
    let editMode = false
    let fetchOptions = PHFetchOptions()
    
    //camera
    let captureSesion = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    let stillImageOutput = AVCaptureStillImageOutput()
    
//Actions and Outlets

    @IBAction func btnCamera(sender: AnyObject) {
        println("Camera")
        
        /*
        captureSesion.sessionPreset = AVCaptureSessionPresetPhoto
        let devices = AVCaptureDevice.devices()
        println(devices)
        for device in devices{
            if device.hasMediaType(AVMediaTypeVideo){
                if device.position == AVCaptureDevicePosition.Back{
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        if captureDevice != nil{
            beginSession()
        }*/
        
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera){
            //load camera interface
            var picker: UIImagePickerController = UIImagePickerController()
            picker.sourceType = UIImagePickerControllerSourceType.Camera
            picker.delegate = self
            picker.allowsEditing = editMode
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
    
    @IBAction func btnTakePhoto(sender: AnyObject) {
        takePhoto()
    }
    
    
    @IBAction func btnPhotoAlbum(sender: AnyObject) {
        println("Album")
        var picker: UIImagePickerController = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker.delegate = self
        picker.allowsEditing = editMode
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    @IBOutlet var collectionView: UICollectionView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Check if the folder exists, if not, create it
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let first_Obj:AnyObject = collection.firstObject{
            //found the album/Users/salo/Documents/ExampleappusingPhotosframework/README.md
            self.albumFound = true
            self.assetCollection = first_Obj as PHAssetCollection
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
        println("ViewWillAppear")
        
        // Get size of the collectionView cell for thumbnail image
        let scale:CGFloat = UIScreen.mainScreen().scale
        let cellSize = (self.collectionView.collectionViewLayout as UICollectionViewFlowLayout).itemSize
        self.assetThumbnailSize = CGSizeMake(cellSize.width, cellSize.height)
        
        //fetch the photos from collection
        self.navigationController?.hidesBarsOnTap = false   //!! Use optional chaining
        self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: fetchOptions)
        
        //TODO: Insert a label that says 'No Photos' when empty
        
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
        return 1
    }
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat{
        return 1
    }

//UIImagePickerControllerDelegate Methods
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!){
        let image = info.objectForKey("UIImagePickerControllerOriginalImage") as UIImage
        
        println(image.description)
        
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
    
//camera funcs
    func beginSession(){
        configureDevice()
        var err : NSError? = nil
        captureSesion.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        if err != nil{
            println("eroor: \(err?.localizedDescription)")
        }
        
        //preview on the screen what camera sees: make FACES FINDS here!
        var previewLayer = AVCaptureVideoPreviewLayer(session: captureSesion)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        
        var outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        stillImageOutput.outputSettings = outputSettings
        if captureSesion.canAddOutput(stillImageOutput){
            println("stilImageOutput Added")
            captureSesion.addOutput(stillImageOutput)
        }
        else{
            println("Faild to add stilImageOutput")
        }
        
        
        captureSesion.startRunning()
        self.navigationController?.hidesBarsOnTap
        //takePhoto()
        
        
    }
    
    func configureDevice(){
        if let device = captureDevice{
            device.lockForConfiguration(nil)
            device.focusMode = .AutoFocus
            device.unlockForConfiguration()
        }
    }
    
    func takePhoto(){
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo){
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection){
                (imageSampleBuffer : CMSampleBuffer!, _) in
                
                let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                var pickedImage: UIImage? = UIImage(data: imageDataJpeg)
                //self.imgViewPhoto.image = pickedImage
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0), {
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                        let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(pickedImage)
                        let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
                        let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection, assets: self.photosAsset)
                        albumChangeRequest.addAssets([assetPlaceholder])
                        }, completionHandler: {(success, error)in
                            dispatch_async(dispatch_get_main_queue(), {
                                NSLog("Adding Image to Library -> %@", (success ? "Sucess":"Error!"))
                            })
                    })
                })
                println("Captured image has been put to app's album")
        
            }
        }else{
            println("No video media type connection available")
        }
    }

}




