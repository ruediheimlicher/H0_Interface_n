//
//  HID.c
//  USB_Stepper
//
//  Created by Ruedi Heimlicher on 30.Juli.11.
//  Copyright 2011 Skype. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/hid/IOHIDBase.h>
#include <IOKit/hid/IOHIDManager.h>
#include "hid.h"

#include <CoreFoundation/CoreFoundation.h>

#define USBATTACHED           5
#define USBREMOVED            6

#define BUFFER_SIZE 64

#define PRODUCT_ID 0x486
#define VENDOR_ID 0x16C0

//#define printf(...) // comment this out to get lots of info printed

static IONotificationPortRef    gNotifyPort;
static io_iterator_t             gAddedIter;
static io_iterator_t          addedIterator;
static io_iterator_t          removedIterator;


int usbattachstatus;

// a list of all opened HID devices, so the caller can
// simply refer to them by number
typedef struct hid_struct hid_t;
typedef struct buffer_struct buffer_t;
static hid_t *first_hid = NULL;
static hid_t *last_hid = NULL;
struct hid_struct 
{
   IOHIDDeviceRef ref;
   int open;
   uint8_t buffer[BUFFER_SIZE];
   buffer_t *first_buffer;
   buffer_t *last_buffer;
   struct hid_struct *prev;
   struct hid_struct *next;
};
struct buffer_struct {
   struct buffer_struct *next;
   uint32_t len;
   uint8_t buf[BUFFER_SIZE];
};

uint product_ID = PRODUCT_ID;

uint vendor_ID = VENDOR_ID;
int hid_usbstatus=0;
int rawhid_recv(int num, void *buf, int len, int timeout);

// private functions, not intended to be used from outside this file

static void add_hid(hid_t *);
static hid_t * get_hid(int);
void free_all_hid(void);
static void hid_close(hid_t *);
static void attach_callback(void *, IOReturn, void *, IOHIDDeviceRef);
static void detach_callback(void *, IOReturn, void *hid_mgr, IOHIDDeviceRef dev);
static void timeout_callback(CFRunLoopTimerRef, void *);
static void input_callback(void *, IOReturn, void *, IOHIDReportType,uint32_t, uint8_t *, CFIndex);

IOHIDManagerRef hidManager;

const int BufferSize(void)
{
   return BUFFER_SIZE;
}

int rawhid_init(uint vendor_ID)
{
   fprintf(stderr,"rawhid_init \n");
   hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
   if (hidManager == NULL) {
      printf("Failed to create HID Manager\n");
      return -1;
   }
   if (CFGetTypeID(hidManager) != IOHIDManagerGetTypeID()) {
      printf("Failed to create HID Manager.\n");
      return -2;
   }
   // Create a matching dictionary for Vendor ID (and optionally Product ID)
   CFMutableDictionaryRef matchingDict = CFDictionaryCreateMutable(kCFAllocatorDefault,
         0,
         &kCFTypeDictionaryKeyCallBacks,
         &kCFTypeDictionaryValueCallBacks);
   if (!matchingDict) 
   {
      printf("Failed to create matching dictionary.\n");
      return -3;
   }
   /*
   CFNumberRef vendorIDRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vendor_ID);
   CFDictionarySetValue(matchingDict, CFSTR(kIOHIDVendorIDKey), vendorIDRef);
   CFNumberRef productIDRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &product_ID);
   CFDictionarySetValue(matchingDict, CFSTR(kIOHIDProductIDKey), productIDRef);

   
   IOHIDManagerSetDeviceMatching(hidManager, matchingDict);
   
   CFSetRef deviceSet = IOHIDManagerCopyDevices(hidManager);
   if (deviceSet == NULL) 
   {
      printf("No HID devices found.\n");
   } 
   else
   {
      CFIndex deviceCount = CFSetGetCount(deviceSet);
      printf("Found %ld HID devices.\n", deviceCount);
      
      IOHIDDeviceRef devices[deviceCount];
      CFSetGetValues(deviceSet, (const void **)devices);
      
      for (CFIndex i = 0; i < deviceCount; i++) 
      {
         IOHIDDeviceRef device = devices[i];
         printf("Device %ld:\n", i + 1);
         
         CFTypeRef vendorID = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey));
         CFNumberRef numberRef = (CFNumberRef)vendorID;
         int intValue;
         
         if (CFNumberGetValue((CFNumberRef)vendorID, kCFNumberIntType, &intValue))
         {
            // Successfully retrieved the integer value
            printf("vendor ID Integer value: %d\n", intValue);
         }
         CFTypeRef productID = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey));
         numberRef = (CFNumberRef)productID;
         if (CFNumberGetValue(((CFNumberRef)productID), kCFNumberIntType, &intValue))
         {
            // Successfully retrieved the integer value
            printf("product ID Integer value: %d\n", intValue);
         }
         
        }// for
      
      CFRelease(deviceSet);
 
   }
   // Cleanup
   CFRelease(vendorIDRef);
   CFRelease(productIDRef);
   CFRelease(matchingDict);
   //IOHIDManagerClose(hidManager, kIOHIDOptionsTypeNone);
   //CFRelease(hidManager);

   */
   
   
   return 1;
}

