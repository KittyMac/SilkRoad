import Foundation
import Hitch
import Spanker
import Sextant
import Flynn
import Jib
import Picaroon

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


// Override print so that it goes to Android logcat
public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items.map { "\($0)" }.joined(separator: separator)
    Flynn.syslog("TAG", output)
}

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

@_cdecl("silkroad_flynnTest")
public func flynnTest(string: UTF8Ptr?,
                      _ returnCallback: CallbackPtr?,
                      _ returnInfo: VoidPtr?) {
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

@_cdecl("silkroad_download")
public func download(url urlUTF8: UTF8Ptr?,
                     _ returnCallback: CallbackPtr?,
                     _ returnInfo: VoidPtr?) {
    guard let urlUTF8 = urlUTF8 else { return }
    let url = Hitch(utf8: urlUTF8)
    
    // For TLS to work in FoundationNetworking, we either need to disable
    // peer validation (bad) or provide a cacert.pem file.
    
    // To disable peer validation
    //setenv("URLSessionCertificateAuthorityInfoFile", "INSECURE_SSL_NO_VERIFY", 1)
    
    // To provide a cacert file. Note that this relies on Java -> JNI code to set the
    // TMPDIR env variable so we know where we can write the file to
    let tmpDir: String = String(cString: getenv("TMPDIR"))
    let cacertPath = "\(tmpDir)/cacert.pem"
    try? SilkRoadFrameworkPamphlet.CacertPem().description.write(toFile: cacertPath,
                                                                 atomically: false,
                                                                 encoding: .utf8)
    setenv("URLSessionCertificateAuthorityInfoFile", cacertPath, 1)
        
    HTTPSession.oneshot.beRequest(url: url.description,
                                  httpMethod: "GET",
                                  params: [:],
                                  headers: [:],
                                  cookies: nil,
                                  proxy: nil,
                                  body: nil, Flynn.any) { data, httpResponse, error in
        if let data = data {
            returnCallback?(returnInfo, Hitch(data: data).export().0)
            return
        }
        if let error = error {
            returnCallback?(returnInfo, Hitch(string: error).export().0)
            return
        }
        let hitch: Hitch = "unknown error"
        returnCallback?(returnInfo, hitch.export().0)
        return
    }
}


public class Lowercase: Actor {
    internal func _beToLowercase(string: String) -> String {
        return string.lowercased()
    }
    internal func _beToLowercase(hitch: Hitch) -> Hitch {
        return hitch.lowercase()
    }
}
