//
//  PhotoThumbnailCollectionViewCell.swift
//  lostfaces
//
//  Created by Aleksandr Salo on 12/9/14.
//  Copyright (c) 2014 Aleksandr Salo. All rights reserved.
//

import UIKit

class PhotoThumbnailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imgView: UIImageView!
    
    func setThumbnailImage(thumbnailImage: UIImage){
        self.imgView.image = thumbnailImage
    }
}