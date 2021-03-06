﻿"Filed out from Dolphin Smalltalk 7"!

Object subclass: #DisplayMonitor
	instanceVariableNames: 'handle info devices'
	classVariableNames: 'MONITOR_DEFAULTTONEAREST MONITOR_DEFAULTTONULL MONITOR_DEFAULTTOPRIMARY'
	poolDictionaries: ''
	classInstanceVariableNames: ''!
DisplayMonitor guid: (GUID fromString: '{2ab65289-2a77-4c76-9ab2-82178699a48c}')!
DisplayMonitor addClassConstant: 'MONITOR_DEFAULTTONEAREST' value: 16r2!
DisplayMonitor addClassConstant: 'MONITOR_DEFAULTTONULL' value: 16r0!
DisplayMonitor addClassConstant: 'MONITOR_DEFAULTTOPRIMARY' value: 16r1!
DisplayMonitor comment: '`DisplayMonitor` is a simple abstraction over the Windows Multiple Display Monitors API. It allows one to enumerate the attached monitors, and to identify:
  - the primary monitor;
  - the monitor on which a point in desktop co-ordinates is displayed; 
  - the monitors that intersect a rectangular region of the desktop, and/or a device context.

Having identified a `DisplayMonitor`, one can then query the desktop co-ordinates of the its display and work areas.

## Instance Variables:
  `handle`		`External.ExternalHandle`. The Windows HMONITOR handle for the monitor.
  `info`		`OS.MONITORINFO`

'!
!DisplayMonitor categoriesForClass!Kernel-Objects! !
!DisplayMonitor methodsFor!

= anObject
	^self == anObject
		or: [anObject species == self species and: [anObject deviceName = self deviceName]]!

deviceName
	"Answer the Window's device name for the monitor that the receiver represents."

	^self info szDevice!

devices
	^devices
		ifNil: 
			[| stream device i |
			stream := Array writeStream: 1.
			i := 0.
			device := DISPLAY_DEVICEW newBuffer.
			
			[UserLibrary default
				enumDisplayDevices: self deviceName
				iDevNum: i
				lpDisplayDevice: device
				dwFlags: 0]
					whileTrue: 
						[stream nextPut: device copy.
						i := i + 1].
			devices := stream grabContents]!

handle
	^handle!

handle: anObject
	handle := anObject!

hash
	^self deviceName hash!

info
	^info
		ifNil: 
			[info := MONITORINFOEXW newBuffer.
			(UserLibrary default getMonitorInfo: handle lpmi: info) ifFalse: [Win32Error signal].
			info]!

isAttachedToDesktop
	"Answer whether the receiver has any displays attached to the desktop."

	^self devices anySatisfy: [:each | each isAttachedToDesktop]!

isPrimary
	"Answer whether the receiver represents the primary/main monitor."

	^self info isPrimary!

origin
	"Answer a `Point` specifying the origin (top-left corner) of the display represented by the object."

	^self rectangle origin!

printOn: aStream
	super printOn: aStream.
	aStream nextPut: $(.
	self isPrimary ifTrue: [aStream nextPutAll: 'primary: '].
	aStream
		print: self deviceName;
		nextPut: $)!

rectangle
	"Answer a `Rectangle` which is the desktop area displayed by this monitor. This is in desktop co-ordinates. Note that the origin can be negative for displays other than the primary that are organised to be right of the primary."

	^self info rcMonitor asRectangle!

workArea
	"Answer a `Rectangle` which is the desktop area displayed by this monitor, excluding any areas used by the window manager, such as the taskbar. Note that the origin can be negative for displays other than the primary that are organised to be right of the primary."

	^self info rcWork asRectangle! !
!DisplayMonitor categoriesFor: #=!comparing!public! !
!DisplayMonitor categoriesFor: #deviceName!accessing!public! !
!DisplayMonitor categoriesFor: #devices!accessing!private! !
!DisplayMonitor categoriesFor: #handle!accessing!private! !
!DisplayMonitor categoriesFor: #handle:!accessing!private! !
!DisplayMonitor categoriesFor: #hash!comparing!public! !
!DisplayMonitor categoriesFor: #info!accessing!private! !
!DisplayMonitor categoriesFor: #isAttachedToDesktop!public!testing! !
!DisplayMonitor categoriesFor: #isPrimary!public!testing! !
!DisplayMonitor categoriesFor: #origin!accessing!public! !
!DisplayMonitor categoriesFor: #printOn:!printing!public! !
!DisplayMonitor categoriesFor: #rectangle!accessing!public! !
!DisplayMonitor categoriesFor: #workArea!accessing!public! !

!DisplayMonitor class methodsFor!

active
	"Answer an instance of the receiver representing the monitor that is most likely to be the one the user might consider active. There is no completely reliable way to determine this, so we use the heuristic that the monitor of the foreground window (whether that is a Dolphin window or not) is likely to be the one with the users' interest.
	An exception is if the 'Progman' window is the foreground window, which will be the case if the user has clicked on the desktop (at least in any version of Windows that is currently relevant)."

	UserLibrary default getForegroundWindow
		ifNotNil: [:hWnd | (DesktopView isProgramManager: hWnd) ifFalse: [^self displayingView: hWnd]].

	"We want to return the display with the mouse cursor if the desktop (really the program manager) has focus, or in the unlikely event that GetForegroundWindow returns null, which according to the docs it can do if activation is in transition."
	^self containingPoint: Cursor position!

allIntersecting: aRectangle
	"Answer a `<collection>` containing instances of the receiver describing all the display monitors with display areas that intersect the specified virtual screen area (i.e. desktop area)."

	^self forCanvas: nil intersecting: aRectangle!

