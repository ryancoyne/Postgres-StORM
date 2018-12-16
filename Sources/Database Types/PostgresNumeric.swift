//
//  Numeric.swift
//  COpenSSL
//
//  Created by Ryan Coyne on 12/14/18.
//

import Foundation

struct PostgresNumeric : CustomStringConvertible, CustomDatabaseTypeConvertible {
    
    /// This is the description of the posgres numeric field.  We didn't want to include everything about the optionals and the number formatter.
    var description: String {
        if self.value == nil { return "nil" }
        return "\(self.value!)"
    }
    /// This is the database type that is needed when going and creating the database column itself.
    var type : String {
        return "numeric(\(precision),\(scale))"
    }
    private var _value : Double? = nil
    private var _numberFormatter : NumberFormatter = {
        var nbFtr = NumberFormatter()
        return nbFtr
    }()
    
    init(_ precision: Int, _ scale: Int, default: Double?=nil) {
        self.precision = precision
        self.scale = scale
        self._value = `default`
    }
    
    /// This is the entire amount of allowed digits, including the decimal amount.
    var precision : Int

    /// This is the scale, or number of allowed decimal places to the right of the decimal point.
    var scale : Int
    
    ///  This is the string value of the numeric field containing all the characters for the defined precision.
    var stringValue : String? {
        // The precision is the entire number of allowed numeric digits.
        if _value == nil { return nil }
        makeSureScaleAndPrecisionSet()
        return _numberFormatter.string(from: _value! as NSNumber)!
    }
    
    ///  This is the double value of the numeric field.
    var value : Double? {
        get {
            return _value
        }
        set {
            _value = newValue
        }
    }
    
    ///  This is the decimal value of the numeric field.
    var decimalValue : Decimal? {
        if _value == nil { return nil }
        return NSNumber(floatLiteral: _value!).decimalValue
    }
    
    private func makeSureScaleAndPrecisionSet() {
        if self._numberFormatter.maximumFractionDigits != self.scale {
            self._numberFormatter.maximumFractionDigits = self.scale
            self._numberFormatter.minimumFractionDigits = self.scale
        }
        let minIntegerDigits = (self.precision-self.scale)
        if self._numberFormatter.maximumIntegerDigits != minIntegerDigits || self._numberFormatter.minimumIntegerDigits != minIntegerDigits {
            self._numberFormatter.maximumIntegerDigits = minIntegerDigits
            self._numberFormatter.minimumIntegerDigits = minIntegerDigits
        }
    }
    
    ///  An easy function to use to get the value from the database into a double value for the numeric field.
    mutating func from(_ value : Any?) {
        if let theString = value as? String {
            self._value = self._numberFormatter.number(from: theString)?.doubleValue
        }
    }
    
    //MARK: - Just PostgresNumeric with PostgresNumeric operators
    static func +=(lhs : inout PostgresNumeric,  rhs : PostgresNumeric?) {
        if lhs._value == nil || rhs == nil || rhs?._value == nil { return }
        lhs._value! += rhs!._value!
    }
    static func +(lhs : PostgresNumeric, rhs : PostgresNumeric?) -> PostgresNumeric {
        if lhs._value == nil || rhs == nil || rhs?._value == nil { return lhs }
        return PostgresNumeric(lhs.precision, lhs.scale, default: lhs._value! - rhs!._value!)
    }
    static func *=(lhs : inout PostgresNumeric,  rhs : PostgresNumeric?) {
        if lhs._value == nil || rhs == nil || rhs?._value == nil { return }
        lhs._value! *= rhs!._value!
    }
    static func *(lhs : PostgresNumeric, rhs : PostgresNumeric?) -> PostgresNumeric {
        if lhs._value == nil || rhs == nil || rhs?._value == nil { return lhs }
        return PostgresNumeric(lhs.precision, lhs.scale, default: lhs._value! - rhs!._value!)
    }
    static func -=(lhs : inout PostgresNumeric,  rhs : PostgresNumeric?) {
        if lhs._value == nil || rhs == nil || rhs?._value == nil { return }
        lhs._value! -= rhs!._value!
    }
    static func -(lhs : PostgresNumeric, rhs : PostgresNumeric?) -> PostgresNumeric {
        if lhs._value == nil || rhs == nil || rhs?._value == nil { return lhs }
        return PostgresNumeric(lhs.precision, lhs.scale, default: lhs._value! - rhs!._value!)
    }
    //MARK: - Just Double with PostgresNumeric operators
    static func +=(lhs : inout PostgresNumeric,  rhs : Double?) {
        if lhs._value == nil || rhs == nil { return }
        lhs._value! += rhs!
    }
    static func +(lhs : PostgresNumeric, rhs : Double?) -> PostgresNumeric {
        if lhs._value == nil || rhs == nil { return lhs }
        return PostgresNumeric(lhs.precision, lhs.scale, default: lhs._value! - rhs!)
    }
    static func *=(lhs : inout PostgresNumeric,  rhs : Double?) {
        if lhs._value == nil || rhs == nil { return }
        lhs._value! *= rhs!
    }
    static func *(lhs : PostgresNumeric, rhs : Double?) -> PostgresNumeric {
        if lhs._value == nil || rhs == nil { return lhs }
        return PostgresNumeric(lhs.precision, lhs.scale, default: lhs._value! - rhs!)
    }
    static func -=(lhs : inout PostgresNumeric,  rhs : Double?) {
        if lhs._value == nil || rhs == nil { return }
        lhs._value! -= rhs!
    }
    static func -(lhs : PostgresNumeric, rhs : Double?) -> PostgresNumeric {
        if lhs._value == nil || rhs == nil { return lhs }
        return PostgresNumeric(lhs.precision, lhs.scale, default: lhs._value! - rhs!)
    }
    
}
