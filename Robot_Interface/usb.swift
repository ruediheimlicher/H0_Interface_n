//
//  Netz.swift
//  SwiftStarter
//
//  Created by Ruedi Heimlicher on 30.10.2014.
//  Copyright (c) 2014 Ruedi Heimlicher. All rights reserved.
//


import Cocoa
import Foundation
import AVFoundation
import Darwin

import IOKit.hid

let BUFFER_SIZE:Int   = Int(BufferSize())

var new_Data:ObjCBool = false



var callbackcounter:Int = 0

let VID:Int = 0x16C0 // 5824

// Create a global variable for the HID Manager
var hidManager: IOHIDManager?


// Start listening to HID devices
func startHIDManager() 
{
    // Create an IOHIDManager instance
    hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    guard let manager = hidManager else 
   {
        print("Failed to create IOHIDManager.")
        return
    }

    // Match all HID devices (you can filter by vendor/product ID)
    let matchingDict: [String: Any] = [:] // Empty matches all devices
    IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)

    // Register a callback for detecting input reports
    IOHIDManagerRegisterInputValueCallback(manager, inputReportCallback, nil)

    // Register a callback for device connection events
    IOHIDManagerRegisterDeviceMatchingCallback(manager, deviceConnectedCallback, nil)

    // Register a callback for device disconnection events
    IOHIDManagerRegisterDeviceRemovalCallback(manager, deviceDisconnectedCallback, nil)

    // Schedule the HID manager on the main run loop
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

 
    print("HID Manager started. Listening for devices...")
   // CFRunLoopRun()  // nicht verwendet
   return
}

func getVendorID(device: IOHIDDevice) -> Int? {
    // Get the property as CFTypeRef
    if let vendorIDRef = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) 
   {
        // Convert to Int if it is a CFNumber
        var vendorID: Int32 = 0
        if CFGetTypeID(vendorIDRef) == CFNumberGetTypeID(),
           CFNumberGetValue((vendorIDRef as! CFNumber), .sInt32Type, &vendorID) 
       {
            return Int(vendorID)
        }
    }
    return nil
}

func getProductID(device: IOHIDDevice) -> Int? {
    // Get the property as CFTypeRef
    if let productIDRef = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) 
   {
        // Convert to Int if it is a CFNumber
        var productID: Int32 = 0
        if CFGetTypeID(productIDRef) == CFNumberGetTypeID(),
           CFNumberGetValue((productIDRef as! CFNumber), .sInt32Type, &productID) 
       {
            return Int(productID)
        }
    }
    return nil
}


// Callback: Called when a device is connected
func deviceConnectedCallback(context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, device: IOHIDDevice)
{
   print("USB deviceConnectedCallback callbackcounter vor: \(callbackcounter)")
   if(callbackcounter > 0)
   {
      //print("deviceConnectedCallback return")
      //return
   }
   if let vendorID = getVendorID(device: device),
       let productID = getProductID(device: device)
  
   {
       print("Vendor ID: \(vendorID)")       
       if vendorID   == VID
      {
          callbackcounter = callbackcounter + 1
          print("deviceConnectedCallback Vendor ID : \(vendorID) productID: \(productID)")
          if let productName = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String 
          {
             print("Product Name: \(productName)")
          }
          let openerfolg = rawhid_open(1, Int32(vendorID) , Int32(productID), 0xFFAB, 0x0200)
          print("deviceConnectedCallback openerfolg: \(openerfolg)")
          
          let userInfo: [String: Any] = [
                 
                 "vendor": vendorID,
                 "product": productID
             ]
          print("deviceConnectedCallback   userinfo: \(userInfo) callbackcounter: \(callbackcounter)")
          //if(callbackcounter == 1)
          //{
             print("deviceConnectedCallback   posting notification")
             NotificationCenter.default.post(name: Notification.Name("HIDInputReportReceived"), object: nil, userInfo: userInfo)
          //}
         
         // handleInputReport(value: productID as! IOHIDValue)
          
       }
      print("USB deviceConnectedCallback callbackcounter nach: \(callbackcounter)")
    }
   
}

