﻿"Filed out from Dolphin Smalltalk 7"!

Core.Object subclass: #'Kernel.Compiler'
	instanceVariableNames: ''
	classVariableNames: 'DefaultFlags DisabledWarnings'
	imports: #(#{Kernel.CompilerFlags} #{Kernel.ParseErrorCodes})
	classInstanceVariableNames: ''
	classConstants: {}!
Kernel.Compiler guid: (Core.GUID fromString: '{87b4c470-026e-11d3-9fd7-00a0cc3e4a32}')!
Kernel.Compiler comment: 'The Compiler class is responsible for compiling new methods and evaluating expressions.'!
!Kernel.Compiler categoriesForClass!System-Compiler! !
!Kernel.Compiler class methodsFor!

compile: aString in: aClass 
	"Compile the String conversion of the argument code as a method of aClass.
	Answer the new method (which is not added to the method dictionary of
	aClass) if there are no syntax errors, otherwise signal a CompilerNotification."

	^(self 
		compile: aString
		in: aClass
		flags: aClass defaultCompilationFlags) method!

compile: aString in: aClass flags: anInteger
	"Private - Compiler the method source, aString, in the context of the class, aClass,
	parameterized by the flags, anInteger, notifying, notifier, of any errors or warnings 
	which are detected. The flags can be combinations of the following:

	0	Default compilation to code. Method is first element of array
		if successful. If some syntax error occurs, then it will be nil.
	1	Reserved.
	2	Syntax Check only.
	4	Reserved.
	8	Turn off optimization
	16	Generate a textmap from ip to a text range as the third element of
		the array. The text map is an Array of Integers.
		Every three elements define one map. The first element in a map is the
		ip of the bytecode (1 based), and the two following elements define
		the start and stop of the text range (1 based) associated with the
		action of the bytecode.	
	32	Generate a temporaries map as the fourth element of the array
		The temporaries map is itself an Array. Every two elements of the 
		array refer to one mapping. A mapping has two elements, an ip and a
		String of temporaries that are valid at the ip. A mapping occurs for
		every time the temporaries list changes in the method. So the start of
		a Block with at least one argument will have an entry, the ending of
		it will also have an entry. Temporaries generated by the optimizer that
		may be ignore have an underscore as their first character. Optimizer
		temporaries are ignore when deciding that the temporaries list has
		changed. Mappings are not necessarily ordered by their ip. Two mappings
		may have the same ip in this case of an optimized empty block.
	64	Generate a debug version of the method which includes break points after
		every expression. Any text/temporaries map generated at the same time will
		account for the extra byte codes in the IP offsets.
	512	Interactive compile (compiler can prompt to define globals etc)
	1024	SendYourself. Don't optimize out #yourself
	"

	| results |
	results := CompilerLibrary default
				compile: self
				source: aString asUtf8String
				in: aClass
				flags: anInteger
				notifying: self.
	^CompilationResult
		method: results first
		rawTextMap: results second
		rawTempsMap: results third!

compileDebugExpression: aString in: aClass evaluationPools: anArray
	"Compile the source text, aString, as if it were method of aClass inserting additional
	breakpoint bytecodes, etc, to make a debuggable method."

	^(self
		compileForEvaluation: aString
		in: aClass
		evaluationPools: anArray
		flags: DebugMethod) method!

compileDebugMethod: aString in: aClass 
	"Compile the source text, aString, as if it were method of aClass inserting additional
	breakpoint bytecodes, etc, to make a debuggable method."

	^(self 
		compile: aString
		in: aClass
		flags: aClass defaultCompilationFlags | DebugMethod) method!

compileExpression: aString in: aBehaviorOrNil
	^self
		compileExpression: aString
		in: aBehaviorOrNil
		flags: aBehaviorOrNil defaultCompilationFlags!

compileExpression: aString in: aBehaviorOrNil flags: anInteger
	^self
		compileForEvaluation: aString
		in: aBehaviorOrNil
		evaluationPools: nil
		flags: anInteger!

