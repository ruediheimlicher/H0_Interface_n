//
//  rDrehknopfView.swift
//  Robot_Interface
//
//  Created by Ruedi Heimlicher on 18.08.2019.
//  Copyright © 2019 Ruedi Heimlicher. All rights reserved.
//
import Cocoa
import Foundation

var zeigerfeld1 = NSMakeRect(50, 10, 50, 50)
class rDrehknopfView: rJoystickView
{
   // var zeigerfeld = NSMakeRect(10, 10, 10, 10)
   
   //   var zeiger:rZeigerView = rZeigerView(frame:zeigerfeld1)
   var ring: NSBezierPath = NSBezierPath()
   var bogen: NSBezierPath = NSBezierPath()
   
   let d:CGFloat = 40; // Durchmesser zeigerbereich
   var zeigerbereich:NSRect = NSZeroRect
   var knopfrect:NSRect = NSZeroRect
   var knopfpfad: NSBezierPath = NSBezierPath()
   var zeigerpfad: NSBezierPath = NSBezierPath()
   var abdeckrect:NSRect = NSZeroRect
   var abdeckpfad: NSBezierPath = NSBezierPath()
   var mitterect:NSRect = NSZeroRect
   var mittepfad: NSBezierPath = NSBezierPath()
   var symm = 1 // Zeiger in Mitte // 0: Zeiger links
   // Winkelbereich Drehknopf
   var maxwinkel:CGFloat = 0
   var minwinkel:CGFloat = 0
   var minarc:CGFloat = 0
      var anzticks:Int = 14;
   var lastwinkelpunkt: NSPoint = NSZeroPoint
   
   
   
   
   
   
   required init?(coder  aDecoder : NSCoder) 
   {
      super.init(coder: aDecoder)
      //Swift.print("rDrehknopfView init")
      achsen.lineWidth = 1  // hair line
      
      knopfrect = bounds
      knopfrect.insetBy(dx: 2, dy: 2)
      //     offsetBy(dx: 5, dy: <#T##CGFloat#>)
      //knopfrect.offsetBy(dx: -5, dy: -5)
      let w:CGFloat = knopfrect.size.width
      let h:CGFloat = knopfrect.size.height
      let mittex:CGFloat = knopfrect.size.width / 2
      let mittey:CGFloat = knopfrect.size.height / 2
      mittelpunkt = NSMakePoint(mittex, mittey)
      
      let radius:CGFloat = knopfrect.size.width / 2

      var symm = 1 // Zeiger in Mitte
      minwinkel = -70
      maxwinkel = 70
      let leftarcpointx = mittex - radius * cos(self.minwinkel)
      let leftarcpointy = mittey - radius * sin(self.minwinkel)
      
      let rightarcpointx = mittex + radius * cos(self.minwinkel)
      let rightarcpointy = mittey + radius * sin(self.minwinkel)
      
      let leftarcpoint = NSMakePoint(leftarcpointx, leftarcpointy)
      var digiarc:CGFloat = 0;
      
      mittelpunkt = NSMakePoint(mittex, mittey)
      
      
      achsen.move(to: NSMakePoint(0, mittey)) // start point
      achsen.line(to: NSMakePoint(w, mittey)) // destination
      achsen.move(to: NSMakePoint(mittex, 0)) // start point
      achsen.line(to: NSMakePoint(mittex, h)) // destination
      
      knopfpfad.appendRect(knopfrect)
      // weg.appendOval(in: knopfrect)
      
      // Zeiger
      let knopfradius:CGFloat = 14
      let lenunten:CGFloat = 32
      let lenoben:CGFloat = 48
      
      zeigerpfad.append(zeigerknopf(center: mittelpunkt))
      zeigerpfad.lineWidth = 1
   
      // zeigerpfad.fill() // > in draw()
      zeigerbereich = NSMakeRect(zeigerpfad.currentPoint.x - d/2, zeigerpfad.currentPoint.y - d/2,d,d)
      
      abdeckrect = bounds
      abdeckrect.size.height = abdeckrect.size.height / 2
  //    abdeckpfad.appendRect(abdeckrect) // ??
      
      
      mitterect = NSMakeRect(mittex-knopfradius, mittey-knopfradius, 2*knopfradius, 2*knopfradius)
      mittepfad.appendOval(in: mitterect)
      ring.appendOval(in: bounds)
      
      // minwinkel -90 maxwinkel 90 von Scheitelpunkt
      // startangle, endangle: ccw von x-Achse
      //bogen.move(to: mittelpunkt)
      bogen.appendArc(withCenter:  mittelpunkt, radius: knopfrect.size.height/2-2, startAngle: minwinkel + 90, endAngle: maxwinkel + 90)
      bogen.lineWidth = 4 
      
      //      Swift.print("zeiger bounds vor origin x: \(zeiger.bounds.origin.x) y: \(zeiger.bounds.origin.y) size h: \(zeiger.bounds.height) w: \(zeiger.bounds.width)")
      //      Swift.print("zeiger frame vor origin x: \(zeiger.frame.origin.x) y: \(zeiger.frame.origin.y) size h: \(zeiger.frame.height) w: \(zeiger.frame.width)")
      
      //   zeiger.setFeld(feld: self.bounds)
      //    addSubview(zeiger)
      
      //     Swift.print("zeiger bounds nach origin x: \(zeiger.bounds.origin.x) y: \(zeiger.bounds.origin.y) size h: \(zeiger.bounds.height) w: \(zeiger.bounds.width)")
      //    Swift.print("zeiger frame nach origin x: \(zeiger.frame.origin.x) y: \(zeiger.frame.origin.y) size h: \(zeiger.frame.height) w: \(zeiger.frame.width)")
      
      //    zeigerpfad.rotateAroundCenter(angle: 45)
      //weg.rotateAroundCenter(angle: -17)
   }
   
