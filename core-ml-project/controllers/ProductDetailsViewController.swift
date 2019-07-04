//
//  ProductDetailsViewController.swift
//  core-ml-project
//
//  Created by Thiago Valente on 04/07/19.
//  Copyright © 2019 Bruno Rocha. All rights reserved.
//

import UIKit

class ProductDetailsViewController: UIViewController {
    
    var barcode: String = ""
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productPriceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.topItem?.title = "Câmera"
        self.productImageView.downloaded(from: "https://cdn-cosmos.bluesoft.com.br/products/\(self.barcode)")
        self.barcodeLabel.text = self.barcode
        requestProductData()
    }
    
    func requestProductData() {
        let service = ApiService()
        let endpoint = "/gtins/\(barcode)"
        service.request(on: endpoint) { (product: Product?, error: Error?) in
            if let product = product {
                self.productNameLabel.text = product.description
                self.productPriceLabel.text = String(format: "%.2f", product.avgPrice ?? 0.0)
            }
        }
    }
    
    @IBAction func openGoogleTap(_ sender: Any) {
        guard let url = URL(string: "https://www.google.com/search?q=\(self.barcode)") else { return }
        UIApplication.shared.open(url)
    }
}
