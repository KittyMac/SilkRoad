import Foundation
import Hitch
import Spanker

@_cdecl("Java_com_chimerasw_silkroadandroidtest_MainActivity_add")
public func add(env: Int, this: Int, x: Int, y: Int) -> Int {
    let someJson: Hitch = #"{"value":96}"#
    return someJson.parsed { root in
        return root?[int: "value"]
    } ?? 0
}