   func zeigerknopf(center:NSPoint) ->NSBezierPath
   {
      var zeigerpfad:NSBezierPath  = NSBezierPath()
      // Zeiger
      let knopfradius:CGFloat = 14
      let lenunten:CGFloat = 32
      let lenoben:CGFloat = 48
      let mittex = center.x
      let mittey = center.y

       zeigerpfad.move(to: NSMakePoint(mittex, mittey)) // , Drehpunkt
      zeigerpfad.move(to: NSMakePoint(mittex, mittey+lenoben)) // spitze
      
      zeigerpfad.line(to: NSMakePoint(mittex-8, mittey-lenunten)) // breite unten nach links
      zeigerpfad.line(to: NSMakePoint(mittex+8, mittey-lenunten)) // breite unten rechts
      zeigerpfad.line(to: NSMakePoint(mittex, mittey+lenoben)) // destination
      zeigerpfad.move(to: NSMakePoint(mittex, mittey)) // , Drehpunkt
      
      return zeigerpfad

   }
   
   
   override func mouseDown(with theEvent: NSEvent) 
   {
      
      super.mouseDown(with: theEvent)
      //          Swift.print("Drehknopf left mouse")
      let location = theEvent.locationInWindow
      //    Swift.print(location)
      //    NSPoint lokalpunkt = [self convertPoint: [anEvent locationInWindow] fromView: nil];
      let lokalpunkt = convert(theEvent.locationInWindow, from: nil)
      //    Swift.print(lokalpunkt)
      var identstring = ""
      
      let ident  = self.identifier
      if let rawident:String = ident?.rawValue
      {
         identstring = rawident
      }
      else
      {
         identstring = "13"
         
      }

      
      var userinformation:[String : Any]
      var winkelpunkt = NSZeroPoint
      
      if weg.contains(lokalpunkt)
      {
                 Swift.print("contains ok ")
         let currentx = lokalpunkt.x
         let currenty = lokalpunkt.y
         //let x = pow(Float(lokalpunkt.x) ,2)
         var spiegeln:CGFloat = 1 // Bereich rechts
         var addwinkel:CGFloat = 0
         
         //   let newhyp = CGFloat(sqrt(pow((Float(lokalpunkt.y)-Float(mittelpunkt.y)),2) + pow((Float(lokalpunkt.x) - Float(mittelpunkt.x)),2)))
         let newhyp = CGFloat(hypot((Float(lokalpunkt.y)-Float(mittelpunkt.y)), (Float(lokalpunkt.x) - Float(mittelpunkt.x))))
         
         var newarc = (lokalpunkt.y - mittelpunkt.y) / newhyp
         
         var minarc = asin(minwinkel)
               var winkelbereich = self.maxwinkel - self.minwinkel
              var winkelschritt = winkelbereich / CGFloat(anzticks-1)
              
              Swift.print("Drehknopf winkelbereich: \(winkelbereich)  winkelschritt: \(winkelschritt) minwinkel: \(self.minwinkel) maxwinkel: \(self.maxwinkel)")


         var newwinkel = asin(newarc) * 180 / CGFloat(Double.pi) //* spiegeln
         Swift.print("Drehknopf newwinkel: \(newwinkel)")

         
         //    Swift.print("md lokalpunkt.x:\t \(lokalpunkt.x)\t lokalpunkt.y: \t\(lokalpunkt.y) \tmittelpunkt.x: \t\(mittelpunkt.x)  \tmittelpunkt.y: \t\(mittelpunkt.y)\t newhyp:\t \(newhyp) \tnewarc: \t\(newarc) \tnewwinkel: \t\(newwinkel) \twinkel: \t\(winkel)")
         //    Swift.print("md newhyp: \(newhyp) winkel: \(winkel) newarc: \(newarc) newwinkel: \(newwinkel)")
         Swift.print("md newhyp: \(newhyp)  newarc: \(newarc) newwinkel: \(newwinkel)")
         zeigerpfad.removeAllPoints()
         
         let mittex:CGFloat = knopfrect.size.width / 2
         let mittey:CGFloat = knopfrect.size.height / 2
         let w:CGFloat = knopfrect.size.width
         let h:CGFloat = knopfrect.size.height
         
         // Zeiger
         let knopfradius:CGFloat = 14
         let lenunten:CGFloat = 32
         let lenoben:CGFloat = 48

         zeigerpfad.append(zeigerknopf(center: mittelpunkt))
          zeigerpfad.lineWidth = 1 
         
         if (lokalpunkt.x > mittelpunkt.x)
         {
            // zeigerpfad.rotateAroundCenterB(angle:(newwinkel - 90) )
            winkelpunkt.x = (newwinkel - 90)
            if ( winkelpunkt.x < minwinkel)
            {
               Swift.print("Drehknopf winkel < minwinkel")
               winkelpunkt.x = minwinkel
            }
            
         }
         else
         {
            
            winkelpunkt.x = (90 - newwinkel )
            if ( winkelpunkt.x > maxwinkel)
            {
               Swift.print("Drehknopf winkel > maxwinkel")
               winkelpunkt.x = maxwinkel
            }
            
         }
         var zeigermitte = NSMakePoint(mittex, mittey)
         zeigerpfad.rotateAroundCenter(center:zeigermitte, angle:winkelpunkt.x)
         
         zeigerbereich = NSMakeRect(zeigerpfad.currentPoint.x - d/2, zeigerpfad.currentPoint.y - d/2,d,d)
         
      }
      userinformation = ["message":"mousedown", "punkt": winkelpunkt, "index": weg.elementCount, "first": -1] as [String : Any]
      userinformation["ident"] = identstring
      
      let nc = NotificationCenter.default
      nc.post(name:Notification.Name(rawValue:"drehknopf"),
              object: nil,
              userInfo: userinformation)
      
      
      
   }
   
