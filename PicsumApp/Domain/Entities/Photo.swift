//
//  Photo.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//
import Foundation

struct Photo {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: URL
    let downloadURL: URL

    var aspectRatio: CGFloat {
        return CGFloat(height) / CGFloat(width)
    }

    var sizeText: String {
        return "\(width) × \(height)"
    }
}

extension Photo: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, author, width, height
        case url
        case downloadURL = "download_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        author = try container.decode(String.self, forKey: .author)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        let urlString = try container.decode(String.self, forKey: .url)
        let downloadString = try container.decode(String.self, forKey: .downloadURL)
        guard let url = URL(string: urlString), let downloadURL = URL(string: downloadString) else {
            throw DecodingError.dataCorruptedError(forKey: .url,
                                                   in: container,
                                                   debugDescription: "Invalid URL string.")
        }
        self.url = url
        self.downloadURL = downloadURL
    }
}
