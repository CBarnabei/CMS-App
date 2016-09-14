//
//  CMSThemeBrain.swift
//  Temp CMS Now
//
//  Created by Matthew Benjamin on 2/6/16.
//  Copyright © 2016 CMS. All rights reserved.
//

import UIKit

struct CMSColorProfile {
    
    // TODO: static func init shortcuts.
    
    static func selectedProfile() -> CMSColorProfile! {
        switch CMSSettingsBrain.selectedThemeIndex() {
        case 0: return darkNightProfile()
        case 1: return tangerineProfile()
        case 2: return yellowJasmineProfile()
        case 3: return mintGreenProfile()
        case 4: return springGreenProfile()
        case 5: return skyBlueProfile()
        case 6: return oceanBlueProfile()
        case 7: return turquoiseProfile()
        case 8: return roseProfile()
        case 9: return royalPurpleProfile()
        case 10: return byzantineProfile()
        case 11: return persianPinkProfile()
        case 12: return flamingoPinkProfile()
        default: return nil
        }
    }
    
    static func colorForCategoryTitle(title: String) -> UIColor {
        switch title {
        case "Lunch": return CMSColorProfile.oceanBlueProfile().dark
        case "General": return CMSColorProfile.darkNightProfile().dark
        case "Events": return CMSColorProfile.mintGreenProfile().dark
        case "Birthdays": return CMSColorProfile.flamingoPinkProfile().dark
        case "Sports": return CMSColorProfile.tangerineProfile().dark
        case "Clubs": return CMSColorProfile.byzantineProfile().dark
        case "Counselor": return CMSColorProfile.turquoiseProfile().dark
        case "Principal": return CMSColorProfile.yellowJasmineProfile().dark
        case "Nurse": return CMSColorProfile.roseProfile().dark
        case "Student School Board": return CMSColorProfile.skyBlueProfile().dark
        case "Graduation": return CMSColorProfile.springGreenProfile().dark
        case "PTSA": return CMSColorProfile.royalPurpleProfile().dark
        case "FCCTC": return CMSColorProfile.persianPinkProfile().dark
        default: fatalError("An invalid category label was passed to \(#function) in \(#file).")
        }
    }
    
    static func colorForCategoryKey(key: String) -> UIColor {
        let title = CMSSettingsBrain.categoriesForKeys[key]
        assert(title != nil, "An invalid category key was passed to \(#function) in \(#file).")
        return colorForCategoryTitle(title!)
    }
    
    static func darkNightProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0x262626, darkHex: 0x1e1e1e, themeIndex: 0)
    }
    
    static func tangerineProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0xFF8C58, darkHex: 0xD37347, themeIndex: 1)
    }
    
    static func yellowJasmineProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0xFFE26B, darkHex: 0xD3B847, themeIndex: 2)
    }
    
    static func mintGreenProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0x89E761, darkHex: 0x61B53D, themeIndex: 3)
    }
    
    static func springGreenProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0x56CF87, darkHex: 0x33985C, themeIndex: 4)
    }
    
    static func skyBlueProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0x5799C0, darkHex: 0x326786, themeIndex: 5)
    }
    
    static func oceanBlueProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0x6177C8, darkHex: 0x3B4D8F, themeIndex: 6)
    }
    
    static func turquoiseProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0x08E8DE, darkHex: 0x00CED1, themeIndex: 7)
    }
    
    static func roseProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0xFF5858, darkHex: 0xD34747, themeIndex: 8)
    }
    
    static func royalPurpleProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0x995AC6, darkHex: 0x69368D, themeIndex: 9)
    }
    
    static func byzantineProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0xC351C3, darkHex: 0x892E89, themeIndex: 10)
    }
    
    static func persianPinkProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0xD85AAC, darkHex: 0xA3377D, themeIndex: 11)
    }
    
    static func flamingoPinkProfile() -> CMSColorProfile {
        return CMSColorProfile(lightHex: 0xFC8EAC, darkHex: 0xFC7B9A, themeIndex: 12)
    }
    
    let light: UIColor
    let dark: UIColor
    
    let themeIndex: Int
    
    init(lightHex: UInt32, darkHex: UInt32, themeIndex: Int) {
        let lightColor = UIColor(hex: lightHex, alpha: 1.0)
        let darkColor = UIColor(hex: darkHex, alpha: 1.0)
        self.init(light: lightColor, dark: darkColor, themeIndex: themeIndex)
    }
    
    private init(light: UIColor, dark: UIColor, themeIndex: Int) {
        self.light = light
        self.dark = dark
        self.themeIndex = themeIndex
    }
    
}

extension UIColor {
    
    convenience init(hex: UInt32, alpha: CGFloat) {
        
        let redComponent = (hex & 0xFF0000) >> 16
        let greenComponent = (hex & 0x00FF00) >> 8
        let blueComponent = (hex & 0x0000FF)
        
        let redFraction: CGFloat = CGFloat(redComponent) / 0xFF
        let greenFraction: CGFloat = CGFloat(greenComponent) / 0xFF
        let blueFraction: CGFloat = CGFloat(blueComponent) / 0xFF
        
        self.init(red: redFraction, green: greenFraction, blue: blueFraction, alpha: alpha)
        
    }
    
}