   override func mouseDragged(with theEvent: NSEvent) 
   {
    //  Swift.print("Drehknopf mouseDragged")
      let location = theEvent.locationInWindow
      //Swift.print(location)
      var lokalpunkt = convert(theEvent.locationInWindow, from: nil)
      var userinformation:[String : Any]
      var winkelpunkt = NSZeroPoint
      Swift.print(lokalpunkt)
      
      zeigerpfad.removeAllPoints()
      let mittex:CGFloat = knopfrect.size.width / 2
      let mittey:CGFloat = knopfrect.size.height / 2
      mittelpunkt = NSMakePoint(mittex, mittey)
      zeigerpfad.append(zeigerknopf(center: mittelpunkt))
       zeigerpfad.lineWidth = 3 
     
      if ring.contains( lokalpunkt) // Klick im Kreis
      {
         //Swift.print("Drehknopf mouseDragged punkt inside")
         let newhyp = CGFloat(sqrt(pow((Float(lokalpunkt.y)-Float(mittelpunkt.y)),2) + pow((Float(lokalpunkt.x) - Float(mittelpunkt.x)),2)))
         var newarc = (lokalpunkt.y - mittelpunkt.y) / newhyp
         
         var newwinkel = asin(newarc) * 180 / CGFloat(Double.pi)  //
         Swift.print("Drehknopf newwinkel: \(newwinkel)  maxwinkel: \(maxwinkel) minwinkel: \(minwinkel)")
            
         if (lokalpunkt.x > mittelpunkt.x)
         {
            //       zeigerpfad.rotateAroundCenterB(angle:(newwinkel - 90) )
            winkelpunkt.x = (newwinkel - 90)
            if ( winkelpunkt.x < minwinkel)
            {
               Swift.print("Drehknopf winkel < minwinkel")
               winkelpunkt.x = minwinkel
            }
            winkelpunkt.y =  1
         }
         else
         {
            //         zeigerpfad.rotateAroundCenterB(angle:(90 - newwinkel ) )
            winkelpunkt.x = (90 - newwinkel )
            if ( winkelpunkt.x > maxwinkel)
            {
               Swift.print("Drehknopf winkel > maxwinkel")
               winkelpunkt.x = maxwinkel
            }
            winkelpunkt.y = -1
         }
         lastwinkelpunkt = winkelpunkt
         zeigerpfad.rotateAroundCenter(center:mittelpunkt, angle:winkelpunkt.x )
         
         //winkelpunkt.x = (newwinkel - 90)
         // zeigerbereich = NSMakeRect(zeigerpfad.currentPoint.x - d/2, zeigerpfad.currentPoint.y - d/2,d,d)
      }
      else
      {
         Swift.print("Drehknopf mouseDragged punkt outside")
         winkelpunkt = lastwinkelpunkt 
         zeigerpfad.rotateAroundCenterB(angle:winkelpunkt.x )
         
      }
      
      //Swift.print("Drehknopf mouseDragged winkelpunkt: \(winkelpunkt)")
      needsDisplay = true
      userinformation = ["message":"mousedown", "punkt": winkelpunkt, "index": weg.elementCount, "first": -1] as [String : Any]
      userinformation["ident"] = self.identifier
      
      let nc = NotificationCenter.default
      nc.post(name:Notification.Name(rawValue:"drehknopf"),
              object: nil,
              userInfo: userinformation)
            
   }
   
