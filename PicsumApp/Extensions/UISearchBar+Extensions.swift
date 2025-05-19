//
//  UISearchBar+Extensions.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import UIKit

extension UISearchBar {
    var textField: UITextField {
        return self.value(forKey: "searchField") as! UITextField
    }
}