int rawhid_startcallback(void)
{
   printf("rawhid_startcallback\n");
   // register callback
   // Create a matching dictionary for HID devices
   CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOHIDDeviceKey);
    
   if (!matchingDict) 
   
   {
         fprintf(stderr, "Failed to create matching dictionary\n");
         return EXIT_FAILURE;
     }
   // Set up a notification port
    IONotificationPortRef notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
    if (!notificationPort) {
        fprintf(stderr, "Failed to create notification port\n");
        return EXIT_FAILURE;
    }
   // Run loop source for notifications
    CFRunLoopSourceRef runLoopSource = IONotificationPortGetRunLoopSource(notificationPort);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);

   // Register for device matching notifications
    io_iterator_t addedIter;
    kern_return_t result = IOServiceAddMatchingNotification(
        notificationPort,
        kIOFirstMatchNotification,
        matchingDict,
        deviceAddedCallback,
        NULL,
        &addedIter
    );

   if (result != KERN_SUCCESS) {
        fprintf(stderr, "Failed to register matching notification\n");
        IONotificationPortDestroy(notificationPort);
        return EXIT_FAILURE;
    }

   // Handle any devices already present
    deviceAddedCallback(NULL, addedIter);

   // Run the run loop to wait for device insertion
    printf("Waiting for USB HID devices to be inserted...\n");
    CFRunLoopRun();


   
   return 0;
}


int rawhid_recv(int num, void *buf, int len, int timeout)
{
   //fprintf(stderr,"rawhid_recv start len: %d\n",len);
   //fprintf(stderr,"rawhid_recv start \n");
   hid_t *hid;
   buffer_t *b;
   CFRunLoopTimerRef timer=NULL;
   CFRunLoopTimerContext context;
   int ret=0, timeout_occurred=0;
   
   if (len < 1) return 0;
   hid = get_hid(num);
   if (!hid || !hid->open) return -1;
   if ((b = hid->first_buffer) != NULL)
   {
      if (len > b->len) len = b->len;
      memcpy(buf, b->buf, len);
      hid->first_buffer = b->next;
      free(b);
      // fprintf(stderr,"rawhid_recv A len: %d\n\n",len);
      return len;
   }
   memset(&context, 0, sizeof(context));
   context.info = &timeout_occurred;
   timer = CFRunLoopTimerCreate(NULL, CFAbsoluteTimeGetCurrent() +(double)timeout / 1000.0, 0, 0, 0, timeout_callback, &context);
   CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);
   while (1) 
   {
      CFRunLoopRun();
      if ((b = hid->first_buffer) != NULL) {
         if (len > b->len) len = b->len;
         memcpy(buf, b->buf, len);
         hid->first_buffer = b->next;
         free(b);
         ret = len;
         break;
      }
      if (!hid->open) {
         //printf("rawhid_recv, device not open\n");
         ret = -1;
         break;
      }
      if (timeout_occurred) break;
   }
   CFRunLoopTimerInvalidate(timer);
   CFRelease(timer);
   //fprintf(stderr,"rawhid_recv ret: %d\n",ret);
   return ret;
   
}




//
static void add_hid(hid_t *h)
{

//   fprintf(stderr, "add_hid\n");
   //IOHIDDeviceRef* r= &h->ref;
   
   CFTypeRef prod = IOHIDDeviceGetProperty(h->ref, CFSTR(kIOHIDProductKey));
   
   CFTypeRef prop= IOHIDDeviceGetProperty(h->ref,CFSTR(kIOHIDManufacturerKey));
   //CFStringRef manu = (CFStringRef)prop;
//   const char* manustr = CFStringGetCStringPtr(prop, kCFStringEncodingMacRoman);
//   fprintf(stderr,"manustr: %s\n",manustr);
   
   if (!first_hid || !last_hid) 
   {
      first_hid = last_hid = h;
      h->next = h->prev = NULL;
      return;
   }
   last_hid->next = h;
   h->prev = last_hid;
   h->next = NULL;
   last_hid = h;
}


static hid_t * get_hid(int num)
{
   hid_t *p;
   for (p = first_hid; p && num > 0; p = p->next, num--) ;
   return p;
}


