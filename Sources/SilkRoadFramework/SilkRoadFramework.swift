import Foundation
import Hitch
import Spanker

@_cdecl("silkroad_add")
public func add(x: Int, y: Int) -> Int {
    return Pamphlet.version.components(separatedBy: ".").count
    
    /*
    let someJson: Hitch = #"{"value":96}"#
    return someJson.parsed { root in
        return root?[int: "value"]
    } ?? 0
     */
}

