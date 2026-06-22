import Foundation

// MARK: - Country
/// Một quốc gia với mã vùng và độ dài số quốc gia hợp lệ (heuristic theo từng nước).
struct Country: Equatable {
    let iso: String        // ISO 3166-1 alpha-2, vd "VN"
    let name: String       // tên hiển thị
    let dialCode: String   // mã vùng, vd "+84"
    let minLen: Int        // số chữ số tối thiểu của số quốc gia (sau khi bỏ số 0 đầu)
    let maxLen: Int        // số chữ số tối đa

    /// Cờ emoji suy ra từ mã ISO (ghép 2 ký tự Regional Indicator).
    var flag: String {
        iso.unicodeScalars.reduce(into: "") { acc, s in
            if let scalar = UnicodeScalar(127397 + s.value) { acc.unicodeScalars.append(scalar) }
        }
    }

    /// Kiểm tra `rawInput` có phải số hợp lệ cho quốc gia này không.
    func isValid(_ rawInput: String) -> Bool {
        (minLen...maxLen).contains(nationalDigits(rawInput).count)
    }

    /// Chuẩn hoá: chỉ giữ chữ số và bỏ một số 0 đứng đầu (định dạng nội địa).
    func nationalDigits(_ rawInput: String) -> String {
        var digits = rawInput.filter(\.isNumber)
        if digits.hasPrefix("0") { digits.removeFirst() }
        return digits
    }
}

// MARK: - Countries
/// Danh sách quốc gia thường dùng kèm độ dài số quốc gia (xấp xỉ, không thay thế libphonenumber).
enum Countries {
    static let `default` = all.first { $0.iso == "VN" }!

    static let all: [Country] = [
        Country(iso: "VN", name: "Việt Nam",          dialCode: "+84",  minLen: 9,  maxLen: 10),
        Country(iso: "US", name: "United States",     dialCode: "+1",   minLen: 10, maxLen: 10),
        Country(iso: "GB", name: "United Kingdom",    dialCode: "+44",  minLen: 10, maxLen: 10),
        Country(iso: "JP", name: "Japan",             dialCode: "+81",  minLen: 9,  maxLen: 10),
        Country(iso: "KR", name: "South Korea",       dialCode: "+82",  minLen: 9,  maxLen: 10),
        Country(iso: "CN", name: "China",             dialCode: "+86",  minLen: 11, maxLen: 11),
        Country(iso: "SG", name: "Singapore",         dialCode: "+65",  minLen: 8,  maxLen: 8),
        Country(iso: "TH", name: "Thailand",          dialCode: "+66",  minLen: 9,  maxLen: 9),
        Country(iso: "MY", name: "Malaysia",          dialCode: "+60",  minLen: 9,  maxLen: 10),
        Country(iso: "ID", name: "Indonesia",         dialCode: "+62",  minLen: 9,  maxLen: 11),
        Country(iso: "PH", name: "Philippines",       dialCode: "+63",  minLen: 10, maxLen: 10),
        Country(iso: "IN", name: "India",             dialCode: "+91",  minLen: 10, maxLen: 10),
        Country(iso: "AU", name: "Australia",         dialCode: "+61",  minLen: 9,  maxLen: 9),
        Country(iso: "FR", name: "France",            dialCode: "+33",  minLen: 9,  maxLen: 9),
        Country(iso: "DE", name: "Germany",           dialCode: "+49",  minLen: 10, maxLen: 11),
        Country(iso: "IT", name: "Italy",             dialCode: "+39",  minLen: 9,  maxLen: 10),
        Country(iso: "ES", name: "Spain",             dialCode: "+34",  minLen: 9,  maxLen: 9),
        Country(iso: "RU", name: "Russia",            dialCode: "+7",   minLen: 10, maxLen: 10),
        Country(iso: "CA", name: "Canada",            dialCode: "+1",   minLen: 10, maxLen: 10),
        Country(iso: "BR", name: "Brazil",            dialCode: "+55",  minLen: 10, maxLen: 11),
        Country(iso: "TW", name: "Taiwan",            dialCode: "+886", minLen: 9,  maxLen: 9),
        Country(iso: "HK", name: "Hong Kong",         dialCode: "+852", minLen: 8,  maxLen: 8),
        Country(iso: "AE", name: "United Arab Emirates", dialCode: "+971", minLen: 9, maxLen: 9),
        Country(iso: "SA", name: "Saudi Arabia",      dialCode: "+966", minLen: 9,  maxLen: 9),
        Country(iso: "LA", name: "Laos",              dialCode: "+856", minLen: 8,  maxLen: 10),
        Country(iso: "KH", name: "Cambodia",          dialCode: "+855", minLen: 8,  maxLen: 9),
        Country(iso: "MM", name: "Myanmar",           dialCode: "+95",  minLen: 8,  maxLen: 10),
    ]
}