void free_all_hid(void)
{
   hid_t *p, *q;
   
   for (p = first_hid; p; p = p->next) 
   {
      hid_close(p);
   }
   p = first_hid;
   while (p) {
      q = p;
      p = p->next;
      free(q);
   }
   first_hid = last_hid = NULL;
}
 


const char* get_manu(void)
{
   return "*\n";
   hid_t * cnc = get_hid(0);
   if (cnc)
   {
      CFTypeRef manu= IOHIDDeviceGetProperty(cnc->ref,CFSTR(kIOHIDManufacturerKey));
      //CFStringRef manu = (CFStringRef)prop;
      
      const char* manustr = CFStringGetCStringPtr(manu, kCFStringEncodingMacRoman);
      //fprintf(stderr,"manustr: %s\n",manustr);   
      return  manustr; 
   }
   else 
   {
      return "Kein USB-Device vorhanden\n";
   }
   
}


const char* get_prod(void)
{
   hid_t * cnc = get_hid(0);
   if (cnc)
   {
      CFTypeRef prod= IOHIDDeviceGetProperty(cnc->ref,CFSTR(kIOHIDProductKey));
      //CFStringRef manu = (CFStringRef)prop;
      const char* prodstr = CFStringGetCStringPtr(prod, kCFStringEncodingMacRoman);
      //fprintf(stderr,"prodstr: %s\n",prodstr);
      
      return  prodstr; 
   }
   else 
   {
      return "***\n";
   }
}

int getX(void)
{
   return 13;
}