compileForEvaluation: aString in: aBehaviorOrNil evaluationPools: anArray flags: anInteger
	"Private - Compile the expression source, aString, in the context of the class, aBehavior,
	parameterized by the flags, anInteger, notifying, notifier, of any errors or warnings 
	which are detected. Additional shared variables are looked up in the <Array> of <PoolDictionary>,
	anArray. Answers an appropriately instantiated CompilationResult.

	The flags can be combinations of the following:

	0	Default compilation to code. Method is first element of array
		if successful. If some syntax error occurs, then it will be nil.
	1	Reserved.
	2	Syntax Check only. Does not generate a method.
	4	Reserved
	8	Turn off optimization
	16	Generate a textmap from ip to a text range as the third element of
		the array. The text map is an Array of Integers.
		Every three elements define one map. The first element in a map is the
		ip of the bytecode (1 based), and the two following elements define
		the start and stop of the text range (1 based) associated with the
		action of the bytecode.	
	32	Generate a temporaries map as the fourth element of the array
		The temporaries map is itself an Array. Every two elements of the 
		array refer to one mapping. A mapping has two elements, an ip and a
		String of temporaries that are valid at the ip. A mapping occurs for
		every time the temporaries list changes in the method. So the start of
		a Block with at least one argument will have an entry, the ending of
		it will also have an entry. Temporaries generated by the optimizer that
		may be ignore have an underscore as their first character. Optimizer
		temporaries are ignore when deciding that the temporaries list has
		changed. Mappings are not necessarily ordered by their ip. Two mappings
		may have the same ip in this case of an optimized empty block.
	64	Generate a debug version of the method which includes break points after
		every expression. Any text/temporaries map generated at the same time will
		account for the extra byte codes in the IP offsets."

	| results expression source |
	source := aString asUtf8String.
	results := CompilerLibrary default
				compileForEvaluation: self
				source: source
				in: aBehaviorOrNil
				evaluationPools: anArray
				flags: anInteger
				notifying: self.
	expression := results first.
	results := CompilationResult
				method: expression
				rawTextMap: results second
				rawTempsMap: results third.
	expression notNil
		ifTrue: 
			[aBehaviorOrNil ifNotNil: [expression methodClass: aBehaviorOrNil].
			expression
				storeSourceString: source evaluationPools: anArray;
				isImmutable: true].
	^results!

compilerNotification: aCompilerNotification 
	"Private - Inform user of Compiler error/warning as detailed in the 
	<CompilerNotification> argument."

	^aCompilerNotification signal!

debugInfoFlags: aBoolean 
	^TextMap | TempsMap | (aBoolean ifTrue: [DebugMethod] ifFalse: [0])!

debugInfoFor: aString in: aClass debug: aBoolean 
	"Answers a CompilationResult with all the information necessary for debugging a method
	in aClass whose sources is aString."

	^self 
		compile: aString
		in: aClass
		flags: aClass defaultCompilationFlags | (self debugInfoFlags: aBoolean)!

debugInfoForExpression: aString in: aBehaviorOrNil evaluationPools: pools debug: aBoolean
	"Answers a CompilationResult with all the information necessary for debugging a method
	in aClass whose sources is aString."

	^self
		compileForEvaluation: aString
		in: aBehaviorOrNil
		evaluationPools: pools
		flags: (self debugInfoFlags: aBoolean)!

defaultFlags
	^DefaultFlags!

defaultFlags: anInteger 
	DefaultFlags := anInteger!

disableWarning: anInteger 
	"Disable the compiler warning with the specified code."

	DisabledWarnings add: anInteger!

enableWarning: anInteger 
	"Enable the compiler warning with the specified code."

	DisabledWarnings remove: anInteger ifAbsent: []!

errorClass
	^CompilerErrorNotification!

