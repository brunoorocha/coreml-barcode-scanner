//
//  Product.swift
//  core-ml-project
//
//  Created by Bruno Rocha on 04/07/19.
//  Copyright © 2019 Bruno Rocha. All rights reserved.
//

import Foundation


struct Product: Decodable {
    var description: String
    var thumbnail: String
    var avgPrice: Float?
    
    private enum CodingKeys: String, CodingKey {
        case description
        case thumbnail
        case avgPrice = "avg_price"
    }
    
    
}
