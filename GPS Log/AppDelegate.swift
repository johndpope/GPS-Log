//
//  AppDelegate.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import UIKit
import BackgroundTasks
import CoreData

@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        Settings.Initialize()
        RegisterBackgroundTasks()
        return true
    }
    
    func RegisterBackgroundTasks()
    {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.iroiro.refresh",
                                        using: nil)
        {
            task in
            self.RefreshAppTask(task: task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.iroiro.location",
                                        using: nil)
        {
            task in
            self.GetLocationTask(task: task as! BGProcessingTask)
        }
    }
    
    func ScheduleAppRefresh()
    {
        let Request = BGAppRefreshTaskRequest(identifier: "com.iroiro.refresh")
        Request.earliestBeginDate = Date(timeIntervalSinceNow: 120)
        do
        {
            try BGTaskScheduler.shared.submit(Request)
        }
        catch
        {
            print("Error scheduling refresh task: \(error.localizedDescription)")
        }
    }
    
    func GetLocationTask(task: BGProcessingTask)
    {
    }
    
    func RefreshAppTask(task: BGAppRefreshTask)
    {
        ScheduleAppRefresh()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        if Settings.GetBoolean(ForKey: .StayAwake)
        {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        if Settings.GetBoolean(ForKey: .StayAwake)
        {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration
    {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>)
    {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

class BGLocation: Operation
{
    private let Context: NSManagedObjectContext!
    var Predicate: NSPredicate? = nil
    var Delay: TimeInterval = 0.0005
    
    init(Context: NSManagedObjectContext)
    {
        self.Context = Context
    }
    
    convenience init(Context: NSManagedObjectContext, Predicate: NSPredicate?, Delay: TimeInterval? = nil)
    {
        self.init(Context: Context)
        self.Predicate = Predicate
        if let UseDelay = Delay
        {
            self.Delay = UseDelay
        }
    }
    
    override func main()
    {
        Context.performAndWait
            {
                //get location
        }
    }
}