   // https://stackoverflow.com/questions/21751105/mac-os-x-convert-between-nsview-coordinates-and-global-screen-coordinates
   override func draw(_ dirtyRect: NSRect) 
   {
      // https://stackoverflow.com/questions/36596545/how-to-draw-a-dash-line-border-for-nsview
      //     super.draw(dirtyRect)
      
      // dash customization parameters
      let dashHeight: CGFloat = 1
      let dashColor: NSColor = .blue
      
      let trigohintergrundfarbe:NSColor  = NSColor.init(red: 0.25, 
                                                        green: 0.85, 
                                                        blue: 0.85, 
                                                        alpha: 0.25) 
      
      hgfarbe  = NSColor.init(red: 0.25, 
                              green: 0.25, 
                              blue: 0.85, 
                              alpha: 0.25)
      // setup the context
      //    let currentContext = NSGraphicsContext.current()!.cgContext
      //currentContext.setLineWidth(dashHeight)
      //currentContext.setLineDash(phase: 0, lengths: [dashLength])
      // currentContext.setStrokeColor(dashColor.cgColor)
      
      // draw the dashed path
      //   currentContext.addRect(bounds.insetBy(dx: dashHeight, dy: dashHeight))
      //    currentContext.strokePath()
      
      NSColor.blue.set() // choose color
      hgfarbe.set() // choose color
      
      knopfpfad.fill()
      //     kreuz.stroke()
      NSColor.green.set() // choose color
      
      weg.lineWidth = 2
      //      weg.stroke()  // draw line(s) in color
      ring.lineWidth = 2
      //     ring.stroke()
      NSColor.red.set() // choose color
      zeigerpfad.stroke()
      zeigerpfad.fill()
      mittepfad.fill()
      NSColor.yellow.set() 
      //bogen.fill()
      NSColor.blue.set() 
      
      bogen.stroke()
      NSColor.yellow.set() 
      trigohintergrundfarbe.set()
      
      hgfarbe.set()
      //   abdeckpfad.fill()
      //   var zeigerrand:NSBezierPath = NSBezierPath(rect:zeigerbereich)
      //      zeigerrand.stroke()
      
      
      
      //      zeigerrandB.stroke()
      
      let currentx = zeigerpfad.currentPoint.x
      let currenty = zeigerpfad.currentPoint.y
      hyp = CGFloat(sqrt(pow((Float(currenty)-Float(mittelpunkt.y)),2) + pow((Float(currentx) - Float(mittelpunkt.x)),2)))
      
      let arc = (currenty - mittelpunkt.y) / hyp
      winkel = asin(arc) * 180 / CGFloat(Double.pi)
      //    Swift.print("draw currentx: \t\(currentx) \tcurrenty: \t\(currenty) \tmittelpunkt.x: \t\(mittelpunkt.x)  \tmittelpunkt.y: \t\(mittelpunkt.y)\t hyp:\t\(hyp)\t newarc: \t\(arc) \tnewwinkel: \t\(winkel) \twinkel: \t\(winkel)")
      //   Swift.print("draw   hyp: \(hyp) winkel: \(winkel) arc: \(arc) ")
      //    Swift.print("draw   hyp: \(hyp) arc: \(arc) ")
      
      //Swift.print("currentx: \(currentx) currenty: \(currenty) winkel: \(winkel)")
      needsDisplay = true
   } // draw
} // DerhknopfView
