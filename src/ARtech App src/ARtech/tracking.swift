//
//  tracking.swift
//  ARtech
//
//  Created by Tiffany Madruga on 11/21/19.
//  Copyright © 2019 Tiffany Madruga. All rights reserved.
//

import Foundation

struct TrackingImage: Decodable {
    let name: String
    let bio: String
    let image: String
    let source: String
    let textNode: Bool
    let webNode: Bool
    let imageNode: Bool
}
