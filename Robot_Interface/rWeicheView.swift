//
//  rWeicheView.swift
//  H0_Interface
//
//  Created by Ruedi Heimlicher on 05.03.2026.
//  Copyright © 2026 Ruedi Heimlicher. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

//var numtasten:Int = 8

let geradeimage:NSImage = NSImage(named: NSImage.Name("WS_Gerade"))!
let ablenkungimage:NSImage = NSImage(named: NSImage.Name("WS_Ablenkung"))!


class rWeichenradio: NSButton 
{
   var radionummer:Int = 0
   var name:String = ""
   func configure()
   {
      self.state = .off
      self.target = self
      self.action = #selector(self.report_weichentaste)
      self.controlSize = .large
      self.title = "x"
      self.setButtonType(NSButton.ButtonType.radio)
      
   }
   override init(frame frameRect: NSRect) 
   {
      Swift.print("rWeichenradio init frame")
      super.init(frame: frameRect)
      configure()
      self.action = #selector(self.report_weichentaste)
   }
   required init?(coder  aDecoder : NSCoder) 
   {
      super.init(coder: aDecoder)
      configure()
      
      Swift.print("rWeichenradio init coder ")
      self.action = #selector(self.reportRadiotaste)
   }
   
   func setValue(_ v: Int) 
   {
      self.radionummer = v
   }
   
   @objc func report_weichentaste(_ sender: NSButton)
   {
      Swift.print("report_weichentaste  ident: \(self.radionummer) name: \(self.name) tag: \(self.tag)")  
      let status = sender.state
      
      
      // let ident = self.identifier
      let tastetag = self.tag
      let userinformation = ["message":"weichenaktion","tag":self.tag, ] as [String : Any]
      let nc = NotificationCenter.default
      
      
      nc.post(name:Notification.Name(rawValue:"tastenstatus"),
              object: nil,
              userInfo: userinformation)
      
   }
   
   @objc func reportRadiotaste()
   {
      
      
      
   }
   
   
}// rWeichenradio



class rWeichenradiogruppeH:NSView
{
   
   var weichengruppenummer:Int = 0
   var weichen: [rWeichenradio] = []
   
   var hintergrundfarbe = NSColor()
   
   var weichenstatus:[Int] = Array(repeating: 0, count: 2) 
   var weichenstellung:UInt8 = 0;
   var radio0:rWeichenradio! 
   var radio1:rWeichenradio! 
   var titelFeld:NSTextField!
   
   required init?(coder  aDecoder : NSCoder) 
   {
      super.init(coder: aDecoder)
      Swift.print("rWeichenradiogruppeH init")
      
   }
   
   
   
   override init(frame frameRect: NSRect) 
   {
      super.init(frame: frameRect)
      let w:CGFloat = bounds.size.width
      let h:CGFloat = bounds.size.height
      let titelfeldrect = NSMakeRect(0,h-10 , 12,12)
      titelFeld = NSTextField(frame:titelfeldrect )
      
      //addSubview(titelFeld)
      
      self.wantsLayer = true
      hintergrundfarbe  = NSColor.init(red: 0, 
                                       green: 1.0, 
                                       blue: 1.0, 
                                       alpha: 0.25)
      self.layer?.backgroundColor =  hintergrundfarbe.cgColor
      
      
      let tasteW:CGFloat = 20
      let tasteH:CGFloat = 20
      
      var tastenrect : NSRect = NSMakeRect(5 ,0 , tasteW,tasteH)
      var radiotaste0 = rWeichenradio(frame:tastenrect)
      
      radio0 = rWeichenradio(frame:tastenrect)
      //radio0.setValue(10)
      
      radio0.name = "radio0"
      
      
      //   addSubview(radio0)
      let tastenrect1 : NSRect = NSMakeRect(30 ,0 , tasteW,tasteH)
      radio1 = rWeichenradio(frame:tastenrect1)
      //radio1.setValue(11)
      radio1.name = "radio1"
      
      //    addSubview(radio1)
      
      //var gruppenrect0 : NSRect = NSMakeRect(50 ,0 , tasteW,tasteH)
      
      
      
   }
   
   
   
   
}

class rWeichenradiogruppeV:NSView
{
   var titelFeld:NSTextField!
   
   var weichengruppenummer:Int = 0
   var weichen: [rWeichenradio] = []
   
