//
//  DocumentInfoViewController.swift
//  EmojiArt
//
//  Created by Admin1 on 21/1/21.
//  Copyright © 2021 Admin1. All rights reserved.
//

import UIKit
//se usa este VC para mostrar la fecha de creacion del documento, su tamaño y el thumbnail en un VC presentado con show modally, en un popover y en un containerView 
class DocumentInfoViewController: UIViewController {
    
    
    override func viewDidLoad() {
        updateUI()
    }
    
    // MARK: - Model
    var document: EmojiArtDocument? {
        didSet{
            updateUI()
        }
    }
    
    // MARK: - Outlets
    @IBOutlet weak var topLevelView: UIStackView!
    @IBOutlet weak var thumbnailAspectRatio: NSLayoutConstraint!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var returnButton: UIButton!
    
    // MARK: - Date Formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - funcs
    private func updateUI(){
        if sizeLabel != nil, createdLabel != nil,
            let url = document?.fileURL,
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path){
            sizeLabel.text = "\(attributes[.size] ?? 0) bytes"
            if let created = attributes[.creationDate] as? Date {
                createdLabel.text = dateFormatter.string(from: created)
            }
        }
        if thumbnailImageView != nil, thumbnailAspectRatio != nil, let thumbnail = document?.thumbnail{
            thumbnailImageView.image = thumbnail
            thumbnailImageView.removeConstraint(thumbnailAspectRatio)
            thumbnailAspectRatio = NSLayoutConstraint(
                item: thumbnailImageView,
                attribute: .width,
                relatedBy: .equal,
                toItem: thumbnailImageView,
                attribute: .height,
                multiplier: thumbnail.size.width / thumbnail.size.height,
                constant: 0)
            thumbnailImageView.addConstraint(thumbnailAspectRatio)
        }
        if presentationController is UIPopoverPresentationController {
            thumbnailImageView?.isHidden = true
            returnButton?.isHidden = true
            view.backgroundColor = .clear
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let fittedSize = topLevelView?.sizeThatFits(UILayoutFittingCompressedSize){
            preferredContentSize = CGSize(width: fittedSize.width + 30, height: fittedSize.height + 30)
        }
    }
    
    @IBAction func returnToDocument() {
        presentingViewController?.dismiss(animated: true)
    }



}
