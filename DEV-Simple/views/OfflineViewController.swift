//
//  OfflineViewController.swift
//  DEV-Simple
//
//  Created by Jacob Boyd on 7/3/19.
//  Copyright © 2019 DEV. All rights reserved.
//

import UIKit

class OfflineViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var drawingCanvas: DEVCanvasView!
    var selectedCell: DEVColorCollectionViewCell?

    let colors = [
        // This are RGB values, just be sure to divide by 255
        UIColor(red: 244/255, green: 144/255, blue: 142/255, alpha: 1),
        UIColor(red: 242/255, green: 240/255, blue: 151/255, alpha: 1),
        UIColor(red: 136/255, green: 176/255, blue: 220/255, alpha: 1),
        UIColor(red: 247/255, green: 181/255, blue: 209/255, alpha: 1),
        UIColor(red: 83/255, green: 196/255, blue: 175/255, alpha: 1),
        UIColor(red: 253/255, green: 227/255, blue: 140/255, alpha: 1)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // register the VC as the delegate, datasource and then connect
        // the collectionViewCell with xib file
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(
            UINib(nibName: "DEVColorCollectionViewCell", bundle: Bundle.main),
            forCellWithReuseIdentifier: DEVColorCollectionViewCell.cellId)

        //Subscribe to reachability changes notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reachabilityChanged),
            name: .flagsChanged,
            object: Network.reachability)
    }

    // MARK: - Reachability
    @objc private func reachabilityChanged(note: Notification) {
        guard let reachability = note.object as? Reachability else {
            return
        }

        // If the user gains connection, dismiss the VC
        switch reachability.status {
        case .wifi:
            self.dismissBtnTapped(self)
        case .wwan:
            self.dismissBtnTapped(self)
        default:
            break
        }
    }

    @IBAction func dismissBtnTapped(_ sender: Any) {
        if let presentingVC = self.presentingViewController {
            presentingVC.dismiss(animated: true, completion: nil)
        }
    }

}

extension OfflineViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DEVColorCollectionViewCell.cellId,
                for: indexPath) as? DEVColorCollectionViewCell else {
                    return UICollectionViewCell()
            }
            cell.configureCell(bgColor: colors[indexPath.item])
            // Set the selectedCell as the first color by default
            if indexPath.item == 0 {
                self.selectedCell = cell
                cell.setSelected(true)
            }
            return cell
    }

    // When a cell is selected, update the UI to reflect the selection
    // and change the strokeColor for drawing
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? DEVColorCollectionViewCell, selectedCell != cell {
            selectedCell?.setSelected(false)
            cell.setSelected(true)
            self.selectedCell = cell

            self.drawingCanvas.setStrokeColor(colors[indexPath.item])
        }
    }
}
