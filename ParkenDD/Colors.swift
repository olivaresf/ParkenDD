//
//  Colors.swift
//  ParkenDD
//
//  Created by Kilian Költzsch on 06/04/15.
//  Copyright (c) 2015 Kilian Koeltzsch. All rights reserved.
//

import UIKit

struct Colors {
	static let favYellow = UIColor(rgba: "#F9E510")
	static let unfavYellow = UIColor(rgba: "#F4E974")
	
	//New Colors based os Parking space availability
	static let zambeziGrey = UIColor(rgba: "#5C5C5C") // No availability (100%): 0x5C5C5C
	static let purple = UIColor(rgba: "#7F0304")      // Few Spaces Left (85%-99%): 0x7F0304
	static let greenCyan = UIColor(rgba: "#1DAA8C")   // Spaces Left (40%-84%): 0x1DAA8C
	static let darkGreen = UIColor(rgba: "#006A39")   // Many Spaces Left: (0%-40%):  0x006A39
	
	static func colorBasedOnPercentage(_ percentage: Double) -> UIColor {
		
		let percentageInt = Int(percentage * 100)
		
		switch percentageInt {
		case 100: return Colors.zambeziGrey
		case 85...99: return Colors.purple
		case 40...84: return Colors.greenCyan
		default: return Colors.darkGreen
			
		}
	}
	
}

extension UIColor {
	/**
	Initializes and returns a color object from a given hex string.
	Props to github.com/yeahdongcn/UIColor-Hex-Swift

	- parameter rgba: hex string

	- returns: color object
	*/
	convenience init(rgba: String) {
		var red:   CGFloat = 0.0
		var green: CGFloat = 0.0
		var blue:  CGFloat = 0.0
		var alpha: CGFloat = 1.0

		if rgba.hasPrefix("#") {
			let index   = rgba.characters.index(rgba.startIndex, offsetBy: 1)
			let hex     = rgba.substring(from: index)
			let scanner = Scanner(string: hex)
			var hexValue: CUnsignedLongLong = 0
			if scanner.scanHexInt64(&hexValue) {
				switch hex.characters.count {
				case 3:
					red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
					green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
					blue  = CGFloat(hexValue & 0x00F)              / 15.0
					alpha = CGFloat(hexValue & 0x000F)             / 15.0
				case 4:
					red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
					green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
					blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
					alpha = CGFloat(hexValue & 0x000F)             / 15.0
				case 6:
					red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
					green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
					blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
				case 8:
					red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
					green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
					blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
					alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
				default:
					preconditionFailure("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
				}
			} else {
				preconditionFailure("Scan hex error")
			}
		} else {
			preconditionFailure("Invalid RGB string, missing '#' as prefix")
		}
		self.init(red:red, green:green, blue:blue, alpha:alpha)
	}
}