allMonitors
	"Answer a `<collection>` containing instances of the receiver describing all the connected display monitors."

	^self forCanvas: nil intersecting: nil!

containingPoint: aPoint
	"Answer an instance of the receiver describing the monitor on which the specified 'Point' in the screen co-ordinate space would appear. If the View is outside the display area of any of the connected monitors, answer nil.
	Note that there may be areas of the virtual screen area that are not visible, depending on the relative sizes and positioning of the monitors in the Windows display settings, i.e. a Point within the virtual screen area may not actually be displayed on any monitor."

	^(UserLibrary default monitorFromPoint: aPoint asParameter dwFlags: MONITOR_DEFAULTTONULL)
		ifNotNil: [:hMonitor | self fromHandle: hMonitor]!

desktopMonitors
	"Answer a `<collection>` containing instances of the receiver describing all the connected display monitors."

	^self allMonitors select: [:each | each isAttachedToDesktop]!

displayingView: aViewOrHandle
	"Answer an instance of the receiver describing the monitor on which the specified `View`/window is (at least mostly) displayed. Note that for the desktop window, the primary monitor will be returned.
	If the window is outside the visible display area, answer nil."

	^(UserLibrary default monitorFromWindow: aViewOrHandle asParameter dwFlags: MONITOR_DEFAULTTONULL)
		ifNotNil: [:hMonitor | self fromHandle: hMonitor]!

forCanvas: aCanvas intersecting: aRectangle
	"Answer a `<collection>` containing instances of the receiver describing all the display monitors that are displaying the specified virtual screen area (i.e. desktop area) of the specified device context. The rectangle and device context can be nil.
		aCanvas isNil & aRectangle isNil		- matches all display monitors
		aCanvas isNil & aRectangle notNil		- matches all display monitors that intersect the virtual screen area specified by aRectangle
		aCanvas notNil & aRecangle isNil		- matches all display monitors that intersect the visibile region of aCanvas
		aCanvas notNil & aRectangle notNil 	- all display monitors that intersect the visibile region of aCanvas and the virtual screen area specified by aRectangle"

	| monitors |
	monitors := Array writeStream: 1.
	self
		forCanvas: aCanvas
		intersecting: aRectangle
		do: [:each | monitors nextPut: each].
	^monitors grabContents!

forCanvas: aCanvas intersecting: aRectangle do: aMonadicValuable
	| user32 callback answer |
	user32 := UserLibrary default.
	callback := ExternalCallback block: 
					[:hMonitor :hdc :lprect :lparam |
					aMonadicValuable value: (DisplayMonitor fromHandle: hMonitor).
					true]
				descriptor: (ExternalDescriptor returnType: 'bool'
						argumentTypes: 'handle handle RECTL* dword').
	answer := user32
				enumDisplayMonitors: aCanvas asParameter
				lprcClip: aRectangle asParameter
				lpfnEnum: callback asParameter
				dwData: 0.
	callback free.
	^answer!

fromHandle: anExternalHandle
	^self new
		handle: anExternalHandle;
		yourself!

icon
	"Answers an Icon that can be used to represent this class"

	^##(self) defaultIcon!

intersecting: aRectangle
	"Answer an instance of the receiver describing the monitor which has the largest intersection with the specified `Rectangle` of the screen co-ordinate space, or nil if there is no intersection."

	^(UserLibrary default monitorFromRect: aRectangle asParameter dwFlags: MONITOR_DEFAULTTONULL)
		ifNotNil: [:hMonitor | self fromHandle: hMonitor]!

nearestPoint: aPoint
	"Answer an instance of the receiver describing the monitor to which the specified `Point` (expressing a position in the screen co-ordinate space) is nearest."

	^(UserLibrary default monitorFromPoint: aPoint asParameter dwFlags: MONITOR_DEFAULTTONEAREST)
		ifNotNil: [:hMonitor | self fromHandle: hMonitor]
		ifNil: [Win32Error signal]!

nearestView: aView
	"Answer an instance of the receiver describing the monitor on which the specified `View` is either mostly displayed, or, if off-screen, to which it is nearest."

	^(UserLibrary default monitorFromWindow: aView asParameter dwFlags: MONITOR_DEFAULTTONEAREST)
		ifNotNil: [:hMonitor | self fromHandle: hMonitor]
		ifNil: [Win32Error signal]!

primary
	"Answer an instance of the receiver describing the primary display monitor."

	^(UserLibrary default monitorFromWindow: nil dwFlags: MONITOR_DEFAULTTOPRIMARY)
		ifNil: [Win32Error signal]
		ifNotNil: [:hMonitor | self fromHandle: hMonitor]! !
!DisplayMonitor class categoriesFor: #active!instance creation!public! !
!DisplayMonitor class categoriesFor: #allIntersecting:!instance creation!public! !
!DisplayMonitor class categoriesFor: #allMonitors!enumerating!public! !
!DisplayMonitor class categoriesFor: #containingPoint:!instance creation!public! !
!DisplayMonitor class categoriesFor: #desktopMonitors!enumerating!public! !
!DisplayMonitor class categoriesFor: #displayingView:!instance creation!public! !
!DisplayMonitor class categoriesFor: #forCanvas:intersecting:!enumerating!public! !
!DisplayMonitor class categoriesFor: #forCanvas:intersecting:do:!enumerating!private! !
!DisplayMonitor class categoriesFor: #fromHandle:!instance creation!private! !
!DisplayMonitor class categoriesFor: #icon!constants!public! !
!DisplayMonitor class categoriesFor: #intersecting:!instance creation!public! !
!DisplayMonitor class categoriesFor: #nearestPoint:!instance creation!public! !
!DisplayMonitor class categoriesFor: #nearestView:!instance creation!public! !
!DisplayMonitor class categoriesFor: #primary!instance creation!public! !

