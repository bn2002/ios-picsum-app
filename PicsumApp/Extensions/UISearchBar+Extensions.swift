//
//  UISearchBar+Extensions.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import UIKit

extension UISearchBar {
    var textField: UITextField {
        if #available(iOS 13.0, *) {
            return self.searchTextField
        } else {
            return self.value(forKey: "searchField") as! UITextField
        }
    }
}
