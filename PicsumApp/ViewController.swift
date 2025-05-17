//
//  ViewController.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//

import UIKit

class ViewController: UIViewController {
    private let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = "Hello, World!"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }


}