evaluate: aString
	"Compile and evaluate the expression, aString, in the context of
	UndefinedObject.  If the expression compiles, answer the result of 
	evaluating the expression with nil as the receiver.
	If the compilation fails, signal a CompilerNotification and answer nil. 
	The expression is not written to the change log."

	^self
		evaluate: aString
		for: nil!

evaluate: aString for: anObject
	"Compile and evaluate the expression, aString, with anObject as the receiver. If the
	expression compiles, answer the result of evaluating the expression. If the compilation
	fails, signal a CompilerNotification and answer nil."

	^self
		evaluate: aString
		for: anObject
		evaluationPools: nil!

evaluate: aString for: anObject evaluationPools: anArray
	^self
		evaluate: aString
		for: anObject
		evaluationPools: anArray
		logged: false!

evaluate: aString for: anObject evaluationPools: anArray logged: aBoolean 
	"Compile and evaluate the expression, aString, with anObject as the 
	receiver.  If the expression compiles, answer the result of evaluating 
	the expression. If the compilation fails, signal a CompilerNotification
	and answer nil. Log the expression to the change log as requested by 
	the argument aBoolean."

	^self 
		evaluate: aString
		for: anObject
		evaluationPools: anArray
		logged: aBoolean
		ifFail: []!

evaluate: aString for: anObject evaluationPools: anArray logged: aBoolean ifFail: failBlock
	"Compile and evaluate the expression, aString, with anObject as the 
	receiver.  If the expression compiles, answer the result of evaluating 
	the expression. If the compilation fails, signal a CompilerNotification
	and answer nil. Log the expression to the change log as requested by 
	the argument aBoolean."

	^(self
		compileForEvaluation: aString
		in: (anObject ifNotNil: [anObject class])
		evaluationPools: anArray
		flags: 0) method
		ifNotNil: 
			[:expr |
			aBoolean ifTrue: [self sourceManager logEvaluate: aString].
			expr value: anObject withArguments: #()]
		ifNil: [failBlock value]!

evaluate: aString for: anObject logged: aBoolean
	"Compile and evaluate the expression, aString, with anObject as the 
	receiver.  If the expression compiles, answer the result of evaluating 
	the expression. If the compilation fails, signal a CompilerNotification
	 and answer nil. Log the expression to the change log as requested by 
	the argument aBoolean."

	^self evaluate: aString for: anObject evaluationPools: nil logged: aBoolean!

evaluate: aString logged: aBoolean
	"Compile and evaluate the expression, aString, in the context of
	UndefinedObject, with nil as the receiver.  If the expression compiles,
	answer the result of evaluating the expression with nil as the receiver.
	If the compilation fails, signal a CompilerNotification and answer nil. 
	Log the expression to the change log as requested by the argument aBoolean."

	^self evaluate: aString for: nil logged: aBoolean!

identifierFrom: aString
	"Answer a String which is an initial suggestion for a Smalltalk identifier based on aString.
	The answer is not guaranteed to be a valid identifier as it could be an empty String.

	Invalid characters are removed, the letter following a removed character is made uppercase
	unless it forms the first character of the identifier when it is made lowercase, all other
	letters are made lowercase."

	| identifier startNewWord first |
	identifier := String smalltalkWriteStream: aString size.
	startNewWord := false.
	first := true.
	aString do: 
			[:c |
			((first and: [self isAValidInitialIdentifierChar: c]) or: [self isAValidIdentifierChar: c])
				ifFalse: [startNewWord := first not]
				ifTrue: 
					[identifier nextPut: (startNewWord ifTrue: [c asUppercase] ifFalse: [c asLowercase]).
					startNewWord := false.
					first := false]].
	^identifier contents!

initialize
	"Private - Initialize the class variables of the receiver.

		Compiler initialize
	"

	DefaultFlags := 0.
	DisabledWarnings := Set new!

isAReservedWord: aString
	"Private - Answer whether aString is a reserved word."

	^self reservedWords includes: aString!

isAValidIdentifierChar: aCharacter
	"Private - Answer whether aCharacter is valid as the non-initial character in an identifier."

	^CRTLibrary default __iscsym: aCharacter!

isAValidInitialIdentifierChar: aCharacter
	"Private - Answer whether aCharacter is valid as the first character in an identifier."

	^CRTLibrary default __iscsymf: aCharacter!

isAValidLocalIdentifier: aString
	"Private - Answer whether aString is a valid local identifier."

	^(aString allSatisfy: [:c | self isAValidIdentifierChar: c]) and: [
		(self isAValidInitialIdentifierChar: aString first) and: [
			(self isAReservedWord: aString) not]]!

isValidSelector: aSymbol
	"Answer whether the <Symbol> argument is a valid selector (unary, binary or keyword)."

	^(Symbol isLiteralSymbol: aSymbol) and: [(self isAReservedWord: aSymbol asString) not]!

isWarningDisabled: anInteger 
	^anInteger >= CWarnFirst and: [DisabledWarnings includes: anInteger]!

notificationCallback: anArray 
	"Private - The receiver has generated an error while compiling, inform notifier of this.
	N.B. This is a callback from the Compiler, and should not be removed."

	"Array layout:
		1) <integer> Error code
		2) <integer> Line number
		3) <integer> Start of erroneous interval
		4) <integer> End of erroneous interval
		5) <integer> Offset of the start of the source code in the original source (0 unless compiling a static expression)
		6) <String> Source code
		7) <string> selector
		8) <behavior> Class in the context of which the compilation is taking place.
		9) The object to be notified.
		10) <Array> of <Object> representing extra information about the error."

	| errorCode offset sourceText lineNumber errorStart errorStop selector methodClass extras notified |
	errorCode := anArray first.
	(self isWarningDisabled: errorCode) ifTrue: [^true].
	lineNumber := anArray at: 2.
	errorStart := anArray at: 3.
	errorStop := anArray at: 4.
	"The offset must be added to the error range to get the actual interval in the source text"
	offset := anArray at: 5.
	sourceText := anArray at: 6.
	selector := anArray at: 7.
	methodClass := anArray at: 8.
	notified := anArray at: 9.
	extras := anArray at: 10 ifAbsent: [#()].
	^notified compilerNotification: ((self notificationClass 
				code: errorCode
				in: sourceText
				for: methodClass
				selector: selector
				position: errorStart + 1
				line: lineNumber
				range: (errorStart to: errorStop) + 1
				extras: extras)
				offset: offset;
				yourself)!

notificationClass
	^CompilerNotification!

reservedWords
	"Private - Answer the Set of reserved words."

	^##(Set withAll: #('self' 'super' 'nil' 'true' 'false' 'thisContext'))!

temporariesMapOf: aString in: aClass 
	"Answers a temporariesMap Array for aString when compiled
	as a method to be installed in aClass. The method is not installed
	into aClass or logged to the change log"

	^(self 
		compile: aString
		in: aClass
		flags: aClass defaultCompilationFlags | TempsMap) tempsMap!

textMapOf: aString in: aClass 
	"Answers a textMap Array for aString when compiled
	as a method to be installed in aClass. The method is not installed
	into aClass or logged to the change log"

	^(self 
		compile: aString
		in: aClass
		flags: aClass defaultCompilationFlags | TextMap) textMap!

uninitialize
	"Clean up VM references that are only required if the compiler is present."

	"Uses:
		notificationCallback:		Sent with compilation errors/warnings
		allInstVarNames			To query class metadata
		evaluate:for:evaluationPools:	To evaluate ##(...) expressions
		bindingFor:				To lookup variables in the evaluation pools.
		fullBindingFor:				Sent to  a namespace to resolve stative variables
		asNumber				Sent to parse numeric literals
		understandsArithmetic		Sent to verify the type of literals when parsing some messages with inline forms, e.g. #to:by:do:
		negative					Similarly to above, but to check for negative 'step'
		#pathString:context:meta:	Sent to instantiate BindingReference objects for literal binding references"

	#(#notificationCallback: #allInstVarNames #evaluate:for:evaluationPools: #bindingFor: #fullBindingFor: #asNumber #understandsArithmetic #negative #pathString:context:flags:)
		, {BindingReference. Smalltalk} do: [:each | VMLibrary default unregisterObject: each].
	CompilerLibrary closeDefault!

warningClass
	^CompilerWarningNotification! !
!Kernel.Compiler class categoriesFor: #compile:in:!compiling!public! !
!Kernel.Compiler class categoriesFor: #compile:in:flags:!compiling!private! !
!Kernel.Compiler class categoriesFor: #compileDebugExpression:in:evaluationPools:!compiling!public! !
!Kernel.Compiler class categoriesFor: #compileDebugMethod:in:!compiling!public! !
!Kernel.Compiler class categoriesFor: #compileExpression:in:!compiling!public! !
!Kernel.Compiler class categoriesFor: #compileExpression:in:flags:!compiling!public! !
!Kernel.Compiler class categoriesFor: #compileForEvaluation:in:evaluationPools:flags:!compiling!private! !
!Kernel.Compiler class categoriesFor: #compilerNotification:!exceptions!private! !
!Kernel.Compiler class categoriesFor: #debugInfoFlags:!development!public! !
!Kernel.Compiler class categoriesFor: #debugInfoFor:in:debug:!development!public! !
!Kernel.Compiler class categoriesFor: #debugInfoForExpression:in:evaluationPools:debug:!development!public! !
!Kernel.Compiler class categoriesFor: #defaultFlags!constants!public! !
!Kernel.Compiler class categoriesFor: #defaultFlags:!accessing!public! !
!Kernel.Compiler class categoriesFor: #disableWarning:!helpers!public! !
!Kernel.Compiler class categoriesFor: #enableWarning:!helpers!public! !
!Kernel.Compiler class categoriesFor: #errorClass!public! !
!Kernel.Compiler class categoriesFor: #evaluate:!evaluating!public! !
!Kernel.Compiler class categoriesFor: #evaluate:for:!evaluating!public! !
!Kernel.Compiler class categoriesFor: #evaluate:for:evaluationPools:!evaluating!public! !
!Kernel.Compiler class categoriesFor: #evaluate:for:evaluationPools:logged:!evaluating!public! !
!Kernel.Compiler class categoriesFor: #evaluate:for:evaluationPools:logged:ifFail:!evaluating!public! !
!Kernel.Compiler class categoriesFor: #evaluate:for:logged:!evaluating!public! !
!Kernel.Compiler class categoriesFor: #evaluate:logged:!evaluating!public! !
!Kernel.Compiler class categoriesFor: #identifierFrom:!parsing!public! !
!Kernel.Compiler class categoriesFor: #initialize!development!initializing!private! !
!Kernel.Compiler class categoriesFor: #isAReservedWord:!parsing!private! !
!Kernel.Compiler class categoriesFor: #isAValidIdentifierChar:!parsing!private! !
!Kernel.Compiler class categoriesFor: #isAValidInitialIdentifierChar:!parsing!private! !
!Kernel.Compiler class categoriesFor: #isAValidLocalIdentifier:!parsing!private! !
!Kernel.Compiler class categoriesFor: #isValidSelector:!public!testing! !
!Kernel.Compiler class categoriesFor: #isWarningDisabled:!exceptions!private! !
!Kernel.Compiler class categoriesFor: #notificationCallback:!exceptions!private! !
!Kernel.Compiler class categoriesFor: #notificationClass!public! !
!Kernel.Compiler class categoriesFor: #reservedWords!constants!private! !
!Kernel.Compiler class categoriesFor: #temporariesMapOf:in:!development!public! !
!Kernel.Compiler class categoriesFor: #textMapOf:in:!development!public! !
!Kernel.Compiler class categoriesFor: #uninitialize!class hierarchy-removing!public! !
!Kernel.Compiler class categoriesFor: #warningClass!public! !
