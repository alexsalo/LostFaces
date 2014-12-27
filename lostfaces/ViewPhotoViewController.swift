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
import Foundation

let uploadURL = "http://requestb.in/1gywwg51"

class ViewPhotoViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult!
    var index: Int = 0
    var myMail: MFMailComposeViewController!
    
    @IBAction func swipeImg(sender: UIGestureRecognizer) {
        if let swipeGesture = sender as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Right:
                println("Swiped right")
                if index > 0{
                    index--
                    displayPhoto()
                }
            case UISwipeGestureRecognizerDirection.Left:
                println("Swiped left")
                if index < self.photosAsset.count - 1{
                    index++
                    displayPhoto()
                }
            case UISwipeGestureRecognizerDirection.Up:
                println("Swiped Up")
                composeEmail()
            case UISwipeGestureRecognizerDirection.Down:
                println("Swiped Down")
                self.sendPhotoToApi()
            default:
                break
            }
        }
    }
    

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
        composeEmail()
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
    
//EMAILING
    
    func composeEmail(){
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
    func sendPhotoToApi(){
        let configName = "edu.baylor.ecs"
        let sessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(configName)
        let session = NSURLSession(configuration: sessionConfig)
        // Prepare the URL Request
        let request = urlRequestWithImage(imgView.image, text: "test")
        let task = session.dataTaskWithRequest(request!)
        task.resume()
        println("Sending photo to API")
    }
    
    func urlRequestWithImage(image: UIImage?, text: String) -> NSURLRequest? {
        
        let url = NSURL(string: uploadURL)
        let request = NSMutableURLRequest(URL: url!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.HTTPMethod = "POST"
        
        var jsonObject = NSMutableDictionary()
        jsonObject["text"] = text
        if let image = image {
            jsonObject["image_details"] = extractDetailsFromImage(image)
            //var imageData = UIImageJPEGRepresentation(image, 1.0)
            //jsonObject["imageData"] = imageData
        }
        
        // Create the JSON payload
        var jsonError: NSError?
        let jsonData = NSJSONSerialization.dataWithJSONObject(jsonObject, options: nil, error: &jsonError)
        if (jsonData != nil) {
            request.HTTPBody = jsonData
        } else {
            if let error = jsonError {
                println("JSON Error: \(error.localizedDescription)")
            }
        }
        
        return request
    }
    
    func extractDetailsFromImage(image: UIImage) -> NSDictionary {
        var resultDict = NSMutableDictionary()
        resultDict["height"] = image.size.height
        resultDict["width"] = image.size.width
        resultDict["orientation"] = image.imageOrientation.rawValue
        resultDict["scale"] = image.scale
        resultDict["description"] = image.description
        return resultDict.copy() as NSDictionary
    }
    
//Upload to FTP
    
}
