//
//  AppDelegate.swift
//  Project
//
//  Created by Connectz technology co., ltd on 8/6/2017.
//  Copyright © 2017 Connectz technology co., ltd. All rights reserved.
//

import AVFoundation
import UIKit
import CoreData
import CoreBluetooth
import IQKeyboardManagerSwift
import Reachability
import Siren
import SwiftyBeaver
import MagicalRecord
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var reach: Reachability?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // SwiftyBeaver log setup
        let console = ConsoleDestination()
        console.minLevel = .debug
        console.format = "$L: $M"
        log.addDestination(console)
        log.info(Helper.documentDirectory)
        
        // Siren setup
        Siren.shared.checkVersion(checkType: .daily)
        
        // IQKeyboardManager
        IQKeyboardManager.sharedManager().enable = true
        
        // MagicalRecord
        MagicalRecord.setLoggingLevel(.off)
        MagicalRecord.setupAutoMigratingCoreDataStack()
        
        // TimeZone
        if let timeZoneName = UserDefaults.string(of: .timezone),
            let timezone = TimeZone(identifier: timeZoneName) {
            NSTimeZone.default = timezone
        }
        
        // Local Notification
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound], completionHandler: { (granted, error) in })
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(false, with: .notifyOthersOnDeactivation)
        } catch let error {
            log.error(error.localizedDescription)
        }
        
        // Reachability
        reach = Reachability.forInternetConnection()
        reach?.startNotifier()
        
        log.info(launchOptions)
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        SBManager.share.getTargetSteps()
        completionHandler(.newData)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if SBManager.share.player?.isPlaying ?? false {
            SBManager.share.player?.stop()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
        // Siren setup
        Siren.shared.checkVersion(checkType: .daily)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        MagicalRecord.cleanUp()
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        // Disable the message notification
        //SBManager.share.reset()
        //SBManager.share.peripheral(
        //    SBManager.share.selectedPeripheral,
        //    write: Data.init(bytes: [0x0d,0x00]))
        //SBPeripheral.share.stop()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: Helper.targetName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