   var hintergrundfarbe: NSColor = .systemBlue
   
   var weichenstatus:[Int] = Array(repeating: 0, count: 2) 
   var weichenstellung:UInt8 = 0;
   var radio0:rWeichenradio! 
   var radio1:rWeichenradio!
   var symbolView:NSImageView!
   
   required init?(coder  aDecoder : NSCoder) 
   {
      super.init(coder: aDecoder)
      Swift.print("rWeichenradiogruppeH init")
      
   }
   
   
   
   
   override init(frame frameRect: NSRect) 
   {
      super.init(frame: frameRect)
      /*
       self.title = "Meine Box"   // Beispiel: Titel setzen
       self.boxType = .primary     // Typ der Box
       self.borderColor = .black   // Rahmenfarbe
       self.fillColor = .lightGray //
       self.titlePosition = .noTitle
       */
      let w:CGFloat = bounds.size.width
      let h:CGFloat = bounds.size.height
      let th:CGFloat = 28
      let tw:CGFloat = 28
      let titelfeldrect = NSMakeRect(w/2 - tw/2, h - th - 2 , th,tw)
      titelFeld = NSTextField(frame:titelfeldrect )
      titelFeld.alignment = .center
      titelFeld.isBezeled = false
      titelFeld.drawsBackground = false
      titelFeld.isEditable = false
      
      titelFeld.font = NSFont(name: "Helvetica", size: 20)
      addSubview(titelFeld)
      
      self.wantsLayer = true
      let weichehintergrundfarbe  = NSColor.init(red: 0.1, 
                                       green: 0.5, 
                                       blue: 0.2, 
                                       alpha: 0.25)
      self.layer?.backgroundColor =  weichehintergrundfarbe.cgColor
      
      
      
      let tasteW:CGFloat = 20
      let tasteH:CGFloat = 20
      
      var tastenrect : NSRect = NSMakeRect(5 ,h/2 - 2 * tasteH , tasteW,tasteH)
      var radiotaste0 = rWeichenradio(frame:tastenrect)
      
      radio0 = rWeichenradio(frame:tastenrect) // untere Taste
      //radio0.setValue(10)
      radio0.state = .on
      radio0.name = "radio0"
      addSubview(radio0) 
      
      var tastenrect1 : NSRect = NSMakeRect(5 ,h/2  , tasteW,tasteH)
      radio1 = rWeichenradio(frame:tastenrect1) // obere Taste
      //radio1.setValue(11)
      radio1.name = "radio1"
      radio0.state = .off
      addSubview(radio1)
      
      let symbolW:CGFloat = 20
      let symbolH:CGFloat = 20
      
      
      var symbolrect : NSRect = NSMakeRect(5 ,h/2 -  symbolH , symbolW,symbolH)
      symbolView = NSImageView(frame:symbolrect) 
      
      symbolView.image = geradeimage
      addSubview(symbolView)
      
      //var gruppenrect0 : NSRect = NSMakeRect(50 ,0 , tasteW,tasteH)
      
      
      
   }
   
   
   
   @objc func setWeichentasten()
   {
      
      
   }
}

class rWeichenradioView:NSView
{
   var weiche:Int = 0
   
   var weichenradiogruppe0:rWeichenradiogruppeH!
   var weichenradiogruppe1:rWeichenradiogruppeH!
   var weichengruppenummer:Int = 0 
   var titelFeld:NSTextField!
   
   var hintergrundfarbe = NSColor()
   var weichenstatus:[Int] = Array(repeating: 0, count: numtasten) // werte der tastenstellungen
   var weichenstellung:UInt8 = 0;
   var weichenarray:[rWeichenradiogruppeV] = []
   
   let n = 10
   var arr: [Int] = []
   
   
   
   @objc func setWeichentasten()
   {
      Swift.print("setWeichentasten \(self.bounds.width)") 
      
   }
   
   
   
   @IBAction func radioChanged(_ sender: NSButton) 
   {
      Swift.print("radioChanged")   
      Swift.print("tag: \(sender.tag) state \(sender.state)") 
      
      //gerade.state = (sender == gerade) ? .on : .off
   }
   
   
   
