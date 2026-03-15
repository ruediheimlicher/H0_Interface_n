//
//  rWeicheSwitch.swift
//  H0_Interface
//
//  Created by Ruedi Heimlicher on 02.03.2026.
//  Copyright © 2026 Ruedi Heimlicher. All rights reserved.
//

import Foundation

import Cocoa
import AppKit

var numtasten:Int = 8




class rWeichentaste:NSSwitch
{
   
   override init(frame frameRect: NSRect) 
   
   {
      Swift.print("rWeichetaste init frame")
      super.init(frame: frameRect)
      configure()
   }
   
   func configure()
   {
      self.state = .off
      self.target = self
      self.action = #selector(self.report_weichentaste)
      self.controlSize = .small
      
      
   }
   required init?(coder  aDecoder : NSCoder) 
   {
      super.init(coder: aDecoder)
      configure()
      let t = self.tag
      Swift.print("rWeichetaste init coder tag: \(t)")
      self.action = #selector(self.report_weichentaste)
   }
   
   @IBAction  func report_weichentaste(_ sender: NSButton)
   {
      Swift.print("report_weichentaste \(self.tag)")  
      let status = sender.state
      let ident = self.identifier
      let tastetag = self.tag
   }
   
}// rWeichetaste

class rWeichentastenView:NSView
{
   
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
   
   
   @objc func selectRadio(_ sender: NSButton) 
   {
      Swift.print("selectRadio state: \(sender.state.rawValue)") 
      //radios.forEach { $0.state = ($0 == sender) ? .on : .off }
   }
   var weiche:Int = 0
   
   var weichengruppe = 0 
   var titelFeld:NSTextField!
   
   var hintergrundfarbe = NSColor()
   var weichenstatus:[Int] = Array(repeating: 0, count: numtasten) // werte der tastenstellungen
   var weichenstellung:UInt8 = 0;
   
   required init?(coder  aDecoder : NSCoder) 
   {
      super.init(coder: aDecoder)
      Swift.print("rWeichentastenView init")
      self.wantsLayer = true
      hintergrundfarbe  = NSColor.init(red: 0, 
                                       green: 0.2, 
                                       blue: 1.0, 
                                       alpha: 0.25)
      self.layer?.backgroundColor =  hintergrundfarbe.cgColor
      
      let w:CGFloat = bounds.size.width
      let h:CGFloat = bounds.size.height
      let switchH = h/Double(numtasten)
      let tasteW:CGFloat = 30
      identifier = NSUserInterfaceItemIdentifier("111")
      weiche = 10
      
      let titelfeldrect = NSMakeRect(w-24,h-24 , 24,24)
      titelFeld = NSTextField(frame:titelfeldrect )
      
      addSubview(titelFeld)
      titelFeld.integerValue = weiche
      
      for row in 0..<numtasten
      {
         let tastenrect = NSMakeRect(5,Double(row)*switchH , tasteW,switchH)
         
         let ident = 2000 + 10 * row 
         //print("weichentastenview row: \(row)  ident: \(ident) weiche: \(weiche)")
         
         var weichentaste:rWeichentaste = rWeichentaste(frame: tastenrect)
         addSubview(weichentaste)
         //var weichentaste:rWeichentaste = self.viewWithTag(ident) as! rWeichentaste
         
         let tastetag = weichentaste.tag
         weichentaste.tag = ident
         weichentaste.target = self 
         weichentaste.action = #selector(self.weichenaktion)
         
      }
      
      
      
   } // required init
   
   @IBAction func weichenaktion(_ sender: NSButton)
   {
      print("weichenaktion weichenstatus vor: \(weichenstatus) tag: \(sender.tag) ")
      for row in 0..<numtasten
      {
         
      }
      let taste = (sender.tag - 2000) / 10
      print("weichenaktion taste: \(taste)") 
      weichenstatus[taste] ^= 1   // invertieren
      
      for bit in 0..<numtasten
      {
         if(weichenstatus[bit] != 0)
         {
            weichenstellung |= (1<<bit) 
         }
         else
         {
            
         }
      }
      print("weichenaktion weichenstatus nach: \(weichenstatus) weichenstellung: \(weichenstellung)")
      let userinformation = ["message":"weichenaktion", "weichenstatus": weichenstatus,"weichenstellung": weichenstellung,"weiche":3, "ident":identifier] as [String : Any]
      let nc = NotificationCenter.default
      nc.post(name:Notification.Name(rawValue:"weichenstatus"),
              object: nil,
              userInfo: userinformation)
      
      
   }
   
}