//  rawhid_send - send a packet
//    Inputs:
//   num = device to transmit to (zero based)
//   buf = buffer containing packet to send
//   len = number of bytes to transmit
//   timeout = time to wait, in milliseconds
//    Output:
//   number of bytes sent, or -1 on error
//
int rawhid_send(int num, uint8_t *buf, int len, int timeout)
{
   //fprintf(stderr,"rawhid_send num: %d\n",num);
   hid_t *hid;
   int result=-100;
  // fprintf(stderr,"rawhid_send a len: %d\n",len);
  // fprintf(stderr,"rawhid_send a buf 0: %d\n",(uint8_t)buf[0]);
   hid = get_hid(num);
   if (!hid || !hid->open) return -1;
   //fprintf(stderr,"rawhid_send A\n");
//#if 1
//#warning "Send timeout not implemented on MACOSX"
   IOReturn ret = IOHIDDeviceSetReport(hid->ref, kIOHIDReportTypeOutput, 0, buf, (CFIndex)len);
   result = (ret == kIOReturnSuccess) ? len : -1;
 //  fprintf(stderr,"rawhid_send B result: %d\n",result);
//#endif
#if 0
   // No matter what I tried this never actually sends an output
   // report and output_callback never gets called.  Why??
   // Did I miss something?  This is exactly the same params as
   // the sync call that works.  Is it an Apple bug?
   // (submitted to Apple on 22-sep-2009, problem ID 7245050)
   //
   //fprintf(stderr,"rawhid_send C\n");
   IOHIDDeviceScheduleWithRunLoop(hid->ref, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
   // should already be scheduled with run loop by attach_callback,
   // sadly this doesn't make any difference either way
   //
   IOHIDDeviceSetReportWithCallback(hid->ref, kIOHIDReportTypeOutput,
                                    0, buf, len, (double)timeout / 1000.0, output_callback, &result);
   //fprintf(stderr,"rawhid_send D\n");
   while (1) 
   {
      fprintf(stderr,"enter run loop (send)\n");
      CFRunLoopRun();
      fprintf(stderr,"leave run loop (send)\n");
      if (result > -100) break;
      if (!hid->open) 
      {
         result = -1;
         break;
      }
   }
#endif
  // fprintf(stderr,"rawhid_send end result: %d\n",result);
   return result;
}


//  rawhid_open - open 1 or more devices
//
//    Inputs:
//   max = maximum number of devices to open
//   vid = Vendor ID, or -1 if any
//   pid = Product ID, or -1 if any
//   usage_page = top level usage page, or -1 if any
//   usage = top level usage number, or -1 if any
//    Output:
//   actual number of devices opened
//




int rawhid_open(int max, int vid, int pid, int usage_page, int usage)
{
   
   kern_return_t           result;
   mach_port_t             masterPort;
   //CFMutableDictionaryRef  matchingDict = NULL;
   CFRunLoopSourceRef      runLoopSource;
   fprintf(stderr,"rawhid_open vid: %d pid: %d\n",vid,pid);
   
   
   //Create a master port for communication with the I/O Kit
   result = IOMasterPort(MACH_PORT_NULL, &masterPort);
   if (result || !masterPort)
   {
      return -1;
   }
   
   //To set up asynchronous notifications, create a notification port and
   //add its run loop event source to the programs run loop
   gNotifyPort = IONotificationPortCreate(masterPort);
   
   runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
   CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource,
                      kCFRunLoopDefaultMode);
    
   static IOHIDManagerRef hid_manager=NULL;
   CFMutableDictionaryRef dict;
   CFNumberRef num;
   IOReturn ret;
   hid_t *p;
   int count=0;
  
   
   
   if (first_hid) free_all_hid();
   //printf("rawhid_open, max=%d\n", max);
   //fflush (stdout); 
   if (max < 1) return 0;
   // Start the HID Manager
   if (hid_manager) 
   {
      CFRelease(hid_manager);
      hid_manager = NULL;
   }

   // http://developer.apple.com/technotes/tn2007/tn2187.html
   if (!hid_manager)
   {
      hid_manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
      if (hid_manager == NULL || CFGetTypeID(hid_manager) != IOHIDManagerGetTypeID()) 
      {
         if (hid_manager) CFRelease(hid_manager);
         return 0;
      }
   }
   
   if (vid > 0 || pid > 0 || usage_page > 0 || usage > 0) {
      // Tell the HID Manager what type of devices we want
      dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                       &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
      if (!dict) return 0;
      if (vid > 0) 
      {
         num = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vid);
         CFDictionarySetValue(dict, CFSTR(kIOHIDVendorIDKey), num);
         CFRelease(num);
      }
      if (pid > 0) 
      {
         num = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &pid);
         CFDictionarySetValue(dict, CFSTR(kIOHIDProductIDKey), num);
         CFRelease(num);
      }
      if (usage_page > 0) 
      {
         num = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usage_page);
         CFDictionarySetValue(dict, CFSTR(kIOHIDPrimaryUsagePageKey), num);
         CFRelease(num);
      }
      if (usage > 0) 
      {
         num = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usage);
         CFDictionarySetValue(dict, CFSTR(kIOHIDPrimaryUsageKey), num);
         CFRelease(num);
      }
      IOHIDManagerSetDeviceMatching(hid_manager, dict);
      CFRelease(dict);
   } 
   else 
   {
      IOHIDManagerSetDeviceMatching(hid_manager, NULL);
   }
   // set up a callbacks for device attach & detach
   IOHIDManagerScheduleWithRunLoop(hid_manager, CFRunLoopGetCurrent(),
                                   kCFRunLoopDefaultMode);
   IOHIDManagerRegisterDeviceMatchingCallback(hid_manager, attach_callback, NULL);
   IOHIDManagerRegisterDeviceRemovalCallback(hid_manager, detach_callback, NULL);
   ret = IOHIDManagerOpen(hid_manager, kIOHIDOptionsTypeNone);
   if (ret != kIOReturnSuccess) 
   {
      IOHIDManagerUnscheduleFromRunLoop(hid_manager,
                                        CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
      CFRelease(hid_manager);
      return 0;
   }
//   printf("run loop\n");
   // let it do the callback for all devices
   while (CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true) == kCFRunLoopRunHandledSource) ;
   // count up how many were added by the callback
   for (p = first_hid; p; p = p->next) count++;
   
   hid_usbstatus=count;
   printf("rawhid_open end count: %d\n",count);
   return count;
}



static void hid_close(hid_t *hid)
{
   //printf("hid_close hid->ref: %d",hid->open);
   if (hid->open > 0)
   {
      printf("hid_close return ");
      return;
   }
   if (!hid || !(hid->open == 1)|| !hid->ref) return;
    
   IOHIDDeviceUnscheduleFromRunLoop(hid->ref, CFRunLoopGetCurrent( ), kCFRunLoopDefaultMode);
   IOHIDDeviceClose(hid->ref, kIOHIDOptionsTypeNone);
   hid->ref = NULL;
}


int rawhid_status(void)
{
   //fprintf(stderr,"status: %d\n",hid_usbstatus);
   return hid_usbstatus;
}

int get_hid_usbstatus(void)
{
   //fprintf(stderr,"get_hid_usbstatus: %d\n",hid_usbstatus);
   return hid_usbstatus;
}

/*
static void input_callback(void *context, IOReturn ret, void *sender,
                           IOHIDReportType type, uint32_t id, uint8_t *data, CFIndex len)
{
   buffer_t *n;
   hid_t *hid;
   
   //fprintf(stderr,"input_callback\n");
   if (ret != kIOReturnSuccess || len < 1) return;
   hid = context;
   if (!hid || hid->ref != sender) return;
   n = (buffer_t *)malloc(sizeof(buffer_t));
   if (!n) return;
   if (len > BUFFER_SIZE) len = BUFFER_SIZE;
   memcpy(n->buf, data, len);
   n->len = len;
   n->next = NULL;
   if (!hid->first_buffer || !hid->last_buffer) {
      hid->first_buffer = hid->last_buffer = n;
   } else {
      hid->last_buffer->next = n;
      hid->last_buffer = n;
   }
   CFRunLoopStop(CFRunLoopGetCurrent());
}

 */

