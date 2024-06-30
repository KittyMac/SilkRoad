import Foundation
import Hitch
import Spanker
import Sextant
import Flynn
import Jib
import Picaroon
import Spyglass
import Gzip
import MailPacket

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
    
    #if swift(>=5.9)
    print("Swift 5.9")
    #elseif swift(>=5.8)
    print("Swift 5.8")
    #elseif swift(<5.7)
    print("Lower than Swift 5.7")
    #endif
    
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
                                  timeoutRetry: nil,
                                  proxy: nil,
                                  body: nil,
                                  Flynn.any) { data, httpResponse, error in
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

@_cdecl("silkroad_ocr")
public func ocr() {
    guard let image = try? SilkRoadFrameworkPamphlet.Image6PngGzip().gunzipped() else {
        print("failed to decompress test image")
        return
    }
    if let spyglass = try? Spyglass(),
       let result = spyglass.parse(image: image) {
        print("tesseract: \(result)")
    } else {
        print("tesseract: failed for unknown reason")
    }
}

@_cdecl("silkroad_imap")
public func imap() {
    let imap = IMAP()
    
    imap.beConnect(domain: "imap.gmail.com",
                   port: 993,
                   account: "test.rocco.receiptpal@gmail.com",
                   password: "qtxf ktfw wutc fntv",
                   oauth2: false,
                   imap) { error in
        print("imap connect error: \(error ?? "nil")")
        imap.beSearch(folder: "INBOX",
                      after: Date(timeIntervalSinceNow: 60 * 60 * 24 * 30 * -1),
                      smaller: 1024 * 512,
                      imap) { error, _ in
            print("imap search error: \(error ?? "nil")")
        }
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