// Callback: Called when a device is disconnected
func deviceDisconnectedCallback(context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, device: IOHIDDevice)
{
    //print("deviceConnectedCallback Device disconnected: \(device)")
   if let vendorID = getVendorID(device: device)
   {
      if vendorID   == VID
      {
         let userInfo: [String: Any] = [
            
            "vendor": vendorID,
            "product": 0
         ]
         NotificationCenter.default.post(name: Notification.Name("HIDInputReportReceived"), object: nil, userInfo: userInfo)
      }
   }
}

// Callback: Called when an input report is received
func inputReportCallback(context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, value: IOHIDValue) {
   // Get the device associated with this report
   //guard let device = IOHIDValueGetDevice(value) else { return }
   
   // Get the element (control/input field) generating the report
   let element = IOHIDValueGetElement(value)
   
   // Get the value from the report
   let intValue = IOHIDValueGetIntegerValue(value)
   
   print("Input  Element \(String(describing: element)), Value \(intValue)")

   //print("Input from device \(device): Element \(String(describing: element)), Value \(intValue)")
   
}



// HID

class rTimerInfo 
{
    var count = 0
}



@objc class usb_teensy: NSObject
{
   var hid_usbstatus: Int32 = 0
   
   var read_byteArray = [UInt8](repeating: 0x00, count: BUFFER_SIZE)
   var last_read_byteArray = [UInt8](repeating: 0x00, count: BUFFER_SIZE)
   var write_byteArray: Array<UInt8> = Array(repeating: 0x00, count: BUFFER_SIZE)
   // var testArray = [UInt8]()
   var testArray: Array<UInt8>  = [0xAB,0xDC,0x69,0x66,0x74,0x73,0x6f,0x64,0x61]
   
   var read_OK:ObjCBool = false
   var new_Data:ObjCBool = false
 
   var datatruecounter = 0
   var datafalsecounter = 0
   
   var readtimer: Timer?
   
   var manustring:String = ""
   var prodstring:String = ""
   
   override init()
   {
      super.init()
   }
   
   open func USBOpen()->Int32
   {
      var r:Int32 = 0
      
      if (hid_usbstatus > 0)
      {
         print("func usb_teensy.USBOpen USB schon offen")
         let alert = NSAlert()
         alert.messageText = "USB Device"
         alert.informativeText = "USB ist schon offen"
         alert.alertStyle = .warning
         alert.addButton(withTitle: "OK")
        // alert.addButton(withTitle: "Cancel")
         let antwort =  alert.runModal() == .alertFirstButtonReturn
         
         return 1;
      }
      let    out = rawhid_open(1, 0x16C0, 0x0486, 0xFFAB, 0x0200)
      print("func usb_teensy.USBOpen out: \(out)")
      
      hid_usbstatus = out as Int32;
      
      if (out <= 0)
      {
         NSLog("USBOpen: no rawhid device found");
         //[AVR setUSB_Device_Status:0];
      }
      else
      {
         NSLog("USBOpen: found rawhid device hid_usbstatus: %d",hid_usbstatus)
         let manu   = get_manu() 
         let manustr:String = String(cString: manu!)
         
         if (manustr.isEmpty)
         {
            manustring = "-"
         }
         else
         {
            manustring = manustr //String(cString: UnsafePointer<CChar>(manustr))
         }

         let prod = get_prod();
         
         //fprintf(stderr,"prod: %s\n",prod);
         let prodstr:String = String(cString: prod!)
         
         //let anyprodstr : Any? = prodstr
         if (prodstr.isEmpty)
         {
            prodstring = "-"
         }
         else
         {
            prodstring = prodstr //String(cString: UnsafePointer<CChar>(prod!))
         }
   //      var USBDatenDic = ["prod": prod, "manu":manu]
         
      }
      
      
      return out;
   } // end USBOpen
   
   open func manufactorer()->String?
   {
      return manustring
   }
   
   open func producer()->String?
   {
      return prodstring
   }
   
   
   
   open func status()->Int32
   {
      return get_hid_usbstatus()
   }
   
   open func dev_present()->Int32
   {
      return usb_present()
   }
   
   /*
    func appendCRLFAndConvertToUTF8_1(_ s: String) -> Data {
    let crlfString: NSString = s + "\r\n" as NSString
    let buffer = crlfString.utf8String
    let bufferLength = crlfString.lengthOfBytes(using: String.Encoding.utf8.rawValue)
    let data = Data(bytes: UnsafePointer<UInt8>(buffer!), count: bufferLength)
    return data;
    }
    */
   