static void timeout_callback(CFRunLoopTimerRef timer, void *info)
{
   //fprintf(stderr,"timeout_callback\n");
   *(int *)info = 1;
   CFRunLoopStop(CFRunLoopGetCurrent());
}


void output_callback(void *context, IOReturn ret, void *sender,
                     IOHIDReportType type, uint32_t id, uint8_t *data, CFIndex len)
{
   fprintf(stderr,"output_callback, r=%d\n", ret);
   if (ret == kIOReturnSuccess) 
   {
      *(int *)context = (uint32_t)len;
   } else {
      // timeout if not success?
      *(int *)context = 0;
   }
   CFRunLoopStop(CFRunLoopGetCurrent());
}

static void input_callback(void *context, IOReturn ret, void *sender,
                           IOHIDReportType type, uint32_t id, uint8_t *data, CFIndex len)
{
   buffer_t *n;
   hid_t *hid;
   
   //fprintf(stderr,"input_callback\n");
   if (ret != kIOReturnSuccess || len < 1) return;
   hid = context;
   if (!hid || hid->ref != sender) return;
   n = (buffer_t *)malloc(sizeof(buffer_t));
   if (!n) return;
   if (len > BUFFER_SIZE) len = BUFFER_SIZE;
   memcpy(n->buf, data, len);
   n->len = (uint32_t)len;
   n->next = NULL;
   if (!hid->first_buffer || !hid->last_buffer) {
      hid->first_buffer = hid->last_buffer = n;
   } else {
      hid->last_buffer->next = n;
      hid->last_buffer = n;
   }
   //free(n);
   CFRunLoopStop(CFRunLoopGetCurrent());
}


static void detach_callback(void *context, IOReturn r, void *hid_mgr, IOHIDDeviceRef dev)
{
   hid_t *p;
   
   fprintf(stderr,"hid detach callback\n");
   //hid_usbstatus=0;
   
   for (p = first_hid; p; p = p->next) {
      if (p->ref == dev) 
      {
         p->open = 0;
         
         usbattachstatus = 0;
         CFRunLoopStop(CFRunLoopGetCurrent());
         NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
         NSDictionary* NotDic = [NSDictionary  dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:USBREMOVED],@"attach",[NSNumber numberWithInt:usbattachstatus],@"usbattachstatus", nil];
         [nc postNotificationName:@"usb_attach" object:NULL userInfo:NotDic];
         fprintf(stderr,"detach notification\n");

         return;
      }
   }
}


static void attach_callback(void *context, IOReturn r, void *hid_mgr, IOHIDDeviceRef dev)
{
   
   struct hid_struct *h;
   
   
   fprintf(stderr,"*** hid attach_callback\n");
   //
   if (IOHIDDeviceOpen(dev, kIOHIDOptionsTypeNone) != kIOReturnSuccess) 
   {
      fprintf(stderr,"hid attach callback not kIOReturnSuccess\n");
      return;
   }
   
   h = (hid_t *)malloc(sizeof(hid_t));
   if (!h) 
   {
      fprintf(stderr,"hid attach_callback not h\n");
      return;
   }
   memset(h, 0, sizeof(hid_t));
   
   IOHIDDeviceScheduleWithRunLoop(dev, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);   
   IOHIDDeviceRegisterInputReportCallback(dev, h->buffer, sizeof(h->buffer), input_callback, h);
   h->ref = dev;
   h->open = 1;
   add_hid(h);
   
   //hid_usbstatus=1;
   

   
   usbattachstatus = 1;
   NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
   NSDictionary* NotDic = [NSDictionary  dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:USBATTACHED],@"attach",[NSNumber numberWithInt:usbattachstatus],@"usbattachstatus", nil];
   [nc postNotificationName:@"usb_attach" object:NULL userInfo:NotDic];
   fprintf(stderr,"hid nach attach_callback notification\n");

}

void printCFType(CFTypeRef cf) 
{
    if (cf != NULL) {
        CFStringRef description = CFCopyDescription(cf);
        if (description != NULL) {
            CFShow(description);
            CFRelease(description);
        } else {
            printf("Object has no description.\n");
        }
    } else {
        printf("NULL object passed to printCFType.\n");
    }
}

