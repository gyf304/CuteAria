//
//  AppDelegate.swift
//  Aria2Helper
//
//  Created by Yifan Gu on 5/22/15.
//  Copyright (c) 2015 Yifan Gu. All rights reserved.
//

//TODO: Implement aria2c output
//TODO: Implement status on menu bar

import Cocoa
import Foundation
import Darwin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WebSocketDelegate, NSUserNotificationCenterDelegate {
    
    var aria2cPath = NSBundle.mainBundle().pathForAuxiliaryExecutable("cutearia-aria2c")
    var aria2cTask = NSTask()
    var aria2cUIPath = NSBundle.mainBundle().pathForResource("webui", ofType: "bundle")! + "/index.html"
    var downloadPath = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory,.UserDomainMask, true)[0] as! String
    var isAria2cRunning = false
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var statusBarItemSpeed : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuSpeed: NSMenu = NSMenu()
    var menuItemExit : NSMenuItem = NSMenuItem()
    var menuItemUI : NSMenuItem = NSMenuItem()
    var menuItemOutput : NSMenuItem = NSMenuItem()
    var menuItemAbout : NSMenuItem = NSMenuItem()
    var menuItemDownloadClipboard : NSMenuItem = NSMenuItem()
    var statusUpdateDaemon = NSTimer()
    var aria2RpcSocket = WebSocket(url: NSURL(string: "http://127.0.0.1:6800/jsonrpc")!)
    var notiCenter = NSUserNotificationCenter.defaultUserNotificationCenter()

    override func awakeFromNib() {

        //Add statusBarItem
        statusBarItemSpeed = statusBar.statusItemWithLength(85)
        statusBarItemSpeed.menu = menuSpeed
        statusBarItemSpeed.title = "◀ Options  "
        
        
        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.image = NSImage(named: "statusIcon.pdf")
        statusBarItem.image?.setTemplate(true)
        
        
        //Add menuItem to menu
        menuItemUI.title = "Show Controls"
        menuItemUI.action = Selector("runUI")
        menuItemUI.keyEquivalent = ""
        menu.addItem(menuItemUI)
        
        //Add menuItem to menu
        
        //TODO: Implement aria2c output
        
        /*
        menuItemOutput.title = "aria2c Output"
        menuItemOutput.action = Selector("exitNow")
        menuItemOutput.keyEquivalent = ""
        menu.addItem(menuItemOutput)
        */
        
        menuItemDownloadClipboard.title = "Start Download from Clipboard"
        menuItemDownloadClipboard.action = Selector("startDownloadFromClipboard")
        menuItemDownloadClipboard.keyEquivalent = ""
        menu.addItem(menuItemDownloadClipboard)
        
        menuItemAbout.title = "About"
        menuItemAbout.action = Selector("showAboutDialog")
        menuItemAbout.keyEquivalent = ""
        menu.addItem(menuItemAbout)

        //Add menuItem to menu
        menuItemExit.title = "Quit"
        menuItemExit.action = Selector("exitNow")
        menuItemExit.keyEquivalent = ""
        menu.addItem(menuItemExit)

        killAllAria2()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.runAria2()
        }
        
        aria2RpcSocket.delegate = self
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.aria2RpcSocket.connect()
        }
    }
    
    func showAboutDialog(){
        let aboutDialog = NSAlert()
        aboutDialog.messageText = "This program utilizes aria2 downloader binary, which is released under GPLv2. \nLicense and source code avilable at http://aria2.sourceforge.net \nThis program utilizes webui-aria2, which is released under MIT license. \nLicense and source code available at https://github.com/ziahamza/webui-aria2"
        aboutDialog.runModal()
    }
    
    func killAllAria2(){
        let pkillTask = NSTask()
        pkillTask.launchPath = "/usr/bin/pkill"
        pkillTask.arguments = ["cutearia-aria2c"]
        pkillTask.launch()
        pkillTask.waitUntilExit()
        isAria2cRunning = false
    }
    
    func runAria2(){
        aria2cTask.launchPath = aria2cPath!
        aria2cTask.arguments = ["--dir=" + downloadPath,
            "--enable-rpc",
            "--rpc-listen-port=6800",
            "--user-agent=\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/600.5.17 (KHTML, like Gecko) Version/8.0.5 Safari/600.5.17\""
        ]
        aria2cTask.launch()
        isAria2cRunning = true
    }
    
    func terminateAria2(){
        if(isAria2cRunning){
            aria2cTask.terminate()
        }
    }
    
    func runUI(){
        NSWorkspace.sharedWorkspace().openURL(NSURL(fileURLWithPath: aria2cUIPath)!)
    }
    
    func exitNow(){
        NSApplication.sharedApplication().terminate(self)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }
    
    
    func updateStatus(){
        aria2RpcSocket.writeString("{\"jsonrpc\":\"2.0\", \"id\":\"CuteAriaGlobalStat\", \"method\":\"aria2.getGlobalStat\"}")
        // write string directly to reduce cpu load
    }
    
    
    func updateStatusUI(input: (JSON)){
        var text = ""
        if let numActiveStr = input["numActive"].string{
            text = (numActiveStr as String) + "@"
        }
        if let downloadSpeedStr = input["downloadSpeed"].string {
            let downloadSpeed = (downloadSpeedStr as NSString).doubleValue
            var readableSpeed = downloadSpeed
            var suffix = "B/s"
            if readableSpeed >= 1000.0 {
                readableSpeed = readableSpeed / 1000.0
                suffix = "kB/s"
                if readableSpeed >= 1000.0 {
                    readableSpeed = readableSpeed / 1000.0
                    suffix = "MB/s"
                }
            }
            text = text + String(format:"%.1f", readableSpeed) + suffix
        }
        statusBarItemSpeed.title = text
    }
    
    func parseAria2Rpc(text: String){
        let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(
            text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!,
            options: NSJSONReadingOptions.AllowFragments,
            error:nil)
        
        let json = JSON(data: text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!,
            options: NSJSONReadingOptions.AllowFragments,
            error:nil)
        
        if let id = json["id"].string{
            switch id {
            case "CuteAriaGlobalStat":
                updateStatusUI(json["result"])
            case "CuteAriaDownloadComplete":
                if let filePath = json["result"]["files"][0]["path"].string{
                    postNoti("Download Completed", subtitle: "", informativetext: filePath as String)
                }
            case "CuteAriaBtDownloadComplete":
                if let filePath = json["result"]["files"][0]["path"].string{
                    postNoti("BT Download Completed", subtitle: "Still Seeding", informativetext: filePath as String)
                }
            default:
                break
            }
        }

        if let method = json["method"].string{
            switch method {
            case "aria2.onDownloadComplete":
                if let gid = json["params"][0]["gid"].string {
                    let requestJSON : JSON = ["jsonrpc": "2.0",
                        "id": "CuteAriaDownloadComplete",
                        "method": "aria2.tellStatus",
                        "params": [gid]
                    ]
                    aria2RpcSocket.writeString(requestJSON.rawString(encoding: NSUTF8StringEncoding, options: NSJSONWritingOptions())!)
                }
            case "aria2.onBtDownloadComplete":
                if let gid = json["params"][0]["gid"].string {
                    let requestJSON : JSON = ["jsonrpc": "2.0",
                        "id": "CuteAriaBtDownloadComplete",
                        "method": "aria2.tellStatus",
                        "params": [gid]
                    ]
                    aria2RpcSocket.writeString(requestJSON.rawString(encoding: NSUTF8StringEncoding, options: NSJSONWritingOptions())!)
                }
            default:
                break
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        statusUpdateDaemon.invalidate()
        aria2RpcSocket.disconnect()
        terminateAria2()
    }
    
    //Websocket callbacks
    
    func websocketDidConnect(socket: WebSocket){
        statusUpdateDaemon = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("updateStatus"), userInfo: nil, repeats: true)
    }
    func websocketDidDisconnect(socket: WebSocket, error: NSError?){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.aria2RpcSocket.connect()
        }
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String){
        println(text)
        parseAria2Rpc(text)
    }
    func websocketDidReceiveData(socket: WebSocket, data: NSData){
        
    }
    
    //NOTIFICATION CENTER

    func postNoti(title: String, subtitle: String, informativetext: String){
        let notification = NSUserNotification()
        notification.title = title
        notification.subtitle = subtitle
        notification.informativeText = informativetext
        notiCenter.deliverNotification(notification)
    }

    func shouldPresentNotification(notification: NSUserNotification) -> Bool{
        return true
    }
    
    //
    
    func startDownloadFromClipboard() {
        if let str = NSPasteboard.generalPasteboard().stringForType(NSPasteboardTypeString){
            startDownloadFromUri(str)
        }
        
    }
    
    func startDownloadFromUri(uri: String) {
        if uri.hasPrefix("http://") || uri.hasPrefix("https://") || uri.hasPrefix("ftp://") || uri.hasPrefix("magnet:?") || uri.hasPrefix("sftp://"){
            let requestJSON : JSON = ["jsonrpc": "2.0",
                "id": "CuteAriaUriDownloadStart",
                "method": "aria2.addUri",
                "params": [[uri]]
            ]
            aria2RpcSocket.writeString(requestJSON.rawString(encoding: NSUTF8StringEncoding, options: NSJSONWritingOptions())!)
        } else {
            postNoti("Cannot Add Download",
                subtitle: "Address Incorrect",
                informativetext: "Address should start with http://, https://, magnet:? or sftp://")
        }
    }
}



class downloadItem {
    var isFile : Bool
    init(uri: String) {
        if uri.hasPrefix("file://") {
            isFile = true
        } else {
            isFile = false
        }
    }
    func startDownload(){
        
    }
}

