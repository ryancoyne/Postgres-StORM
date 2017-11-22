//
//  CCXMirroring.swift
//  StORMPackageDescription
//
//  Created by Ryan Coyne on 11/22/17.
//

//
//  CCXMirror.swift
//  FindAPride
//
//  Created by Ryan Coyne on 11/17/17.
//  Copyright © 2017 Launch, LLC. All rights reserved.
//

fileprivate protocol CCXMirroring {
    func didInitializeSuperclass()
    func superclassMirrors() -> [Mirror]
    func allChildren() -> [String:Any]
}

class CCXMirror: CCXMirroring {
    private var superclassCount = 0
    func didInitializeSuperclass() {
        self.superclassCount += 1
    }
    func superclassMirrors() -> [Mirror] {
        var mirrors : [Mirror] = []
        let mir = Mirror(reflecting: self)
        mirrors.append(mir)
        var currentContext : Mirror?
        for _ in 0...self.superclassCount {
            if currentContext.isNil {
                currentContext = mir.superclassMirror
            } else {
                currentContext = currentContext?.superclassMirror
            }
            if currentContext.isNotNil {
                mirrors.append(currentContext!)
            }
        }
        return mirrors
    }
    func allChildren() -> [String:Any] {
        // Remove out the superclass count which is private:
        var children = self.superclassMirrors().allChildren
        children.removeValue(forKey: "superclassCount")
        return children
    }
}