CFRange containsSubstring(CFStringRef string, CFStringRef substring) {
    // Use CFStringFind to search for substring in the string
    CFRange range = CFRangeMake(0, CFStringGetLength(string)); // Search the entire string
    CFStringCompareFlags options = kCFCompareCaseInsensitive;  // Case-insensitive comparison
    
    // Check if the substring is found
    return CFStringFind(string, substring,  options);
}

int check_usb_attach(void)
{
   CFMutableDictionaryRef matchingDict;
   io_iterator_t iter;
   kern_return_t kr;
   io_service_t device;
   int anzahl=0;
   
   // set up a matching dictionary for the class 
   matchingDict = IOServiceMatching("IOUSBDevice");
   if (matchingDict == NULL)
   {
      fprintf(stderr, "Unable to create matching dictionary\n");
      return -1; // fail
   }
   // Now we have a dictionary, get an iterator.
   kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iter);
   if (kr != KERN_SUCCESS)
   {
      fprintf(stderr, "IOServiceGetMatchingServices failed\n");
      return -1;
   }
   
   return 0;
}



int findHIDDevicesWithVendorID(uint32_t vendorID) 
{
   int anzahl = 0;
   IOHIDManagerRef hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
   if (!hidManager) {
      fprintf(stderr, "Failed to create HID Manager.\n");
      return -1;
   }
   
   // Create a matching dictionary for devices with the specified Vendor ID
   CFMutableDictionaryRef matchingDict = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                   0,
                                                                   &kCFTypeDictionaryKeyCallBacks,
                                                                   &kCFTypeDictionaryValueCallBacks);
   if (!matchingDict) {
      fprintf(stderr, "Failed to create matching dictionary.\n");
      CFRelease(hidManager);
      return -1;
   }
   
   CFNumberRef vendorIDRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vendorID);
   if (!vendorIDRef) {
      fprintf(stderr, "Failed to create CFNumber for Vendor ID.\n");
      CFRelease(matchingDict);
      CFRelease(hidManager);
      return -1;
   }
   
   CFDictionarySetValue(matchingDict, CFSTR(kIOHIDVendorIDKey), vendorIDRef);
   IOHIDManagerSetDeviceMatching(hidManager, matchingDict);
   
   // Get matching devices
   CFSetRef deviceSet = IOHIDManagerCopyDevices(hidManager);
   if (!deviceSet) {
      printf("No devices found for Vendor ID: %u\n", vendorID);
   } 
   else 
   {
      CFIndex deviceCount = CFSetGetCount(deviceSet);
      printf("Found %ld devices with Vendor ID: %u\n", deviceCount, vendorID);
      anzahl++;
      
      return anzahl;
      
      
      IOHIDDeviceRef *deviceArray = malloc(deviceCount * sizeof(IOHIDDeviceRef));
      CFSetGetValues(deviceSet, (const void **)deviceArray);
      
      for (CFIndex i = 0; i < deviceCount; i++) {
         IOHIDDeviceRef device = deviceArray[i];
         printf("Device %ld:\n", i + 1);
         
         // Get some device properties as an example
         CFTypeRef productName = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
         if (productName && CFGetTypeID(productName) == CFStringGetTypeID()) {
            char name[256];
            CFStringGetCString(productName, name, sizeof(name), kCFStringEncodingUTF8);
            printf("\tProduct Name: %s\n", name);
         } else {
            printf("\tProduct Name: Unknown\n");
         }
      }
      
      free(deviceArray);
      CFRelease(deviceSet);
   }
   
   CFRelease(vendorIDRef);
   CFRelease(matchingDict);
   CFRelease(hidManager);
   return anzahl;
}


int findHIDDevicesWithVendorAndProductID(uint32_t vendorID , uint32_t productID) 
{
    // Create a matching dictionary for HID devices
   int anzahl = 0;
    CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOHIDDeviceKey);
    if (!matchingDict) {
        fprintf(stderr, "Failed to create matching dictionary.\n");
        return -1;
    }

    // Add VendorID to the dictionary
    CFNumberRef vendorIDRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vendorID);
    CFDictionarySetValue(matchingDict, CFSTR(kIOHIDVendorIDKey), vendorIDRef);
    CFRelease(vendorIDRef);

    // Add ProductID to the dictionary
    CFNumberRef productIDRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &productID);
    CFDictionarySetValue(matchingDict, CFSTR(kIOHIDProductIDKey), productIDRef);
    CFRelease(productIDRef);

    // Get a list of devices that match the criteria
    io_iterator_t iterator;
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator);

    if (result != KERN_SUCCESS) {
        fprintf(stderr, "Failed to get matching services: %x\n", result);
        return -1;
    }

    // Iterate through matching devices
    io_object_t device;
   
    while ((device = IOIteratorNext(iterator))) {
        // Fetch device properties
        CFStringRef productName = IORegistryEntryCreateCFProperty(device, CFSTR(kIOHIDProductKey), kCFAllocatorDefault, 0);
        if (productName) 
        {
           anzahl++;
            char name[256];
            CFStringGetCString(productName, name, sizeof(name), kCFStringEncodingUTF8);
            printf("findHIDDevicesWithVendorAndProductID Found Device: %s\n", name);
            CFRelease(productName);
        }

        // Release the device
        IOObjectRelease(device);
    }

    // Release the iterator
    IOObjectRelease(iterator);
   return anzahl;
}

