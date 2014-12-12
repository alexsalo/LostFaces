//
//  ViewPhotoViewController.swift
//  lostfaces
//
//  Created by Aleksandr Salo on 12/9/14.
//  Copyright (c) 2014 Aleksandr Salo. All rights reserved.
//

import UIKit
import Photos
import MessageUI

class ViewPhotoViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult!
    var index: Int = 0
    var myMail: MFMailComposeViewController!

    @IBAction func btnMetadata(sender: AnyObject) {
        println("Cancel");
        var img = self.photosAsset[self.index] as PHAsset
        //println(img.description)
        //println(img.)
        
        img.requestContentEditingInputWithOptions(nil) { (contentEditingInput: PHContentEditingInput!, _) -> Void in
            //Get full image
            let url = contentEditingInput.fullSizeImageURL
            let orientation = contentEditingInput.fullSizeImageOrientation
            var inputImage = CIImage(contentsOfURL: url)
            inputImage = inputImage.imageByApplyingOrientation(orientation)
            
            for (key, value) in inputImage.properties() {
                println("key: \(key)")
                println("value: \(value)")
            }
        }
        
        let alert = UIAlertController(title: "Metadata", message:
            img.description, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnCancel(sender: AnyObject) {
        println("Cancel");
        self.navigationController?.popToRootViewControllerAnimated(true)        
    }
    
    @IBAction func btnExport(sender: AnyObject) {
        println("Export");
        
        
        
        if(MFMailComposeViewController.canSendMail()){
            println("Can send email");
            myMail = MFMailComposeViewController()
            myMail.mailComposeDelegate = self
            
            //myMail.mailComposeDelegate
            
            // set the subject
            myMail.setSubject("My report")
            
            //To recipients
            var toRecipients = ["alexsalovrn@gmail.com"]
            myMail.setToRecipients(toRecipients)
            
            //CC recipients
            //var ccRecipients = ["tzhang85@gatech.edu"]
            //myMail.setCcRecipients(ccRecipients)
            
            //BCC recipients
            //var bccRecipients = ["tzhang85@gatech.edu"]
            //myMail.setBccRecipients(ccRecipients)
            
            //Add some text to the message body
            var sentfrom = "Email sent from lostfaces app"
            myMail.setMessageBody(sentfrom, isHTML: true)
            
            //Include an attachment
            var image = imgView.image
            var imageData = UIImageJPEGRepresentation(image, 1.0)
            
            myMail.addAttachmentData(imageData, mimeType: "image/jped", fileName: "lostface_image")
            
            //Display the view controller
            self.presentViewController(myMail, animated: true, completion: nil)
        }
        else{
            println("Email is unavailable");
            var alert = UIAlertController(title: "Alert", message: "Your device cannot send emails", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func btnTrash(sender: AnyObject) {
        println("Trash");
        let alert = UIAlertController(title: "Delete Image", message: "Are you sure you want to delete this image?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default,
            handler: {(alertAction)in
                PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                    //Delete Photo
                    let request = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection)
                    request.removeAssets([self.photosAsset[self.index]])
                    },
                    completionHandler: {(success, error)in
                        NSLog("\nDeleted Image -> %@", (success ? "Success":"Error!"))
                        alert.dismissViewControllerAnimated(true, completion: nil)
                        if(success){
                            // Move to the main thread to execute
                            dispatch_async(dispatch_get_main_queue(), {
                                self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: nil)
                                if(self.photosAsset.count == 0){
                                    println("No Images Left!!")
                                    self.navigationController?.popToRootViewControllerAnimated(true)
                                }else{
                                    if(self.index >= self.photosAsset.count){
                                        self.index = self.photosAsset.count - 1
                                    }
                                    self.displayPhoto()
                                }
                            })
                        }else{
                            println("Error: \(error)")
                        }
                })
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: {(alertAction)in
            //Do not delete photo
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBOutlet var imgView: UIImageView!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.hidesBarsOnTap = true
        displayPhoto()
    }
    
    func displayPhoto(){
        // Set targetSize of image to iPhone screen size
        let screenSize: CGSize = UIScreen.mainScreen().bounds.size
        let targetSize = CGSizeMake(screenSize.width, screenSize.height)
        
        let imageManager = PHImageManager.defaultManager()
        var ID = imageManager.requestImageForAsset(self.photosAsset[self.index] as PHAsset, targetSize: targetSize, contentMode: .AspectFit, options: nil, resultHandler: {
            (result, info)->Void in
            self.imgView.image = result
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mailComposeController(controller: MFMailComposeViewController!,
        didFinishWithResult result: MFMailComposeResult,
        error: NSError!){
            
            switch(result.value){
            case MFMailComposeResultSent.value:
                println("Email sent")
                
            default:
                println("Whoops")
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)
    }

//HHTP Request
    func httpRequest(){
        
    }
}
