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
   
   // var boardindex:Int = 0 // 0: teensy++2  1: teensy3.xx
   
    var read_byteArray = [UInt8](repeating: 0x00, count: BUFFER_SIZE)
   var last_read_byteArray = [UInt8](repeating: 0x00, count: BUFFER_SIZE)
   var write_byteArray: Array<UInt8> = Array(repeating: 0x00, count: BUFFER_SIZE)
   // var testArray = [UInt8]()
     
   var testArray: Array<UInt8>  = [0xAB,0xDC,0x69,0x66,0x74,0x73,0x6f,0x64,0x61]
   
   var read_OK:ObjCBool = false
   
   var datatruecounter = 0
   var datafalsecounter = 0
   
    var readtimer: Timer?
   
   var manustring:String = ""
   var prodstring:String = ""
   
  
     var USBTimerInfo = rTimerInfo()
     
   // von CNC_Mill
     var lastreadarray = [UInt8](repeating: 0x00, count: BUFFER_SIZE)
     var readarray = [UInt8](repeating: 0x00, count: BUFFER_SIZE)
     
    let VENDOR_ID:UInt32 = 0x16C0
     
   override init()
   {
      super.init()
      
     // let initreturn:Int = USBInit(VID:VENDOR_ID)
     // print("usb init return: \(initreturn)") 
      
   }
    
    
    
    
    open func USBInit(VID:UInt32)-> Int
    {
       return Int(rawhid_init(VID));
       
    }
   

    open func USBOpen(code:[String:Any] , board: Int)->Int32
    {
       //boardindex = board
       
       var r:Int32 = 0
       
       let PID:Int32 = Int32(code["PID"] as! Int32)//
       let VID:Int32 = Int32(code["VID"] as! Int32)//
       print("func usb_teensy.USBOpen board: \(board)  PID: \(PID) VID: \(VID)")
       
      // VID: 5824
      // PID: 1158 
       // rawhid_open(int max, int vid, int pid, int usage_page, int usage)
       
       /*
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
       */
       // VID: 
       
       let    out = rawhid_open(1,  VID, PID, 0xFFAB, 0x0200)
       
       
       print("func usb_teensy.USBOpen out: \(out)")
       
       hid_usbstatus = out as Int32;
       globalusbstatus = Int(hid_usbstatus)
       if (out <= 0)
       {
          NSLog("USBOpen: no rawhid device found");
          //AVR.setUSB_Device_Status:0
       }
       else
       {
          NSLog("USBOpen: found rawhid device hid_usbstatus: %d",hid_usbstatus)
          /*
          let manu   = get_manu()
          let manustr:String = String(cString: manu!)
          
          if (manustr == "")
          {
             manustring = "-"
          }
          else
          {
             manustring = manustr
             //manustring = String(cString: UnsafePointer<CChar>(manustr))
          }
          
          let prod = get_prod();
          if (prod == nil)
          {
             prodstring = "-"
          }
          else 
          {
             //fprintf(stderr,"prod: %s\n",prod);
             let prodstr:String = String(cString: prod!)
             if (prodstr == nil)
             {
                prodstring = "-"
             }
             else
             {
                prodstring = String(cString: UnsafePointer<CChar>(prod!))
             }
          }
          var USBDatenDic = ["prod": prod, "manu":manu]
          */
          
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
  
    
    open func usb_free()
    {
       free_all_hid();
       //IOHIDManagerClose()
    }
   
   open func dev_present()->Int32
   {
      let vid:UInt32 = 0x16C0;
      let pid:UInt32 = 0x486;
      //let anz = findHIDDevicesWithVendorID(UInt32(vid))
      
      let anz = findHIDDevicesWithVendorAndProductID(vid,pid);
      
      //let productID = findHIDDeviceWithVendorID(vid);
      
      print("dev_present anz: \(anz)")
      return anz;
     // return usb_present()
   }
   
    open func timer_valid()->Bool
    {
       return ((readtimer?.isValid) != nil)
    }

   
    open func iscont()-> Int
    {
       if (read_OK).boolValue == true
       {
            return 1
       }
       return 0
    }
   
   open func getlastDataRead()->Data
   {
      return lastDataRead
   }
   
   @objc func start_read_USB(_ cont: Bool, dic:[String:Any])-> Int
   {
      read_OK = ObjCBool(cont)
      var home = 0
      var timerDic:NSMutableDictionary  = ["count": 0,"home":home]
      
 //     let result = rawhid_recv(0, &read_byteArray, Int32(BUFFER_SIZE), 50);
      
    //  print("\ result: \(result) cont: \(cont)")
      //print("usb.swift start_read_byteArray start: *\n\(read_byteArray)*")
  //    let usbData = Data(bytes:read_byteArray)
  //    print("\n+++ new read_byteArray in start_read_USB:")
  //     for  i in 0..<BUFFER_SIZE
  //     {
  //        print(" \(read_byteArray[i])", terminator: "")
  //     }
      // print("\n")
/*
      let nc = NotificationCenter.default
      nc.post(name:Notification.Name(rawValue:"newdata"),
              object: nil,
              userInfo: ["message":"neue Daten", "data":read_byteArray,"startdata":usbData])
  */    
      // var somethingToPass = "It worked in teensy_send_USB"
     
      
      let xcont = cont;
      
      if (xcont == true)
      {
         
         
         if readtimer?.isValid == true
         {
            readtimer?.invalidate()
         }
         readtimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(usb_teensy.cont_read_USB(_:)), userInfo: USBTimerInfo, repeats: true)
      
      }
      return 0
      //return Int(result) //
   }
   
    @objc func updateUserInfoHome(newhome:Int ) 
    {
       // Invalidate the existing timer
       var oldUserInfo = readtimer?.userInfo as! [String : Any]
       var oldhome = 0
      
       if oldUserInfo.keys.contains("home")
       {
          oldUserInfo["home"] = newhome
       }
            
       if readtimer?.isValid == true
       {
          readtimer?.invalidate()
       }
       /*
       if  newUserInfo
       // Update the userInfo property
       userInfo = newUserInfo

       // Create a new timer with the updated userInfo
       createTimer()
        */
   }
   
   
   @objc open func cont_read_USB(_ timer: Timer)
   {
     // print("\n*** cont_read_USB start")
      //print("*read_OK: \(read_OK)")
      if (read_OK).boolValue
      {
         //var tempbyteArray = [UInt8](count: 32, repeatedValue: 0x00)
         
         var result = rawhid_recv(0, &read_byteArray, Int32(BUFFER_SIZE), 0)
         
         var usbrecvcount = 0
         for  i in 0..<BUFFER_SIZE
         {
            if read_byteArray[i] > 0
            {
               usbrecvcount += 1
            }
         }
    //     print("*cont_read_USB usbrecvcount: \(usbrecvcount)")
         if usbrecvcount == 0
         {
            return
         }
         if read_byteArray[0] > 0x80
         {
            //print("*cont_read_USB result: \(result) code: \(read_byteArray[0]) tastaturwert: \(read_byteArray[57]) Taste: \(read_byteArray[58]) potwertA: \(read_byteArray[13])")
         }
         //print("tempbyteArray in Timer: *\(read_byteArray)*")
        // var timerdic: [String: Int]
         
         guard let timerInfo = timer.userInfo as? rTimerInfo else 
         { 
            print("cont_read_USB timerinfo not OK")
            return 
            
         }
         
             timerInfo.count += 1
     
          
          //print("cont_read_USB timerInfo: \(timerInfo.count)")
      
           
         if !(last_read_byteArray == read_byteArray)
         {
           //print("last_read_byteArray not eq read byteArray ");
            /*
                 guard let timerInfo = timer.userInfo as? rTimerInfo else { return }

                        timerInfo.count += 1
                       // print("cont_read_USB timerInfo: \(timerInfo.count)")
            */
            
            //print("cont_read_USB timerInfo: \(timerInfo) read_byteArray 0: \(read_byteArray[0])")

            
            last_read_byteArray = read_byteArray
            lastDataRead = Data(bytes:read_byteArray)
            let usbData = Data(bytes:read_byteArray)
            new_Data = true
            datatruecounter += 1
            let codehex = read_byteArray[0]
            let codehexstring = String(codehex, radix:16, uppercase:true)
       //     print("cont_read_USB new Data codehex: \(codehex) codehex: \(codehexstring)")
            
            
            //print("\n+++ cont_read_USB new read_byteArray in Timer. code: \(read_byteArray[0])")
            
            if (read_byteArray[0] == 0xF3)
            {
               print("usb code F3")
            }

            
            if (read_byteArray[0] == 0xBD)
            {
               print("usb code BD")
            }
             
     //        print("read_byteArray: \(read_byteArray)")
            /*
             for  i in 0..<BUFFER_SIZE
            {
               print("i: \(i)  \(read_byteArray[i]) ")
            }
            print("\n")
            */
            // http://dev.iachieved.it/iachievedit/notifications-and-userinfo-with-swift-3-0/
            
            //let usbdic = ["message":"neue Daten", "data":read_byteArray] as [String : UInt8]
            let nc = NotificationCenter.default
            /*       
             nc.post(name:Notification.Name(rawValue:"newdata"),
             object: nil,
             userInfo: ["message":"neue Daten", "data":read_byteArray, "usbdata":usbData])
             */
            // CNC
            nc.post(name:Notification.Name(rawValue:"newdata"),
                    object: nil,
                    userInfo: ["message":"neue Daten", "data":read_byteArray, "contdata":usbData])
            
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
            if (read_byteArray[0] > 0)
            {
            //print("---nix neues  \(read_byteArray[0])\t\(datafalsecounter)\n")
            }
            datafalsecounter += 1
            //stop_read_USB()
         }
         //println("*read_USB in Timer result: \(result)")
         
         //let theStringToPrint = timer.userInfo as String
         //println(theStringToPrint)
         //timer.invalidate()
      }
      else
      {
         print("* usb cont_read_USB timer.invalidate")
         timer.invalidate()
      }
      //print("+++ end cont_read +++\n")
   }
   
   open func report_stop_read_USB(_ inTimer: Timer)
   {
      
      read_OK = false
   }
   
   @objc func stop_read_USB()
   {
      read_OK = false
   }
 
    @objc func clear_data()
    {
       for  i in 0..<BUFFER_SIZE
       {
          read_byteArray[i] = 0
          if write_byteArray.count > i
          {
          write_byteArray[i] = 0
          }
       }
       
    }

    @objc func stop_timer()
    {
       if ((readtimer) != nil)
            
       {
          if ((readtimer?.isValid) != nil)
          {
             NSLog("writeCNCAbschnitt HALT timer inval");
             readtimer?.invalidate();
          }
          readtimer = nil
          
       }
       read_OK = false

    }

    
   open func send_USB()->Int32
   {
      // http://www.swiftsoda.com/swift-coding/get-bytes-from-nsdata/
      // Test Array to generate some Test Data
      //var testData = Data(bytes: UnsafePointer<UInt8>(testArray),count: testArray.count)
  /*    
      write_byteArray[0] = testArray[0]
      write_byteArray[1] = testArray[1]
      write_byteArray[2] = testArray[2]
      
      if (testArray[0] < 0xFF)
      {
         testArray[0] += 1
      }
      else
      {
         testArray[0] = 0;
      }
      if (testArray[1] < 0xFF)
      {
         testArray[1] += 1
      }
      else
      {
         testArray[1] = 0;
      }
      if (testArray[2] < 0xFF)
      {
         testArray[2] += 1
      }
      else
      {
         testArray[2] = 0;
      }
      
      //println("write_byteArray: \(write_byteArray)")
//      print("write_byteArray in send_USB: ", terminator: "")
      
      for  i in 0...16
      {
//         print(" \(write_byteArray[i])", terminator: "\t")
      }
      print("")
  */    
      
     //    let senderfolg = rawhid_send(0,&write_byteArray, Int32(BUFFER_SIZE), 50)
      var senderfolg:Int32 = 0xFF
      // print("usb send_USB boardindex: \(boardindex)")
      if  boardindex == 0 // teensy++2
      {
         senderfolg = rawhid_send(0,&write_byteArray, 32, 50)
      }
      else if boardindex == 1 // teensy3.xx
      {
         senderfolg = rawhid_send(0,&write_byteArray, 64, 50)
      }
      
         
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
      var reportSize:Int = 64;   
      var buffer = [UInt8]();
      result = rawhid_recv(0, &buffer, Int32(BUFFER_SIZE), 50);
      
      var dataRead:Data = Data(bytes:buffer)
      if (dataRead != lastDataRead)
      {
         print("neue Daten")
      }
      print(dataRead as NSData);   
            
   }
    
    
    func getHIDDevices(withVendorID vendorID: Int) -> [IOHIDDevice] 
    {
        var devices: [IOHIDDevice] = []

        // Create a matching dictionary for HID devices
        let matchingDict = IOServiceMatching(kIOHIDDeviceKey)
        guard let hidService = matchingDict else {
            print("Failed to create HID matching dictionary")
            return devices
        }
        
        // Create a mutable dictionary to add VendorID filter
        let mutableDict = NSMutableDictionary(dictionary: hidService)
       
       mutableDict[kIOHIDVendorIDKey] = vendorID

        // Get matching HID services
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMasterPortDefault, mutableDict, &iterator)
        if result != KERN_SUCCESS {
            print("Error: Unable to get matching HID services (\(result))")
            return devices
        }

        // Iterate through matching services
        var service: io_object_t = IOIteratorNext(iterator)
        while service != 0 
       {
           if let device = IOHIDDeviceCreate(kCFAllocatorDefault, service) 
           {
                devices.append(device)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }

        // Release the iterator
        IOObjectRelease(iterator)

        return devices
    }// 




   
}


open class Hello
{
   open func setU()
   {
      print("Hi Netzteil")
   }
}