int findHIDDeviceWithVendorID(uint32_t vendorID) 
{
   int productID = 0;
    // Create a HID device manager
    IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (!manager) 
    {
        fprintf(stderr, "Failed to create HID Manager\n");
        return -1;
    }

    // Create a matching dictionary for devices with the given vendor ID
    CFMutableDictionaryRef matchingDict = CFDictionaryCreateMutable(
        kCFAllocatorDefault,
        0,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks
    );

    if (!matchingDict) {
        fprintf(stderr, "Failed to create matching dictionary\n");
        CFRelease(manager);
        return -1;
    }

    // Add the vendor ID to the matching dictionary
    CFNumberRef vendorIDRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vendorID);
    CFDictionarySetValue(matchingDict, CFSTR(kIOHIDVendorIDKey), vendorIDRef);
    CFRelease(vendorIDRef);

    // Set the HID Manager to search with the matching dictionary
    IOHIDManagerSetDeviceMatching(manager, matchingDict);
    CFRelease(matchingDict);

    // Copy all matching devices
    CFSetRef deviceSet = IOHIDManagerCopyDevices(manager);
    if (!deviceSet) {
        fprintf(stderr, "No devices found for vendor ID: %u\n", vendorID);
        CFRelease(manager);
        return -1;
    }

    // Iterate through the matching devices
    CFIndex deviceCount = CFSetGetCount(deviceSet);
    if (deviceCount == 0) {
        fprintf(stderr, "No devices found for vendor ID: %u\n", vendorID);
        CFRelease(deviceSet);
        CFRelease(manager);
        return -1;
    }

    printf("Devices found for vendor ID: %u\n", vendorID);
  
    IOHIDDeviceRef *devices = (IOHIDDeviceRef *)malloc(deviceCount * sizeof(IOHIDDeviceRef));
    CFSetGetValues(deviceSet, (const void **)devices);
   int anzahl = 0;
    for (CFIndex i = 0; i < deviceCount; i++) {
        IOHIDDeviceRef device = devices[i];
       anzahl++;
        // Get the product ID
        CFTypeRef productIDRef = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey));
        if (productIDRef && CFGetTypeID(productIDRef) == CFNumberGetTypeID()) {
            
            CFNumberGetValue((CFNumberRef)productIDRef, kCFNumberIntType, &productID);
            printf("Device %ld: Product ID = %d\n", i + 1, productID);
        } 
        else 
        {
            printf("Device %ld: Product ID not available\n", i + 1);
        }
    }

    free(devices);
    CFRelease(deviceSet);
    CFRelease(manager);
   return productID;
}

// Callback function when a matching device is detected
void deviceAddedCallback(void *refCon, io_iterator_t iterator) 
{
    io_service_t device;
    while ((device = IOIteratorNext(iterator))) {
        printf("USB HID device inserted.\n");

        // Fetch vendor and product IDs as an example
        CFNumberRef vendorIDRef = (CFNumberRef)IORegistryEntryCreateCFProperty(device, CFSTR(kIOHIDVendorIDKey), kCFAllocatorDefault, 0);
        CFNumberRef productIDRef = (CFNumberRef)IORegistryEntryCreateCFProperty(device, CFSTR(kIOHIDProductIDKey), kCFAllocatorDefault, 0);

        if (vendorIDRef && productIDRef) {
            int vendorID, productID;
            CFNumberGetValue(vendorIDRef, kCFNumberIntType, &vendorID);
            CFNumberGetValue(productIDRef, kCFNumberIntType, &productID);

            printf("Detected device: Vendor ID = 0x%04x, Product ID = 0x%04x\n", vendorID, productID);
        }

        if (vendorIDRef) CFRelease(vendorIDRef);
        if (productIDRef) CFRelease(productIDRef);

        // Release the device object
        IOObjectRelease(device);
    }
   
}



