//
//  ScheduledClosure.swift
//  CMS Now
//
//  Created by App Development on 2/17/16.
//  Copyright © 2016 com.chambersburg. All rights reserved.
//

import Foundation

/// A Scheduled Closure is a custom object that executes a specified code block after a certain amount of time. The block can be repeating, and is capable of running on any custom queue for asynchronous operation.
class ScheduledClosure {
    
    deinit {
        print("Invalidating \(self) \(objectID(self))")
        timer?.invalidate()
    }
    
    private init(queue: NSOperationQueue, qos: NSQualityOfService, closure: Task ) {
        self.task = closure
        self.queue = queue
        self.qos = qos
    }
    
    /**
     Scedules the passed closure to execute after a specified number of seconds.
     
     If you specify a value for `tolerance`, the system is responsible for determining exactly when the closure executes, depending on what will be most efficient.
     
     Although the actual task is guarenteed to be executed on the passed operation queue, or on the main queue if no custom queue is specified, the tasks associated with scheduling the closure, including the timer itself, run on the main queue.
     
     The type of task defined by the value of `qualityOfService` will determine how many system resources are devoted to executing the task, and therefore determine how quickly the task may complete. Describe the operation accurately using a case of `NSQualityOfService`.
     
     Specifying `firesDuringCommonProcesses` as true will allow the task to execute simultaneously with another operation on the main queue, such as UI scrolling. You should leave this value with its default of `false` unless you truly need this task to execute regardless of other operations like UI manipulation.
     
     The passed closure represents the task you are scheduling and returns `Void`, taking exactly one parameter, an NSOperation representing the operation that this task will be wrapped in. Use this parameter to periodically check the `cancelled` property. You can ignore this parameter if you do not want to support cancelling an in-progress task.
     
     - Parameter timeInterval: The number of seconds to wait before execution.
     - Parameter tolerance: **Optional** The amount of leeway, in seconds, the closure has to execute. For example, if you set `timeInterval` to 10 and `tolerance` to 5, the closure may execute anytime between 10 and 15 seconds from the time it is scheduled. The default value is 0.
     - Parameter repeats: Specify `true` if you would like the closure to continue executing on an interval defined by `timeInterval`. Specify `false` to force the closure to only execute once.
     - Parameter queue: **Optional** The operation queue to run the task on. If no queue is passed, the closure will run on the main queue. To schedule the closure asynchronously, specify a custom `NSOperationQueue` here.
     - Parameter qualityOfService: **Optional** The relative priority of the closure's task, specified as a case of `NSQualityOfService`. The default value is `NSQualityOfService.Default`.
     - Parameter firesDuringCommonProcesses: **Optional** Specify `true` if you would like the closure to begin execution regardless of whether another process, such as UI manipulations like scrolling, are already taking place. The default value is `false`.
     - Parameter closure: The task you are scheduling, wrapped in a closure. The closure returns `Void` and takes exactly one parameter, an NSOperation representing the operation that this task will be wrapped in. Use this parameter to periodically check the `cancelled` property.
     
    */
    static func scheduleClosureWithTimeInterval(timeInterval: NSTimeInterval, tolerance: NSTimeInterval = 0, repeats: Bool, queue: NSOperationQueue = NSOperationQueue.mainQueue(), qualityOfService: NSQualityOfService = .Default, firesDuringCommonProcesses: Bool = false, closure: (NSOperation) -> () ) -> ScheduledClosure {
        
        let scheduledClosure = ScheduledClosure(queue: queue, qos: qualityOfService, closure: closure)
        let op = NSBlockOperation() {
            // Create Sceduled Closure
            scheduledClosure.timer = Timer.scheduledTimerWithTimeInterval(timeInterval, target: scheduledClosure, selector: #selector(scheduledClosure.run), userInfo: nil, repeats: repeats)
            scheduledClosure.timer.tolerance = tolerance
            
            /* If firing during common processes is requested, we need to make a modification to the timer.
             
             Here's what's going on:
             
             Above, we are scheduling the timer on the main thread, even if a seperate operation queue is requested for the task. We do this because running a timer is not much work, so there's no need to push it onto a background queue. It is the task itself that we will run in the specified queue, not the timer, since running a timer is a cheep operation.
             Now, without going into extreme detail, when we create an NSTimer, behind the scenes it gets associated with a Run Loop. A Run Loop is just mechanism that can wake up sleeping threads on certain events. A timer needs to be associated with a run loop because the Run Loop will ensure the thread responds on the fire date. When you just create a timer like above, it automatically gets associated with the main run loop (for the main thread) and the default run loop mode. A run loop mode defines rules for when to deliver an event.
             
             If you didn't understand the previous two paragraphs, don't sweat because this is the important one. Because of the rules the default run loop mode defines, the timer we created above will not fire when some other process, such as scrolling content, is running on the main thread. This means that if a Scheduled Closure is created without specifying firesDuringCommonProcesses as true, and a user is scrolling or doing something else with the UI at the moment the timer is supposed to fire, the timer will not fire until the UI is finished. Typically, this mode gives better performance for the UI and is not a big deal for the task. If, however, firesDuringCommonProcesses is explicitly specified as true, we need to explicitly add the timer to the CommonModes run loop mode, as shown below. This means that the timer will be allowed to fire even while other processes, such as UI updates, are running.
             
             */
            if firesDuringCommonProcesses {
                NSRunLoop.mainRunLoop().addTimer(scheduledClosure.timer, forMode: NSRunLoopCommonModes)
            }
            
            // Report to Xcode Console
            print("Scheduled \(objectID(scheduledClosure))")
        }
        if let currentQueue = NSOperationQueue.currentQueue() where currentQueue == NSOperationQueue.mainQueue() {
            op.start()
        } else {
            NSOperationQueue.mainQueue().addOperations([op], waitUntilFinished: true)
        }
        
        // Return newly created Scheduled Closure so that the caller can retain a reference to it if they wish. This is useful in case they need to cancel a timer.
        return scheduledClosure
    }
    
    /**
     Cancels the execution of the passed code block.
     
     If the block has not yet executed, it will never start. If it is in the process of running, it is prevented from running again and the currently running block is cancelled according to the cancel logic in the passed closure.
    */
    func cancel() {
        print("Canceling \(operationName)")
        timer?.invalidate()
        for operation in queue.operations {
            if operation.name == operationName {
                operation.cancel()
            }
        }
    }
    
    @objc private func run() {
        print("Adding SC \(objectID(self)) to queue.")
        queue.addOperation(operation)
    }
    
    private var timer: Timer!
    private let task: Task
    
    private lazy var operationName: String = "Task for \(objectID(self))"
    
    private var operation: NSOperation {
        
        get {
            let blockOperation = NSBlockOperation()
            let block = { [unowned blockOperation] in
                NSLog("Running \(self) on \(NSOperationQueue.currentQueue())")
                self.task(blockOperation)
            }
            blockOperation.addExecutionBlock(block)
            blockOperation.name = operationName
            blockOperation.qualityOfService = qos
            return blockOperation
        }
        
    }
    
    private let queue: NSOperationQueue
    private let qos: NSQualityOfService
    
    private typealias Timer = NSTimer
    private typealias Task = (NSOperation) -> ()
    
}

func objectID(object: AnyObject) -> String {
    return String(ObjectIdentifier(object).hashValue)
}