   /*
    open func start_read_USB()-> NSDictionary
    {
    
    read_OK = true
    let timerDic:NSMutableDictionary  = ["count": 0]
    
    
    let result = rawhid_recv(0, &read_byteArray, 32, 50);
    
    print("*start_read_USB result: \(result)")
    print("lnread_byteArray nach: *\(read_byteArray)*")
    
    var somethingToPass = "It worked in teensy_send_USB"
    
    var timer : Timer? = nil
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(usb_teensy.cont_read_USB(_:)), userInfo: timerDic, repeats: true)
    
    return timerDic as NSDictionary
    }
    */
   
   open func getlastDataRead()->Data
   {
      return lastDataRead
   }
   
   open func start_read_USB(_ cont: Bool)-> Int
   {
      read_OK = ObjCBool(cont)
      var timerDic:NSMutableDictionary  = ["count": 0]
      
      let result = rawhid_recv(0, &read_byteArray, Int32(BUFFER_SIZE), 50);
      
      print("\n*report_start_read_USB result: \(result) cont: \(cont)")
      //print("usb.swift start_read_byteArray start: *\n\(read_byteArray)*")
      
      let nc = NotificationCenter.default
      nc.post(name:Notification.Name(rawValue:"newdata"),
              object: nil,
              userInfo: ["message":"neue Daten", "data":read_byteArray])
      
      // var somethingToPass = "It worked in teensy_send_USB"
      let xcont = cont;
      
      if (xcont == true)
      {
         var timer : Timer? = nil
         timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(usb_teensy.cont_read_USB(_:)), userInfo: timerDic, repeats: true)
      }
      return Int(result) //
   }
   
   /*   
    open func cont_read_USB(_ timer: Timer)
    {
    if (read_OK).boolValue
    {
    var tempbyteArray = [UInt8](repeating: 0x00, count: BUFFER_SIZE)
    var result = rawhid_recv(0, &last_read_byteArray, 32, 50)
    //println("tempbyteArray in Timer: *\(tempbyteArray)*")
    // var timerdic: [String: Int]
    
    
    // http://dev.iachieved.it/iachievedit/notifications-and-userinfo-with-swift-3-0/
    let nc = NotificationCenter.default
    nc.post(name:Notification.Name(rawValue:"newdata"),
    object: nil,
    userInfo: ["message":"neue Daten", "data":read_byteArray])
    
    if  let dic = timer.userInfo as? NSMutableDictionary
    {
    if var count:Int = timer.userInfo?["count"] as? Int
    {
    count = count + 1
    dic["count"] = count
    //dic["nr"] = count+2
    //println(dic)
    }
    }
    
    let timerdic:Dictionary<String,Int?> = timer.userInfo as! Dictionary<String,Int?>
    //let messageString = userInfo["message"]
    var tempcount = timerdic["count"]!
    
    //timer.userInfo["count"] = tempcount + 1
    
    
    
    
    
    //timerdic["count"] = 2
    
    // var count:Int = timerdic["count"]
    
    //timer.userInfo["count"] = count+1
    if !(last_read_byteArray == read_byteArray)
    {
    read_byteArray = last_read_byteArray
    
    print("+++ new read_byteArray in Timer:", terminator: "")
    for  i in 0...4
    {
    print(" \(read_byteArray[i])", terminator: "")
    }
    print("")
    
    }
    //println("*read_USB in Timer result: \(result)")
    
    //let theStringToPrint = timer.userInfo as String
    //println(theStringToPrint)
    }
    else
    {
    timer.invalidate()
    }
    }
    */
   
   @objc open func cont_read_USB(_ timer: Timer)
   {
      //print("*cont_read_USB read_OK: \(read_OK)")
      if (read_OK).boolValue
      {
         //var tempbyteArray = [UInt8](count: 32, repeatedValue: 0x00)
         
         var result = rawhid_recv(0, &read_byteArray, Int32(BUFFER_SIZE), 50)
         
         
         //print("*cont_read_USB result: \(result)")
         print("tempbyteArray in Timer: *\(read_byteArray)*")
        // var timerdic: [String: Int]
         
         
          if  var dic = timer.userInfo as? NSMutableDictionary
          {
            if var count:Int = dic["count"] as? Int 
          {
          count = count + 1
          dic["count"] = count
          //dic["nr"] = count+2
          //println(dic)
          //usb_count += 1
          }
          }
          
         let timerdic:Dictionary<String,Int?> = timer.userInfo as! Dictionary<String,Int?>
         //let messageString = userInfo["message"]
         var tempcount = timerdic["count"]!
         
         //timer.userInfo["count"] = tempcount + 1
         
         //print("+++ new read_byteArray in Timer:")
         /*
          for  i in 0...12
          {
          print(" \(read_byteArray[i])")
          }
          println()
          for  i in 0...12
          {
          print(" \(last_read_byteArray[i])")
          }
          println()
          println()
          */
         
         
         
         //timerdic["count"] = 2
         
         // var count:Int = timerdic["count"]
         
         //timer.userInfo["count"] = count+1
         if !(last_read_byteArray == read_byteArray)
         {
            last_read_byteArray = read_byteArray
            lastDataRead = Data(bytes:read_byteArray)
            let usbData = Data(bytes:read_byteArray)
            new_Data = true
            datatruecounter += 1
            let codehex = read_byteArray[0]
            /*
            print("+++ new read_byteArray in Timer:", terminator: "")
            for  i in 0...16
            {
               print(" \(read_byteArray[i])", terminator: "")
            }
            print("\n32-36")
            for  i in 32...36
            {
               print(" \(read_byteArray[i])", terminator: "")
            }
            print("")
*/
            // http://dev.iachieved.it/iachievedit/notifications-and-userinfo-with-swift-3-0/
            
            //let usbdic = ["message":"neue Daten", "data":read_byteArray] as [String : UInt8]
            let nc = NotificationCenter.default
            
            nc.post(name:Notification.Name(rawValue:"newdata"),
                    object: nil,
                    userInfo: ["message":"neue Daten", "data":read_byteArray, "usbdata":usbData])
            
            // print("+ new read_byteArray in Timer:", terminator: "")
            //for  i in 0...31
            //{
            // print(" \(read_byteArray[i])", terminator: "")
            //}
            //print("")
            //let stL = NSString(format:"%2X", read_byteArray[0]) as String
            //print(" * \(stL)", terminator: "")
            //let stH = NSString(format:"%2X", read_byteArray[1]) as String
            //print(" * \(stH)", terminator: "")
            
            //var resultat:UInt32 = UInt32(read_byteArray[1])
            //resultat   <<= 8
            //resultat    += UInt32(read_byteArray[0])
            //print(" Wert von 0,1: \(resultat) ")
            
            //print("")
            //var st = NSString(format:"%2X", n) as String
            //     } // end if codehex
         }
         else
         {
            //new_Data = false
            datafalsecounter += 1
            //print("--- \(read_byteArray[0])\t\(datafalsecounter)")
         }
         //println("*read_USB in Timer result: \(result)")
         
         //let theStringToPrint = timer.userInfo as String
         //println(theStringToPrint)
         //timer.invalidate()
      }
      else
      {
         print("*cont_read_USB timer.invalidate")
         timer.invalidate()
      }
   }
   
   open func report_stop_read_USB(_ inTimer: Timer)
   {
      
      read_OK = false
   }
   
   
   
   open func send_USB()->Int32
   {
      // http://www.swiftsoda.com/swift-coding/get-bytes-from-nsdata/
      // Test Array to generate some Test Data
      //var testData = Data(bytes: UnsafePointer<UInt8>(testArray),count: testArray.count)
         let senderfolg = rawhid_send(0,&write_byteArray, Int32(BUFFER_SIZE), 50)
         
         if hid_usbstatus == 0
         {
            //print("hid_usbstatus 0: \(hid_usbstatus)")
         }
         else
         {
            //print("hid_usbstatus not 0: \(hid_usbstatus)")
            
         }
         
         return senderfolg
      
   }
   
   
   
   open func rep_read_USB(_ inTimer: Timer)
   {
      var result:Int32  = 0;
      var reportSize:Int = 32;   
      var buffer = [UInt8]();
      result = rawhid_recv(0, &buffer, 64, 50);
      
      var dataRead:Data = Data(bytes:buffer)
      if (dataRead != lastDataRead)
      {
         print("neue Daten")
      }
      print(dataRead as NSData);   
      
      
   }
   
}


open class Hello
{
   open func setU()
   {
      print("Hi Netzteil")
   }
}