   required init?(coder  aDecoder : NSCoder) 
   {
      super.init(coder: aDecoder)
      
      Swift.print("rWeichenradioView init coder")
      
      NotificationCenter.default.addObserver(self, selector:#selector(tastenstatusAktion(_:)),name:NSNotification.Name(rawValue: "tastenstatus"),object:nil)
      
      self.wantsLayer = true
      let weicheviewhintergrundfarbe  = NSColor.init(red: 0.1, 
                                       green: 0.6, 
                                       blue: 0.4, 
                                       alpha: 0.25)
      self.layer?.backgroundColor =  weicheviewhintergrundfarbe.cgColor
      //self.layer?.backgroundColor =  NSColor.yellow.cgColor
      let w:CGFloat = bounds.size.width
      let h:CGFloat = bounds.size.height
      var switchH:CGFloat = 32
      let tasteW:CGFloat = 32
      let delta:CGFloat = 48
      identifier = NSUserInterfaceItemIdentifier("111")
      
      
      weiche = 15
      let titelfeldrect = NSMakeRect(w-24,h-24 , 24,24)
      titelFeld = NSTextField(frame:titelfeldrect )
      
      addSubview(titelFeld)
      titelFeld.integerValue = weiche
      
      weichenarray.reserveCapacity(numtasten)
      
      
      for col in 0..<numtasten
      {
         //let tastenrect = NSMakeRect(10 ,10 + CGFloat(row) * switchH, 2 * tasteW, switchH)
         let grupperect = NSMakeRect(10 + CGFloat(col) * delta ,8 ,  tasteW, (3*switchH))
         
         let weichenradiogruppe = rWeichenradiogruppeV(frame:(grupperect))
         weichenradiogruppe.wantsLayer = true
         //weichenradiogruppe.layer?.backgroundColor =  NSColor.red.cgColor
         var nr = 20 + 2*col
         weichenradiogruppe.weichengruppenummer = 20 + col
         weichenradiogruppe.radio0.setValue(nr)
         weichenradiogruppe.radio0.state = .on
         weichenradiogruppe.radio0.tag = 2000+nr
         //weichenradiogruppe.radio0.action = #selector(self.weichenaktion)
         nr += 1
         weichenradiogruppe.radio1.setValue(nr)
         //weichenradiogruppe.radio0.state = .off
         weichenradiogruppe.radio1.tag = 2000+nr
         weichenradiogruppe.hintergrundfarbe = .red
         weichenradiogruppe.titelFeld.stringValue = "\(col)"
         //weichenradiogruppe.radio1.action = #selector(self.weichenaktion)
         addSubview(weichenradiogruppe)
         weichenarray.append(weichenradiogruppe)      
         Swift.print("rWeichenradioView row: \(col) nr: \(nr)")
      }
      
      
      
      
   }//required
   
   @objc  func tastenstatusAktion(_ notification:Notification) 
   {
      let info = notification.userInfo
      print("rWeichenradioView tastenstatusAktion info: \(info)")
      //guard let tastenstatus = notification.userInfo?["tastenstatus"]as? [Int] else {return}
      
      guard var weichetag   = notification.userInfo?["tag"]as? Int else 
      {
         print("tastenstatusAktion tag ist nil")
         return
         
      }
      print("tastenstatusAktion weichetag raw: \(weichetag)")
      weichetag -= 2000
      weichetag -= 20
      let weiche:UInt8 = UInt8(Int(weichetag / 2))
      let ablenkung:UInt8 = UInt8(weichetag % 2)
      
      print("tastenstatusAktion weichetag: \(weichetag) weiche: \(weiche) ablenkung: \(ablenkung)")
      
      var data_gerade:UInt8 = 0
      var data_ablenkung:UInt8 = 0
      //data_gerade |= (1<<(weiche))
      data_gerade = UInt8(8 * weiche) + 8
      if(ablenkung == 1)
      {
         weichenarray[Int(weiche)].symbolView.image = ablenkungimage
         data_gerade += 4
      }
      else
      {
         weichenarray[Int(weiche)].symbolView.image = geradeimage
      }
      
      
      print("tastenstatusAktion data_gerade: \(data_gerade) data_ablenkung: \(data_ablenkung)")
      
      let userinformation = ["message":"weichenaktion", "data": data_gerade, "weiche": weiche, "ablenkung": ablenkung ] as [String : Any]
      let nc = NotificationCenter.default
      nc.post(name:Notification.Name(rawValue:"weichenstatus"),
              object: nil,
              userInfo: userinformation)
      
      
   }
   
}// rWeichenradioView
