import Foundation

enum MeasurementUnit: String, CaseIterable {
    case centimeters = "cm"
    case inches = "in"
    
    var displayName: String {
        switch self {
        case .centimeters:
            return "Centimeters"
        case .inches:
            return "Inches"
        }
    }
    
    var shortName: String {
        return rawValue
    }
}

// Fractional inch utilities
struct FractionalInch {
    let whole: Int
    let numerator: Int
    let denominator: Int
    
    init(whole: Int, numerator: Int, denominator: Int) {
        self.whole = whole
        self.numerator = numerator
        self.denominator = denominator
    }
    
    init(from decimal: Double) {
        let wholePart = Int(decimal)
        let fractionalPart = decimal - Double(wholePart)
        
        // Convert to nearest 1/8th inch
        let eighths = Int(round(fractionalPart * 8))
        
        if eighths == 0 {
            self.whole = wholePart
            self.numerator = 0
            self.denominator = 1
        } else if eighths == 4 {
            self.whole = wholePart
            self.numerator = 1
            self.denominator = 2
        } else if eighths == 2 {
            self.whole = wholePart
            self.numerator = 1
            self.denominator = 4
        } else if eighths == 6 {
            self.whole = wholePart
            self.numerator = 3
            self.denominator = 4
        } else {
            self.whole = wholePart
            self.numerator = eighths
            self.denominator = 8
        }
    }
    
    var decimalValue: Double {
        return Double(whole) + (Double(numerator) / Double(denominator))
    }
    
    var displayString: String {
        if numerator == 0 {
            return "\(whole)"
        } else if whole == 0 {
            return "\(numerator)/\(denominator)"
        } else {
            return "\(whole) \(numerator)/\(denominator)"
        }
    }
}

// Measurement conversion utilities
struct MeasurementConverter {
    static let cmToInch: Double = 0.393701
    static let inchToCm: Double = 2.54
    
    static func cmToInches(_ cm: Double) -> Double {
        return cm * cmToInch
    }
    
    static func inchesToCm(_ inches: Double) -> Double {
        return inches * inchToCm
    }
    
    static func formatMeasurement(_ value: Double, unit: MeasurementUnit) -> String {
        switch unit {
        case .centimeters:
            return String(format: "%.1f", value)
        case .inches:
            let fractional = FractionalInch(from: value)
            return fractional.displayString
        }
    }
    
    static func parseMeasurement(_ string: String, unit: MeasurementUnit) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch unit {
        case .centimeters:
            return Double(trimmed)
        case .inches:
            return parseFractionalInch(trimmed)
        }
    }
    
    static func parseFractionalInch(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle simple decimal
        if let decimal = Double(trimmed) {
            return decimal
        }
        
        // Handle fractions like "1/2", "3/4"
        if trimmed.contains("/") && !trimmed.contains(" ") {
            let parts = trimmed.split(separator: "/")
            guard parts.count == 2,
                  let numerator = Double(parts[0]),
                  let denominator = Double(parts[1]),
                  denominator != 0 else {
                return nil
            }
            return numerator / denominator
        }
        
        // Handle mixed numbers like "12 3/8", "5 1/2"
        if trimmed.contains(" ") && trimmed.contains("/") {
            let parts = trimmed.split(separator: " ")
            guard parts.count == 2,
                  let whole = Double(parts[0]) else {
                return nil
            }
            
            let fractionPart = String(parts[1])
            let fractionParts = fractionPart.split(separator: "/")
            guard fractionParts.count == 2,
                  let numerator = Double(fractionParts[0]),
                  let denominator = Double(fractionParts[1]),
                  denominator != 0 else {
                return nil
            }
            
            return whole + (numerator / denominator)
        }
        
        return nil
    }
} 