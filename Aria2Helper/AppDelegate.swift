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
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var aria2cPath = NSBundle.mainBundle().pathForResource("aria2c", ofType: "bin")
    var aria2cTask = NSTask()
    var aria2cUIPath = NSBundle.mainBundle().pathForResource("index", ofType: "html")
    var downloadPath = NSSearchPathForDirectoriesInDomains(.DownloadsDirectory,.UserDomainMask, true)[0] as! String
    var isAria2cRunning = false
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItemExit : NSMenuItem = NSMenuItem()
    var menuItemUI : NSMenuItem = NSMenuItem()
    var menuItemOutput : NSMenuItem = NSMenuItem()
    var menuItemAbout : NSMenuItem = NSMenuItem()
    
    

    override func awakeFromNib() {

        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.title = "CuteAria"
        
        //Add menuItem to menu
        menuItemUI.title = "Show WebUI"
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
        
        menuItemAbout.title = "About"
        menuItemAbout.action = Selector("showAboutDialog")
        menuItemAbout.keyEquivalent = ""
        menu.addItem(menuItemAbout)

        //Add menuItem to menu
        menuItemExit.title = "Quit"
        menuItemExit.action = Selector("exitNow")
        menuItemExit.keyEquivalent = ""
        menu.addItem(menuItemExit)
        
        runAria2()
    }
    
    func showAboutDialog(){
        let aboutDialog = NSAlert()
        aboutDialog.messageText = "This program utilizes aria2 downloader binary, which is released under GPLv2. \nLicense and source code avilable at http://aria2.sourceforge.net \nThis program utilizes webui-aria2, which is released under MIT license. \nLicense and source code available at https://github.com/ziahamza/webui-aria2"
        aboutDialog.runModal()
    }
    
    func runAria2(){
        aria2cTask.launchPath = aria2cPath!
        aria2cTask.arguments = ["--dir=" + downloadPath, "--enable-rpc", "--rpc-listen-port=6800"]
        aria2cTask.launch()
        isAria2cRunning = true
    }
    
    func terminateAria2(){
        if(isAria2cRunning){
            aria2cTask.terminate()
        }
    }
    
    func runUI(){
        NSWorkspace.sharedWorkspace().openURL(NSURL(fileURLWithPath: aria2cUIPath!)!)
    }
    
    func exitNow(){
        NSApplication.sharedApplication().terminate(self)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        terminateAria2()
    }


}

