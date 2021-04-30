//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Admin1 on 4/12/20.
//  Copyright © 2020 Admin1. All rights reserved.
//

import UIKit

// MARK: - Extension
extension EmojiArt.EmojiInfo{
    init?(label: UILabel){
        if let attributedText = label.attributedText, let font = attributedText.font{
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributedText.string
            size = Int(font.pointSize)
        } else {
            return nil
        }
    }
}

// MARK: - Class
class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate, EmojiArtViewDelegate, UIPopoverPresentationControllerDelegate {
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Document Info"{
            if let destination = segue.destination.contents as? DocumentInfoViewController{
                document?.thumbnail = emojiArtView.snapshot
                destination.document = document
                if let ppc = destination.popoverPresentationController {
                    ppc.delegate = self
                }
            }
        } else if segue.identifier == "Embed Document Info"{
            embeddedDocumentInfo = segue.destination.contents as? DocumentInfoViewController
        }
    }
    
    private var embeddedDocumentInfo: DocumentInfoViewController?
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    @IBAction func close(BySegue: UIStoryboardSegue){
        done()
    }
    
    @IBOutlet weak var embeddedDocInfoHeight: NSLayoutConstraint!
    @IBOutlet weak var embeddedDocInfoWidth: NSLayoutConstraint!
    
    
    // MARK: - Model
   
    var emojiArt: EmojiArt? {
        get{
            if let url = emojiArtBackgroundImage.url{
                let emojis = emojiArtView.subviews.flatMap { $0 as? UILabel }.flatMap { EmojiArt.EmojiInfo(label: $0) }
                return EmojiArt(url: url, emojis: emojis)
            }
            return nil
        }
        set{
            emojiArtBackgroundImage = (nil, nil)
            emojiArtView.subviews.flatMap {$0 as? UILabel}.forEach { $0.removeFromSuperview() }
            if let url = newValue?.url{
                imageFetcher = ImageFetcher(fetch: url) { (url, image) in
                    DispatchQueue.main.async {
                        self.emojiArtBackgroundImage = (url, image)
                        newValue?.emojis.forEach{
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
                            self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Saving Document
    var document: EmojiArtDocument?
    
    @IBAction func save(_ sender: UIBarButtonItem? = nil) {
        document?.emojiArt = emojiArt
        if document?.emojiArt != nil{
            document?.updateChangeCount(.done)
        }
    }
    
    @IBAction func done(_ sender: UIBarButtonItem? = nil) {
        guard let eavobserver = emojiArtViewObserver else { return }
        NotificationCenter.default.removeObserver(eavobserver)
        save()
        if document?.emojiArt != nil{
            document?.thumbnail = emojiArtView.snapshot
        }
        presentingViewController?.dismiss(animated: true){
            self.document?.close { success in
                guard let observer = self.documentObserver else { return }
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    private var documentObserver: NSObjectProtocol?
    private var emojiArtViewObserver: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        documentObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name.UIDocumentStateChanged,
            object: document,
            queue: OperationQueue.main,
            using: { notification in
                print("document state changed to \(self.document!.documentState)")
                if self.document!.documentState == .normal, let docInfoVC = self.embeddedDocumentInfo{
                    docInfoVC.document = self.document
                    self.embeddedDocInfoWidth.constant = docInfoVC.preferredContentSize.width
                    self.embeddedDocInfoHeight.constant = docInfoVC.preferredContentSize.height
                }
        })
        document?.open { success in
            if success{
                self.title = self.document?.localizedName
                self.emojiArt = self.document?.emojiArt
                self.emojiArtViewObserver = NotificationCenter.default.addObserver(
                    forName: .EmojiArtViewDidChange,
                    object: self.emojiArtView,
                    queue: OperationQueue.main,
                    using: { notification in
                        self.save()
                    }
                )
            }
        }
    }
    
    
    // MARK: - dropZone
    @IBOutlet weak var dropZone: UIView! {
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    // MARK: - EmojiArtView
    lazy var emojiArtView: EmojiArtView = {
        let eav = EmojiArtView()
        eav.delegate = self
        return eav
    }()
    
    func emojiArtViewDidChange(_ sender: EmojiArtView) {
        save()
    }
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet{
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight.constant = scrollView.contentSize.height
        scrollViewWidth.constant = scrollView.contentSize.width
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    private var _emojiBackgroundURL: URL?
    
    var emojiArtBackgroundImage: (url: URL?, image: UIImage?){
        get{
            return (_emojiBackgroundURL, emojiArtView.backgorundImage)
        }
        set{
            _emojiBackgroundURL = newValue.url
            scrollView?.zoomScale = 1.0
            emojiArtView.backgorundImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
            }
        }
    }
    
    // MARK: - emojiCollectionView
    var emojis = "😀😃😄🐱🐶✈️🚗🐰🍕🍔🍎🍩🙂⚽️".map { String($0) }
    
    @IBOutlet weak var emojiCollectionView: UICollectionView! {
        didSet{
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
            emojiCollectionView.dragInteractionEnabled = true
        }
    }
    
    // MARK: - collectionView funcs
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    
    private var font: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
        if let emojiCell = cell as? EmojiCollectionViewCell{
            let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
            emojiCell.label.attributedText = text
        }
        return cell
    }
    
    private func dragItems(at indexPath: IndexPath)-> [UIDragItem]{
        if let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText{
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            dragItem.localObject = attributedString
            return [dragItem]
        } else {
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items{
            if let sourceIndexPath = item.sourceIndexPath{
                if let attributedString = item.dragItem.localObject as? NSAttributedString{
                    collectionView.performBatchUpdates({
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else{
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { (provider, error) in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString {
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                            })
                        } else{
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
    
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    var imageFetcher: ImageFetcher!
    
    private var suppressBadURLWarinigs = false
    
    private func presentBadUrlWarning(for url: URL?){
        if !suppressBadURLWarinigs{
            let alert = UIAlertController(
                title: "Image Transfer Failed",
                message: "Couldn't transfer the dropped image from its source.\nShow this warning in de future?",
                preferredStyle: .alert)
        
            alert.addAction(UIAlertAction(
                title: "Keep Warning",
                style: .default))
        
            alert.addAction(UIAlertAction(
                title: "Stop Warning",
                style: .destructive,
                handler: { action in
                    self.suppressBadURLWarinigs = true
            }))
        
            present(alert, animated: true)
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url, image)
                self.save()
            }
        }
        
        session.loadObjects(ofClass: NSURL.self) { nsurls in
            if let url = nsurls.first as? URL{
                DispatchQueue.global(qos: .userInitiated).async {
                    if let imageData = try? Data(contentsOf: url.imageURL), let image = UIImage(data: imageData){
                        DispatchQueue.main.async {
                            self.emojiArtBackgroundImage = (url, image)
                            self.save()
                        }
                    } else {
                        self.presentBadUrlWarning(for: url)
                    }
                }
            }
            
        }
        
        session.loadObjects(ofClass: UIImage.self) { images in
            if let image = images.first as? UIImage{
                self.imageFetcher.backup = image
            }
        }
    }
    

}
