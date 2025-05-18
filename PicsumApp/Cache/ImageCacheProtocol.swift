//
//  ImageCacheProtocol.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 19/5/25.
//
import Foundation
import UIKit

protocol ImageCacheProtocol {
    func getImage(for key: String) -> Data?
    func setImage(_ image: Data, for key: String)
    func removeImage(for key: String)
    func clear()
}
