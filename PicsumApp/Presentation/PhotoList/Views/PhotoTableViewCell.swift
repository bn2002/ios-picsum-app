//
//  PhotoTableViewCell.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//
import UIKit

final class PhotoTableViewCell: UITableViewCell {
    static let reuseIdentifier = "PhotoTableViewCell"
    
    // MARK: - UI Components
    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    private var aspectRatioConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.photoImageView.image = nil
        self.authorLabel.text = nil
        self.sizeLabel.text = nil
        self.loadingIndicator.stopAnimating()
    }
    
    // MARK: - Setup
    private func setupViews() {
        self.contentView.addSubview(self.photoImageView)
        self.contentView.addSubview(self.authorLabel)
        self.contentView.addSubview(self.sizeLabel)
        self.contentView.addSubview(self.loadingIndicator)
        
        NSLayoutConstraint.activate([
            self.photoImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8),
            self.photoImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            self.photoImageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),
            
            self.authorLabel.topAnchor.constraint(equalTo: self.photoImageView.bottomAnchor, constant: 8),
            self.authorLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            self.authorLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),
            
            self.sizeLabel.topAnchor.constraint(equalTo: self.authorLabel.bottomAnchor, constant: 4),
            self.sizeLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            self.sizeLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),
            self.sizeLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -8),
            
            self.loadingIndicator.centerXAnchor.constraint(equalTo: self.photoImageView.centerXAnchor),
            self.loadingIndicator.centerYAnchor.constraint(equalTo: self.photoImageView.centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with photo: Photo) {
        self.authorLabel.text = "\(photo.author) - ID: \(photo.id)"
        
        if photo.isHighResolution {
            self.sizeLabel.text = "Size: Original(\(photo.sizeText)) - Optimized(\(photo.optimizedSizeText))"
        } else {
            self.sizeLabel.text = "Size: \(photo.sizeText)"
        }
        
        self.aspectRatioConstraint?.isActive = false
    
        self.aspectRatioConstraint = self.photoImageView.heightAnchor.constraint(equalTo: self.photoImageView.widthAnchor, multiplier: photo.aspectRatio)
        self.aspectRatioConstraint?.priority = .defaultHigh
        self.aspectRatioConstraint?.isActive = true
        
        // Only clear image and show loading if we don't have an image
        if self.photoImageView.image == nil {
            self.loadingIndicator.startAnimating()
        }
        
    }
    
    func setImage(data: Data) {
        if let image = UIImage(data: data) {
            self.photoImageView.image = image
            self.loadingIndicator.stopAnimating()
        }
    }
} 
