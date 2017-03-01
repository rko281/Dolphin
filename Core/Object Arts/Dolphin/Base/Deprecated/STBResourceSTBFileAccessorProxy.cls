"Filed out from Dolphin Smalltalk X6"!

STBProxy subclass: #STBResourceSTBFileAccessorProxy
	instanceVariableNames: 'fileName bytes'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
STBResourceSTBFileAccessorProxy guid: (GUID fromString: '{87B4C6F1-026E-11D3-9FD7-00A0CC3E4A32}')!
STBResourceSTBFileAccessorProxy comment: ''!
!STBResourceSTBFileAccessorProxy categoriesForClass!System-Binary storage! !
!STBResourceSTBFileAccessorProxy methodsFor!

bytes: aByteArray
	"Private - Set the receiver's bytes inst var to a ByteArray."

	bytes := aByteArray!

fileName: aString
	"Private - Set the receiver's fileName inst var to aString."

	fileName := aString!

stbFixup: inFiler at: anInteger 
	"Answer the object that this one represents.
	If the receiver's bytes inst var is non-nil then we create a new file containing
	this data - the contents of the original ResourceSTBFileAccesor file. Also,
	we propagate the codebase of the loading STBInFiler into the reconstituted
	accessor so that it can resolve any remote class references within its
	resource STB data."

	| accessor classLocator |
	bytes notNil 
		ifTrue: 
			[| stream |
			stream := FileStream write: fileName text: false.
			[stream nextPutAll: bytes] ensure: [stream close]].
	classLocator := inFiler classLocator copyWithCodeBase.
	(accessor := ResourceSTBFileAccessor onFileName: fileName) classLocator: classLocator.
	self become: accessor! !
!STBResourceSTBFileAccessorProxy categoriesFor: #bytes:!accessing!private! !
!STBResourceSTBFileAccessorProxy categoriesFor: #fileName:!accessing!private! !
!STBResourceSTBFileAccessorProxy categoriesFor: #stbFixup:at:!converting!public! !

!STBResourceSTBFileAccessorProxy class methodsFor!

withEmbeddedFile: aResourceSTBFileAccessor
	"Answer a new instance of the receiver with the contents of aResourceSTBFileAccessor's file
	embedded in its bytes inst var."

	^self basicNew
		fileName: aResourceSTBFileAccessor fileName;
		bytes: aResourceSTBFileAccessor byteArray;
		yourself!

withExternalFile: aResourceSTBFileAccessor
	"Answer a new instance of the receiver containing the aResourceSTBFileAccessor's file
	name only, leaving its bytes inst var nil."

	^self basicNew
		fileName: aResourceSTBFileAccessor fileName;
		yourself! !
!STBResourceSTBFileAccessorProxy class categoriesFor: #withEmbeddedFile:!instance creation!public! !
!STBResourceSTBFileAccessorProxy class categoriesFor: #withExternalFile:!instance creation!public! !
