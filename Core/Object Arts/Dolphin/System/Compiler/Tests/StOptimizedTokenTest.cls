﻿"Filed out from Dolphin Smalltalk 7"!

StTokenTest subclass: #StOptimizedTokenTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
StOptimizedTokenTest guid: (GUID fromString: '{9b15fc9c-7c2c-41cb-b2b9-7a8e037ee1be}')!
StOptimizedTokenTest comment: ''!
!StOptimizedTokenTest categoriesForClass!Unclassified! !
!StOptimizedTokenTest methodsFor!

subjectClass
	^StOptimizedToken!

testInstanceCreation
	| token token2 originalMethod testMethod |
	token := self subjectClass
				start: 1
				comments: nil
				stop: 3.
	self assert: token isOptimized.
	self assert: token start equals: 1.
	self assert: token stop equals: 3.
	self assertIsNil: token comments.
	"Now test that the Smalltalk backup code works without primitive: 157"
	originalMethod := self subjectClass class compiledMethodAt: #start:comments:stop:.
	testMethod := originalMethod copy.
	"Sanity check"
	self deny: testMethod == originalMethod.
	testMethod extraIndex: 0.
	"Invoke the method directly so we don't need to install it."
	token2 := testMethod value: self subjectClass withArguments: #(20 nil 22).
	self assert: token2 start equals: 20.
	self assert: token2 stop equals: 22.
	self assert: token2 comments equals: nil! !
!StOptimizedTokenTest categoriesFor: #subjectClass!constants!private! !
!StOptimizedTokenTest categoriesFor: #testInstanceCreation!public!unit tests! !