int usb_present(void)
{
   printf("hid usb_present\n");
   int vid = 0x16C0;
   int pid = 0x486;
   return findHIDDevicesWithVendorID(vid);
   //return findHIDDevicesWithVendorAndProductID(vid,pid);
   
   CFMutableDictionaryRef matchingDict;
   io_iterator_t iter;
   kern_return_t kr;
   io_service_t device;
   int anzahl=0;
   
   // set up a matching dictionary for the class 
   matchingDict = IOServiceMatching("IOUSBDevice");
   if (matchingDict == NULL)
   {
      fprintf(stderr, "Unable to create matching dictionary\n");
      return -1; // fail
   }
   
   
   
   // Now we have a dictionary, get an iterator.
   kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iter);
   if (kr != KERN_SUCCESS)
   {
      fprintf(stderr, "IOServiceGetMatchingServices failed\n");
      return -1;
   }
    // iterate 

   while ((device = IOIteratorNext(iter)))
   {
      // Start VID
      CFNumberRef cfVid = (CFNumberRef)IORegistryEntryCreateCFProperty(device, CFSTR(kIOHIDVendorIDKey), kCFAllocatorDefault, 0);
      
      if (cfVid) 
      {
         int deviceVID;
           CFNumberGetValue(cfVid, kCFNumberIntType, &deviceVID);
           CFRelease(cfVid);

           // Compare with the desired PID
           if (deviceVID == vid) 
           {
               // Get the product name
               CFStringRef cfProductName = (CFStringRef)IORegistryEntryCreateCFProperty(device, CFSTR(kIOHIDProductKey), kCFAllocatorDefault, 0);
               char productName[256];
               if (cfProductName) {
                   CFStringGetCString(cfProductName, productName, sizeof(productName), kCFStringEncodingUTF8);
                   CFRelease(cfProductName);
               } else {
                   snprintf(productName, sizeof(productName), "Unknown");
               }

               printf("hid usb_present Found device: PID=0x%04x, Product=%s\n", deviceVID, productName);
           }
       }
      
      
      // end VID
      
      //start PID
      CFNumberRef cfPid = (CFNumberRef)IORegistryEntryCreateCFProperty(device, CFSTR(kIOHIDProductIDKey), kCFAllocatorDefault, 0);
      
      if (cfPid) 
      {
           int devicePID;
           CFNumberGetValue(cfPid, kCFNumberIntType, &devicePID);
           CFRelease(cfPid);

           // Compare with the desired PID
           if (devicePID == pid) {
               // Get the product name
               CFStringRef cfProductName = (CFStringRef)IORegistryEntryCreateCFProperty(device, CFSTR(kIOHIDProductKey), kCFAllocatorDefault, 0);
               char productName[256];
               if (cfProductName) {
                   CFStringGetCString(cfProductName, productName, sizeof(productName), kCFStringEncodingUTF8);
                   CFRelease(cfProductName);
               } else {
                   snprintf(productName, sizeof(productName), "Unknown");
               }

               printf("Found device: PID=0x%04x, Product=%s\n", devicePID, productName);
           }
       }
      
      
      
      // end PID
      //printf("\n--- Device Found ---\n");
      
      // Retrieve the property dictionary for each device
      CFDictionaryRef properties = NULL;
      kr = IORegistryEntryCreateCFProperties(device, (CFMutableDictionaryRef *)&properties, kCFAllocatorDefault, 0);
      if (kr == KERN_SUCCESS && properties) 
      {
         // Print each property key-value pair
         CFIndex count = CFDictionaryGetCount(properties);
         const void* keys[count];
         const void* values[count];
         CFDictionaryGetKeysAndValues(properties, keys, values);
         
         //printf("Device Properties:\n");
         for (CFIndex i = 0; i < count; i++) 
         {
            CFStringRef key = (CFStringRef)keys[i];
            CFTypeRef value = values[i];
            CFStringRef description = CFCopyDescription(values[i]);
            char descString[256];
            CFStringGetCString(description, descString, sizeof(descString), kCFStringEncodingUTF8);
            
            // Print the key as a string
            char keyName[256];
            if (CFStringGetCString(key, keyName, sizeof(keyName), kCFStringEncodingUTF8))
            {
               printf("keyName  %s: description: %s\n", keyName,descString);
            }
             CFStringRef teensystring = CFSTR("Teensyduino");
            
            if(strcmp(keyName,"kUSBVendorString") == 0)
            {
              // printf("gefunden: %s value:\t",keyName);
               //printCFType(value);
               // CFStringGetCString(description, k, 256, kCFStringEncodingUTF8);
               
               CFRange r = containsSubstring(description, teensystring);
               if (r.length != 0)
               {
                  printf("teensy gefunden \n");
                  anzahl++;
               }
               
            }
         }
      }
      CFRelease(properties);
      IOObjectRelease(device);
   }
   
   // Done, release the iterator 
   IOObjectRelease(iter);
   return anzahl;
}


