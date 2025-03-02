//
//  File.swift
//  
//
//  Created by Dai Pham on 08/02/2024.
//

import Foundation

public class DateConvert {
    
    private var date:Date
    private var dateString:String
    
    public init?(
        date: Date? = nil,
        dateString: String? = nil,
        isUTC:Bool = true,
        formatOutput:String = "yyyy-MM-dd'T'HH:mm:ss"
    ) {
        var localDate:Date?
        var localDateString:String?
        if let dateString {
            self.dateString = dateString
            if let date = Self.fromStringToDate(dateString: dateString) {
                localDate = date
                localDateString = Self.fromDateToString(date: date, format: formatOutput, isUTC: isUTC)
            }
        }
        if let date {
            localDate = date
            localDateString = Self.fromDateToString(date: date, format: formatOutput)
        }
        guard let localDate, let localDateString else {
            return nil
        }
        self.date = localDate
        self.dateString = localDateString
    }
    
    public func getDate() -> Date {
        return date
    }
    
    public func getDateString() -> String {
        return dateString
    }
    
    public func stringToServer(
        format:String = "yyyy-MM-dd'T'HH:mm:ss"
    ) -> String? {
        return Self.fromDateToString(date: date, format: format, isUTC: true)
    }
    
    private static func fromDateToString(
        date:Date,
        format:String = "yyyy-MM-dd'T'HH:mm:ss",
        isUTC:Bool = false // when convert to string server from date UTC should true for this param
    ) -> String {
        let df = DateFormatter()
        df.dateFormat = format
        if isUTC {
            df.timeZone = TimeZone(identifier: "UTC")
        }
        let locale = Locale(identifier: "en_US_POSIX")
        df.locale = locale
        let dateString = df.string(from: date)
        return dateString
    }
    
    private static func fromStringToDate(
        dateString:String
    ) -> Date? {
        let df = DateFormatter()
        let format = Self.detectFormatString(dateString)
        df.dateFormat = format
        let locale = Locale(identifier: "en_US_POSIX")
        df.locale = locale
        df.timeZone = TimeZone(identifier:"UTC")
        let dateFromString = df.date(from: dateString)
        return dateFromString
    }
    
    public static func detectFormatString(_ dateString:String) -> String {
//        let regex1 = "^\\d{4}-\\d{2}-\\d{2}[']?T[']?\\d{2}:\\d{2}:\\d{2}$"
        let regex2 = "^\\d{4}-\\d{2}-\\d{2}[']?T[']?\\d{2}:\\d{2}:\\d{2}.+(.*)$"
        
        if NSPredicate(format: "SELF MATCHES %@", regex2).evaluate(with: dateString) {
            return "yyyy-MM-dd'T'HH:mm:ss.SSS"
        }
        return "yyyy-MM-dd'T'HH:mm:ss"
    }
}
