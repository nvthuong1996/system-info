//
//  AppDelegate.swift
//  System Info
//
//  Created by Thuong Nguyen Van on 6/21/19.
//  Copyright © 2019 Thuong Nguyen Van. All rights reserved.
//

import Cocoa
import NetworkExtension
import Foundation
import Darwin



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(printQuote(_:))
        }
        constructMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func printQuote(_ sender: Any?) {
        let wifiinfo = getWiFiAddress()
        copyToClipBoard(textToCopy:wifiinfo.ip4);
        
        let notification = NSUserNotification()
        notification.title = "Copy IP locahost to clipboard"
        notification.informativeText = wifiinfo.ip4
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
        //print("\(quoteText) — \(quoteAuthor.ip4)")
    }
    
    private func copyToClipBoard(textToCopy: String) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(textToCopy, forType: .string)
        
    }

    func constructMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Copy IP Localhost", action: #selector(AppDelegate.printQuote(_:)), keyEquivalent: "P"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    func showNotification() -> Void {

    }
    
    func getWiFiAddress() -> (ip4: String, mac: String, addr: sockaddr_in) {
        
        var address : String = "..."
        var mac: String = ":::::"
        var success: Bool
        var addr_in = sockaddr_in()
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        success = getifaddrs(&ifaddr) == 0
        assert(success)
        assert(ifaddr != nil)
        let firstAddr = ifaddr!
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            let name = String(cString: interface.ifa_name)
            if  name == "en0" {
                if addrFamily == UInt8(AF_INET) {
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    success = getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                          &hostname, socklen_t(hostname.count),
                                          nil, socklen_t(0), NI_NUMERICHOST) == 0
                    assert(success)
                    addr_in = withUnsafePointer(to: &addr) {
                        $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                            $0.pointee
                        }
                    }
                    address = String(cString: hostname)
                }
                if addrFamily == UInt8(AF_LINK) {
                    interface.ifa_addr.withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { (sdl) -> Void in
                        var hw = sdl.pointee.sdl_data
                        withUnsafeBytes(of: &hw, { (p) -> Void in
                            mac = p[Int(sdl.pointee.sdl_nlen)..<Int(sdl.pointee.sdl_alen + sdl.pointee.sdl_nlen)].map({ (u) -> String in
                                var s = String(u, radix:16)
                                if s.count < 2 {
                                    s.append("0")
                                    s = String(s.reversed())
                                }
                                return s
                            }).joined(separator: ":")
                        })
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
        return (address, mac, addr_in)
    }
}



