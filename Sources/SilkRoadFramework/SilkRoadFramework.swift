import Foundation
import Hitch
import Spanker

@_cdecl("Java_com_chimerasw_silkroadandroidtest_MainActivity_add")
public func add(env: Int, this: Int, x: Int, y: Int) -> Int {
    let hitch: Hitch = "1234567"
    return hitch.toInt() ?? 99
}

