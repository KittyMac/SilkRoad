import Foundation
import Hitch
import Spanker
import Sextant
import Flynn
import Jib

public typealias VoidPtr = UnsafePointer<UInt8>
public typealias UTF8Ptr = UnsafePointer<UInt8>
public typealias CallbackPtr = @convention(c) (VoidPtr?, UTF8Ptr?) -> ()

@_cdecl("silkroad_add")
public func add(x: Int, y: Int) -> Int {
    return x + y
}

@_cdecl("silkroad_uppercase")
public func uppercase(string: UTF8Ptr?) -> UTF8Ptr? {
    guard let string = string else { return nil }
    return Hitch(utf8: string).uppercase().export().0
}

@_cdecl("silkroad_jsonpath")
public func jsonpath(queryUTF8: UTF8Ptr?,
                     jsonUTF8: UTF8Ptr?) -> UTF8Ptr? {
    guard let queryUTF8 = queryUTF8 else { return nil }
    guard let jsonUTF8 = jsonUTF8 else { return nil }
    let query = Hitch(utf8: queryUTF8)
    let json = Hitch(utf8: jsonUTF8)
    let results = JsonElement(unknown: [])
    
    json.parsed { root in
        root?.query(forEach: query) { result in
            results.append(value: result)
        }
    }
    
    return results.toHitch().export().0
}


public class Lowercase: Actor {
    internal func _beToLowercase(string: String) -> String {
        return string.lowercased()
    }
    internal func _beToLowercase(hitch: Hitch) -> Hitch {
        return hitch.lowercase()
    }
}

@_cdecl("silkroad_flynnTest")
public func flynnTest(string: UTF8Ptr?, _ returnCallback: CallbackPtr?, _ returnInfo: VoidPtr?) {
    guard let string = string else { return }
    
    let lowercase = Lowercase()
    lowercase.beToLowercase(hitch: Hitch(utf8: string), Flynn.any) { result in
        returnCallback?(returnInfo, result.export().0)
    }
}

@_cdecl("silkroad_eval")
public func eval(javascriptUTF8: UTF8Ptr?) -> UTF8Ptr? {
    guard let javascriptUTF8 = javascriptUTF8 else { return nil }
    let jib = Jib()
    return jib[hitch: HalfHitch(utf8: javascriptUTF8)]?.export().0
}
