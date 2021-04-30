//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Admin1 on 4/12/20.
//  Copyright © 2020 Admin1. All rights reserved.
//

import UIKit

// MARK: - Protocol
protocol EmojiArtViewDelegate: class{
    func emojiArtViewDidChange(_ sender: EmojiArtView)
}

// MARK: - Notification
extension Notification.Name {
    static let EmojiArtViewDidChange = Notification.Name("EmojiArtViewDidChange")
}

// MARK: - Class
class EmojiArtView: UIView, UIDropInteractionDelegate {
    
    // MARK: - inits
    override init(frame: CGRect){
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: - Model
    var backgorundImage: UIImage? { didSet { setNeedsDisplay() }}
    
    // MARK: - delegate
    weak var delegate: EmojiArtViewDelegate?
    
    // MARK: - funcs
    private func setup(){
        addInteraction(UIDropInteraction(delegate: self))
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: NSAttributedString.self) { providers in
            let dropPoint = session.location(in: self)
            for attributedString in providers as? [NSAttributedString] ?? []{
                self.addLabel(with: attributedString, centeredAt: dropPoint)
                self.delegate?.emojiArtViewDidChange(self)
                NotificationCenter.default.post(name: .EmojiArtViewDidChange, object: self)
            }
        }
    }
    
    func addLabel(with attributedString: NSAttributedString, centeredAt point: CGPoint){
        let label = UILabel()
        label.attributedText = attributedString
        label.backgroundColor = .clear
        label.sizeToFit()
        label.center = point
        addSubview(label)
    }
    
    override func draw(_ rect: CGRect) {
        backgorundImage?.draw(in: bounds)
    }
 

}
