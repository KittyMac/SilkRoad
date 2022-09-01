import Foundation
import Hitch
import Spanker

public typealias UTF8Ptr = UnsafePointer<UInt8>

@_cdecl("silkroad_add")
public func add(x: Int, y: Int) -> Int {
    return x + y
}

@_cdecl("silkroad_uppercase")
public func uppercase(string: UTF8Ptr?) -> UTF8Ptr? {
    guard let string = string else { return nil }
    return Hitch(utf8: string).uppercase().export().0
}

