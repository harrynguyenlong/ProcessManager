//
//  Utils.swift
//  ProcessManager
//
//  Created by Nguyen Ba Long on 29/07/2018.
//  Copyright © 2018 Nguyen Ba Long. All rights reserved.
//

import Foundation
import Darwin

public func GetBSDProcessList() -> ([kinfo_proc]?)  {
    
    var done = false
    var result: [kinfo_proc]?
    var err: Int32
    
    repeat {
        var name = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0];
        
        let namePointer = name.withUnsafeMutableBufferPointer({ UnsafeMutablePointer<Int32>($0.baseAddress) })
        
        var length: Int = 0
        
        err = sysctl(namePointer, u_int(name.count), nil, &length, nil, 0)
        if err == -1 {
            err = errno
        }
        
        if err == 0 {
            let count = length / MemoryLayout.stride(ofValue: kinfo_proc())
            result = [kinfo_proc](repeating: kinfo_proc(), count: count)
            err = result!.withUnsafeMutableBufferPointer({ ( p: inout UnsafeMutableBufferPointer<kinfo_proc>) -> Int32 in
                return sysctl(namePointer, u_int(name.count), p.baseAddress, &length, nil, 0)
            })
            switch err {
            case 0:
                done = true
            case -1:
                err = errno
            case ENOMEM:
                err = 0
            default:
                fatalError()
            }
        }
    } while err == 0 && !done
    
    return result
}


