-- Copyright (c) 2016 Eric McCorkle.  All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
--
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--
-- 3. Neither the name of the author nor the names of any contributors
--    may be used to endorse or promote products derived from this software
--    without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS''
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
-- PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS
-- OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
-- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
-- LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
-- USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
-- OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.
{-# OPTIONS_GHC -funbox-strict-fields -Wall -Werror #-}
{-# LANGUAGE FlexibleContexts, OverloadedStrings,
             MultiParamTypeClasses #-}

-- | Defines the datatype for Salt compiler messages.  Every message
-- that can possibly be emitted from the Salt compiler will have a
-- definition in this module.  Any time a new message type is added to
-- the compiler, definition for it should be added to this module.
--
-- The 'Message' type is an abstract form of messages that is stored
-- until the message is actually output to the command line.  This
-- facilitates different output formats and also facilitates testing
-- of message output in a robust fashion.
module Language.Salt.Message(
       Message,

       -- ** Internal Compiler Error
       internalError,

       -- ** Lexer Messages
       badChars,
       badEscape,
       newlineCharLiteral,
       tabCharLiteral,
       longCharLiteral,
       emptyCharLiteral,
       untermComment,
       untermString,
       tabInStringLiteral,
       hardTabs,
       trailingWhitespace,
       newlineInString,

       -- ** Parser Messages
       parseError,

       -- ** Collect Messages
       duplicateField,
       duplicateTruth,
       duplicateSyntax,
       duplicateBuilder,
       duplicateName,

       -- ** Resolution Messages
       cyclicDefs,
       illegalAccess,
       outOfContextAccess,
       undefSymbol,

       namelessField,
       noTopLevelDef,
       namelessUninitDef,
       badComponentName,
       importNestedScope,
       expectedFuncType,
       cyclicInherit,
       patternBindMismatch,

       -- ** Precedence Parsing Messages
       cyclicPrecedence,
       precedenceParseError,
       expectedRef,

       -- ** File Access Messages
       cannotFindFile,
       cannotFindComponent,
       cannotAccessFile,
       cannotAccessComponent,
       cannotCreateFile,
       cannotCreateArtifact,

       -- ** Type Check Messages
       missingFields,
       tupleMismatch,

       -- ** Normalization Messages
--       callNonFunc,
--       noMatch,
) where

import Control.Monad.Messages
import Control.Monad.Positions
import Control.Monad.Symbols
import Data.Hashable
import Data.Position.BasicPosition
import Data.Position.DWARFPosition(DWARFPosition, basicPosition)
import Data.PositionElement
import Language.Salt.Surface.Token(Token)
import Language.Salt.Surface.Common
--import Data.Default
import Data.Symbol
import Text.Format
--import Language.Salt.Core.Syntax hiding (Position)

import qualified Data.ByteString as Strict
import qualified Data.ByteString.Lazy as Lazy
import qualified Data.Message as Msg

-- | Data structure containing all data for a particular message.
data Message =
    -- | Bad characters in lexical input.
    BadChars {
      -- | The bad characters from input (error).
      badCharsContent :: !Lazy.ByteString,
      -- | The position of the bad characters.
      badCharsPos :: !Position
    }
    -- | Bad characters in lexical input.
  | BadEscape {
      -- | The bad characters from input (error).
      badEscContent :: !Lazy.ByteString,
      -- | The position of the bad characters.
      badEscPos :: !Position
    }
    -- | An empty character literal.
  | EmptyCharLiteral {
      -- | The position of the bad character literal.
      emptyCharPos :: !Position
    }
    -- | A long character literal (more than one character in the literal).
  | LongCharLiteral {
      -- | The characters from the literal.
      longCharContent :: !Lazy.ByteString,
      -- | The position of the bad character literal.
      longCharPos :: !Position
    }
    -- | A newline in a character literal.
  | NewlineCharLiteral {
      -- | The position of the bad character literal.
      newlineCharPos :: !Position
    }
    -- | A hard tab in a character literal.
  | TabCharLiteral {
      -- | The position of the bad character literal.
      tabCharPos :: !Position
    }
    -- | Unterminated comment (error).
  | UntermComment {
      -- | Position at which the unterminated comment begins.
      untermCommentPos :: !Position
    }
    -- | A hard tab in a string literal.
  | TabStringLiteral {
      -- | The position of the hard tab.
      tabStringPos :: !Position
    }
    -- | Unterminated string literal (error).
  | UntermString {
      -- | Position at which the unterminated string begins.
      untermStringPos :: !Position
    }
    -- | Hard tabs in input (remark).
  | HardTabs {
      -- | The position of the hard tab.
      hardTabsPos :: !Position
    }
    -- | Trailing whitespace.
  | TrailingWhitespace {
      -- | The position of the trailing whitespace.
      trailingWhitespacePos :: !Position
    }
    -- | Newline in a string constant.
  | NewlineInString {
      -- | The position of the newline in the string.
      newlineInStringPos :: !Position
    }
    -- | Parse error.
  | ParseError {
      -- | The position of the parse error.
      parseErrorToken :: !Token
    }
    -- | Missing expected module definition.
  | NoTopLevelDef {
      -- | The expected top level definition name.
      noTopLevelDefName :: !Strict.ByteString,
      -- | The position of the component in which the definition was
      -- supposed to occur.
      noTopLevelDefPos :: !Position
    }
    -- | Duplicate record field binding.
  | DuplicateField {
      -- | The name of the duplicate field.
      duplicateFieldName :: !Strict.ByteString,
      -- | The positions at which each field definition occurs.
      duplicateFieldPosList :: ![Position]
    }
  | NamelessField {
      namelessFieldPos :: !Position
    }
    -- | Duplicate truth definition in the current environment.
  | DuplicateTruth {
      -- | The name of the duplicate truth.
      duplicateTruthName :: !Strict.ByteString,
      -- | The positions at which each truth definition occurs.
      duplicateTruthPosList :: ![Position]
    }
    -- | Reference to undefined symbol
  | UndefSymbol {
      undefSymbolSym :: !Strict.ByteString,
      undefSymbolPos :: ![Position]
    }
    -- | An uninitialized definition with no top-level name.
  | NamelessUninitDef {
      namelessUninitDefPos :: !Position
    }
    -- | Duplicate builder definition in the current environment.
  | DuplicateBuilder {
      -- | The name of the duplicate builder definition.
      duplicateBuilderName :: !Strict.ByteString,
      -- | The positions at which each builder definition occurs.
      duplicateBuilderPosList :: ![Position]
    }
    -- | Duplicate builder definition in the current environment.
  | DuplicateSyntax {
      -- | The name of the duplicate syntax definition.
      duplicateSyntaxName :: !Strict.ByteString,
      -- | The positions at which each syntax definition occurs.
      duplicateSyntaxPosList :: ![Position]
    }
    -- | Cannot find a file or a component
  | CannotFind {
      -- | The name of the file or component being accessed.
      cannotFindName :: !Strict.ByteString,
      -- | Whether the name is a raw file name or a component name.
      cannotFindIsFileName :: !Bool,
      -- | The position at which the file or component was referenced.
      cannotFindPos :: !Position
    }
    -- | Error accessing a file or component.
  | CannotAccess {
      -- | The name of the file or component being accessed.
      cannotAccessName :: !(Maybe Strict.ByteString),
      -- | Whether the name is a raw file name or a component name.
      cannotAccessFileName :: !Strict.ByteString,
      -- | Error message given by the operating system.
      cannotAccessMsg :: !Strict.ByteString,
      -- | The position at which the file or component was referenced.
      cannotAccessPos :: !Position
    }
    -- | A component does not have the name expected for its filename.
  | BadComponentName {
      -- | The expected name.
      badComponentNameExpected :: !Strict.ByteString,
      -- | Possibly the actual component name.
      badComponentNameActual :: !(Maybe Strict.ByteString),
      -- | The position of the component statement.
      badComponentNamePos :: !Position
    }
    -- | Error creating an artifact.
  | CannotCreate {
      -- | The name of the file or component being accessed.
      cannotCreateName :: !(Maybe Strict.ByteString),
      -- | Whether the name is a raw file name or a component name.
      cannotCreateFileName :: !Strict.ByteString,
      -- | Error message given by the operating system.
      cannotCreateMsg :: !Strict.ByteString
    }
    -- | Attempting to import a nested scope.
  | ImportNestedScope {
      importNestedScopePos :: !Position
    }
    -- | Internal error arising from an unexpected constructor for a static expr
    -- ession.
  | InternalError {
      internalErrorStr :: !Strict.ByteString,
      internalErrorPos :: ![Position]
    }
  | CallNonFunc {
      callNonFuncTerm :: !Doc,
      callNonFuncPos :: !Position
    }
  | NoMatch {
      noMatchTerm :: !Doc,
      noMatchPos :: !Position
    }
  | ExpectedFunc {
      expectedFuncPos :: !Position
    }
  | CyclicDefs {
      cyclicDefsPos :: ![Position]
    }
  | CyclicInherit {
      cyclicInheritPos :: !Position
    }
  | IllegalAccess {
      illegalAccessPos :: ![Position],
      illegalAccessSym :: !Strict.ByteString,
      illegalAccessKind :: !Visibility
    }
  | OutOfContext {
      outOfContextPos :: ![Position],
      outOfContextKind :: !ContextKind,
      outOfContextSym :: !Strict.ByteString
    }
  | PatternBindMismatch {
      patternBindMismatchPos :: ![Position],
      patternBindMismatchSym :: !Strict.ByteString
    }
  | CyclicPrecedence {
      cyclicPrecedencePos :: ![Position]
    }
  | PrecedenceParseError {
      precParseErrorPos :: !Position
    }
  | ExpectedRef {
      expectedRefPos :: !Position
    }
  | MissingFields {
      missingFieldsNames :: ![Strict.ByteString],
      missingFieldsPos :: !Position
    }
  | TupleMismatch {
      tupleMismatchExpected :: !Word,
      tupleMismatchActual :: !Word,
      tupleMismatchPos :: !Position
    }
    -- | Duplicate name reference binding.
  | DuplicateName {
      duplicateElemName :: !Strict.ByteString,
      duplicateNamePosList :: ![Position]
    }
{-
  -- | An error message representing an undefined proposition in the
  -- truth envirnoment.
    UndefProp {
      -- | The name of the undefined proposition.
      undefName :: !Symbol,
      -- | The position at which the bad use of "exact" occurred.
      undefPos :: !Position
    }
  -- | An error message representing an attempt to use the "exact"
  -- rule with a proposition that does not match the goal.
  | ApplyMismatch {
      -- | The name of the mismatched proposition in the truth environment.
      applyName :: !Symbol,
      -- | The proposition from the truth environment.
      applyProp :: Term Symbol Symbol,
      -- | The goal proposition.
      applyGoal :: Term Symbol Symbol,
      -- | The position at which the bad use of "exact" occurred.
      applyPos :: !Position
    }
  -- | An error message representing an attempt to use the "intro"
  -- rule with a goal that is not an implies proposition.
  | IntroMismatch {
      -- | The goal proposition.
      introGoal :: Term Symbol Symbol,
      -- | The position at which the bad use of "exact" occurred.
      introPos :: !Position
    }
  -- | An error message representing an attempt to use the "introVar"
  -- rule with a goal that is not a forall proposition.
  | IntroVarMismatch {
      -- | The goal proposition.
      introVarGoal :: Term Symbol Symbol,
      -- | The position at which the bad use of "exact" occurred.
      introVarPos :: !Position
    }
  -- | An error message representing an attempt to use the "apply"
  -- rule with a proposition that is not a forall proposition.
  | ApplyWithMismatch {
      -- | The proposition attempting to be applied.
      applyWithProp :: Term Symbol Symbol,
      -- | The position at which the bad use of "apply" occurred.
      applyWithPos :: !Position
    }
  -- | An error message indicating that a proof script continues after
  -- the proof is complete.
  | Complete {
      -- | The position at which the bad use of "apply" occurred.
      completePos :: !Position
    }
  -- | An error message indicating that a proof script ended before
  -- the proof was complete.
  | Incomplete
-}
    deriving (Ord, Eq)

instance Hashable Message where
  hashWithSalt s BadChars { badCharsContent = str, badCharsPos = pos } =
    s `hashWithSalt` (0 :: Int) `hashWithSalt` str `hashWithSalt` pos
  hashWithSalt s BadEscape { badEscContent = str, badEscPos = pos } =
    s `hashWithSalt` (1 :: Int) `hashWithSalt` str `hashWithSalt` pos
  hashWithSalt s LongCharLiteral { longCharContent = str, longCharPos = pos } =
    s `hashWithSalt` (2 :: Int) `hashWithSalt` str `hashWithSalt` pos
  hashWithSalt s NewlineCharLiteral { newlineCharPos = pos } =
    s `hashWithSalt` (3 :: Int) `hashWithSalt` pos
  hashWithSalt s TabCharLiteral { tabCharPos = pos } =
    s `hashWithSalt` (4 :: Int) `hashWithSalt` pos
  hashWithSalt s EmptyCharLiteral { emptyCharPos = pos } =
    s `hashWithSalt` (5 :: Int) `hashWithSalt` pos
  hashWithSalt s UntermComment { untermCommentPos = pos } =
    s `hashWithSalt` (6 :: Int) `hashWithSalt` pos
  hashWithSalt s TabStringLiteral { tabStringPos = pos } =
    s `hashWithSalt` (7 :: Int) `hashWithSalt` pos
  hashWithSalt s UntermString { untermStringPos = pos } =
    s `hashWithSalt` (8 :: Int) `hashWithSalt` pos
  hashWithSalt s HardTabs { hardTabsPos = pos } =
    s `hashWithSalt` (9 :: Int) `hashWithSalt` pos
  hashWithSalt s TrailingWhitespace { trailingWhitespacePos = pos } =
    s `hashWithSalt` (10 :: Int) `hashWithSalt` pos
  hashWithSalt s NewlineInString { newlineInStringPos = pos } =
    s `hashWithSalt` (11 :: Int) `hashWithSalt` pos
  hashWithSalt s ParseError { parseErrorToken = tok } =
    s `hashWithSalt` (12 :: Int) `hashWithSalt` position tok
  hashWithSalt s NoTopLevelDef { noTopLevelDefName = sym,
                                 noTopLevelDefPos = pos } =
    s `hashWithSalt` (13 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s DuplicateField { duplicateFieldName = sym,
                                  duplicateFieldPosList = pos } =
    s `hashWithSalt` (14 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s NamelessField { namelessFieldPos = pos } =
    s `hashWithSalt` (15 :: Int) `hashWithSalt` pos
  hashWithSalt s DuplicateTruth { duplicateTruthName = sym,
                                  duplicateTruthPosList = pos } =
    s `hashWithSalt` (16 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s UndefSymbol { undefSymbolSym = sym, undefSymbolPos = pos } =
    s `hashWithSalt` (17 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s NamelessUninitDef { namelessUninitDefPos = pos } =
    s `hashWithSalt` (18 :: Int) `hashWithSalt` pos
  hashWithSalt s DuplicateBuilder { duplicateBuilderName = sym,
                                    duplicateBuilderPosList = pos } =
    s `hashWithSalt` (19 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s CannotFind { cannotFindName = cname,
                              cannotFindIsFileName = isfile,
                              cannotFindPos = pos } =
    s `hashWithSalt` (20 :: Int) `hashWithSalt`
    cname `hashWithSalt` isfile `hashWithSalt` pos
  hashWithSalt s CannotAccess { cannotAccessName = cname,
                                cannotAccessFileName = filename,
                                cannotAccessMsg = msg,
                                cannotAccessPos = pos } =
    s `hashWithSalt` (21 :: Int) `hashWithSalt` cname `hashWithSalt`
    filename `hashWithSalt` msg `hashWithSalt` pos
  hashWithSalt s BadComponentName { badComponentNameExpected = expected,
                                    badComponentNameActual = actual,
                                    badComponentNamePos = pos } =
    s `hashWithSalt` (22 :: Int) `hashWithSalt`
    expected `hashWithSalt` actual `hashWithSalt` pos
  hashWithSalt s CannotCreate { cannotCreateName = cname,
                                cannotCreateFileName = filename,
                                cannotCreateMsg = msg } =
    s `hashWithSalt` (23 :: Int) `hashWithSalt`
    cname `hashWithSalt` filename `hashWithSalt` msg
  hashWithSalt s ImportNestedScope { importNestedScopePos = pos } =
    s `hashWithSalt` (24 :: Int) `hashWithSalt` pos
  hashWithSalt s InternalError { internalErrorPos = pos } =
    s `hashWithSalt` (25 :: Int) `hashWithSalt` pos
  hashWithSalt s CallNonFunc { callNonFuncPos = pos } =
    s `hashWithSalt` (26 :: Int) `hashWithSalt` pos
  hashWithSalt s NoMatch { noMatchPos = pos } =
    s `hashWithSalt` (27 :: Int) `hashWithSalt` pos
  hashWithSalt s ExpectedFunc { expectedFuncPos = pos } =
    s `hashWithSalt` (28 :: Int) `hashWithSalt` pos
  hashWithSalt s CyclicDefs { cyclicDefsPos = pos } =
    s `hashWithSalt` (29 :: Int) `hashWithSalt` pos
  hashWithSalt s CyclicInherit { cyclicInheritPos = pos } =
    s `hashWithSalt` (30 :: Int) `hashWithSalt` pos
  hashWithSalt s IllegalAccess { illegalAccessPos = pos } =
    s `hashWithSalt` (31 :: Int) `hashWithSalt` pos
  hashWithSalt s OutOfContext { outOfContextPos = pos } =
    s `hashWithSalt` (32 :: Int) `hashWithSalt` pos
  hashWithSalt s DuplicateSyntax { duplicateSyntaxName = sym,
                                   duplicateSyntaxPosList = pos } =
    s `hashWithSalt` (33 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s PatternBindMismatch { patternBindMismatchPos = pos,
                                       patternBindMismatchSym = sym } =
    s `hashWithSalt` (34 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s CyclicPrecedence { cyclicPrecedencePos = pos } =
    s `hashWithSalt` (35 :: Int) `hashWithSalt` pos
  hashWithSalt s PrecedenceParseError { precParseErrorPos = pos } =
    s `hashWithSalt` (36 :: Int) `hashWithSalt` pos
  hashWithSalt s ExpectedRef { expectedRefPos = pos } =
    s `hashWithSalt` (37 :: Int) `hashWithSalt` pos
  hashWithSalt s MissingFields { missingFieldsPos = pos,
                                 missingFieldsNames = names } =
    s `hashWithSalt` (38 :: Int) `hashWithSalt` names `hashWithSalt` pos
  hashWithSalt s TupleMismatch { tupleMismatchExpected = expected,
                                 tupleMismatchActual = actual,
                                 tupleMismatchPos = pos } =
    s `hashWithSalt` (39 :: Int) `hashWithSalt`
    expected `hashWithSalt` actual `hashWithSalt` pos
  hashWithSalt s DuplicateName { duplicateElemName = sym,
                                 duplicateNamePosList = pos } =
    s `hashWithSalt` (40 :: Int) `hashWithSalt` sym `hashWithSalt` pos

instance Msg.Message Message where
  severity HardTabs {} = Msg.Warning
  severity TrailingWhitespace {} = Msg.Warning
  severity NamelessUninitDef {} = Msg.Warning
  severity InternalError {} = Msg.Internal
  severity CallNonFunc {} = Msg.Internal
  severity NoMatch {} = Msg.Internal
  severity _ = Msg.Error

  brief BadChars { badCharsContent = chrs }
    | Lazy.length chrs == 1 = string "Invalid character" <+>
                              dquoted (lazyBytestring chrs)
    | otherwise = string "Invalid characters" <+>
                  dquoted (lazyBytestring chrs)
  brief BadEscape { badEscContent = content } =
    string "Invalid escape sequence" <+> dquoted (lazyBytestring content)
  brief EmptyCharLiteral {} = string "Empty character literal"
  brief NewlineCharLiteral {} = string "Unescaped newline in character literal"
  brief TabCharLiteral {} = string "Unescaped hard tab in character literal"
  brief LongCharLiteral {} = string "Multiple characters in character literal"
  brief UntermComment {} = string "Unterminated comment"
  brief TabStringLiteral {} = string "Unescaped hard tab in string literal"
  brief UntermString {} = string "Unterminated string literal"
  brief HardTabs {} = string "Hard tabs"
  brief TrailingWhitespace {} = string "Trailing whitespace"
  brief NewlineInString {} = string "Unescaped newline in string literal"
  brief ParseError {} = string "Syntax error"
  brief NoTopLevelDef { noTopLevelDefName = namestr } =
    string "Expected a top-level definition named" <+>
    dquoted (bytestring namestr)
  brief DuplicateField { duplicateFieldName = namestr } =
    string "Duplicate field name" <+> bytestring namestr
  brief NamelessField {} = string "Field binding has no name"
  brief DuplicateTruth { duplicateTruthName = namestr } =
    string "Duplicate truth definition" <+> bytestring namestr
  brief UndefSymbol { undefSymbolSym = namestr } =
    string "Undefined symbol" <+> bytestring namestr
  brief NamelessUninitDef {} =
    string "Uninitialized definition with no top-level name"
  brief DuplicateBuilder { duplicateBuilderName = namestr } =
    string "Multiple builder definitions with name " <+> bytestring namestr
  brief CannotFind { cannotFindName = cname, cannotFindIsFileName = True } =
    hsep [ string "File", dquoted (bytestring cname),
           string "does not exist" ]
  brief CannotFind { cannotFindName = cname, cannotFindIsFileName = False } =
    hsep [ string "Cannot locate component", bytestring cname ]
  brief CannotAccess { cannotAccessName = Nothing,
                       cannotAccessFileName = fname } =
    string "Cannot access file" <+> dquoted (bytestring fname)
  brief CannotAccess { cannotAccessName = Just cname } =
    string "Cannot access component" <+> bytestring cname
  brief BadComponentName {} = string "Component name mismatch"
  brief CannotCreate { cannotCreateName = Nothing,
                       cannotCreateFileName = fname } =
    string "Cannot create file" <+> dquoted (bytestring fname)
  brief CannotCreate { cannotCreateName = Just cname } =
    string "Cannot create file for" <+> bytestring cname
  brief ImportNestedScope {} = string "Importing from a nested scope"
  brief InternalError { internalErrorStr = str } = bytestring str
  brief CallNonFunc {} = string "Call to non-function during evaluation"
  brief NoMatch {} = string "No pattern matching term"
  brief ExpectedFunc {} = string "Expected a term with a function type"
  brief CyclicDefs {} = string "Cyclic scope definitions"
  brief CyclicInherit {} = string "Cyclic inheritance"
  brief IllegalAccess { illegalAccessKind = kind, illegalAccessSym = sym } =
    string "Illegal access to " <> format kind <>
    string " private element " <> bytestring sym
  brief OutOfContext { outOfContextSym = sym, outOfContextKind = kind } =
    string "Cannot access " <> format kind <>
    string " element " <> bytestring sym <>
    string " from static context"
  brief DuplicateSyntax { duplicateSyntaxName = namestr } =
    string "Multiple syntax directives for symbol " <+> bytestring namestr
  brief PatternBindMismatch { patternBindMismatchSym = sym } =
    string "Symbol " <+> bytestring sym <+>
    string " is not defined by other options in the pattern"
  brief CyclicPrecedence {} = string "Conflicting precedence directives"
  brief PrecedenceParseError {} = string "Syntax error"
  brief ExpectedRef {} = string "Expected a reference to a definition"
  brief MissingFields {} = string "Record value does not have required field(s)"
  brief TupleMismatch { tupleMismatchExpected = expected,
                        tupleMismatchActual = actual }
    | expected < actual = string "Too many fields in tuple"
    | otherwise = string "Not enough fields in tuple"
  brief DuplicateName { duplicateElemName = namestr } =
    string "Duplicate name reference" <+> bytestring namestr

  details m | Msg.severity m == Msg.Internal =
    Just $! string "An internal compiler error has occurred."
  details HardTabs {} =
    Just $! string "Use of hard tabs is discouraged; use spaces instead."
  details LongCharLiteral {} =
    Just $! string "Use a string literal to represent multiple characters"
  details CannotAccess { cannotAccessName = Nothing,
                         cannotAccessMsg = msg } =
    Just $! string "Error while accessing file:" </> bytestring msg
  details CannotAccess { cannotAccessName = Just _,
                         cannotAccessFileName = fname,
                         cannotAccessMsg = msg } =
    Just $! fillSep [ string "Error while accessing file",
                      dquoted (bytestring fname) <> colon,
                      bytestring msg ]
  details BadComponentName { badComponentNameExpected = expected,
                             badComponentNameActual = Just actual } =
    Just $! fillSep [ string "Expected component named",
                      bytestring expected <> comma,
                      string "but actual name is",
                      bytestring actual ]
  details BadComponentName { badComponentNameExpected = expected,
                             badComponentNameActual = Nothing } =
    Just $! fillSep [ string "Expected component named",
                      bytestring expected <> comma,
                      string "but no component declaration present" ]
  details CannotCreate { cannotCreateName = Nothing,
                         cannotCreateMsg = msg } =
    Just $! string "Error while creating file:" </> bytestring msg
  details CannotCreate { cannotCreateName = Just _,
                         cannotCreateFileName = fname,
                         cannotCreateMsg = msg } =
    Just $! fillSep [ string "Error while creating file",
                      dquoted (bytestring fname) <> colon,
                      bytestring msg ]
  details CallNonFunc { callNonFuncTerm = term } =
    Just $! fillSep [string "value", term, string "is not a function"]
  details NoMatch { noMatchTerm = term } =
    Just $! fillSep [string "value", term, string "could not be matched"]
  details CyclicPrecedence {} =
    Just $! string "These precedence directives form one or more cycles"
  details TupleMismatch { tupleMismatchExpected = expected,
                        tupleMismatchActual = actual } =
    Just $! string "Expected " <> format expected <>
            string ", got " <> format actual
  details _ = Nothing

  highlighting HardTabs {} = Msg.Background
  highlighting TrailingWhitespace {} = Msg.Background
  highlighting TabStringLiteral {} = Msg.Background
  highlighting _ = Msg.Foreground

instance Msg.MessagePosition BasicPosition Message where
  positions BadChars { badCharsPos = pos } = [pos]
  positions BadEscape { badEscPos = pos } = [pos]
  positions NewlineCharLiteral { newlineCharPos = pos } = [pos]
  positions TabCharLiteral { tabCharPos = pos } = [pos]
  positions LongCharLiteral { longCharPos = pos } = [pos]
  positions EmptyCharLiteral { emptyCharPos = pos } = [pos]
  positions UntermComment { untermCommentPos = pos } = [pos]
  positions TabStringLiteral { tabStringPos = pos } = [pos]
  positions UntermString { untermStringPos = pos } = [pos]
  positions HardTabs { hardTabsPos = pos } = [pos]
  positions TrailingWhitespace { trailingWhitespacePos = pos } = [pos]
  positions NewlineInString { newlineInStringPos = pos } = [pos]
  positions ParseError { parseErrorToken = tok } = [position tok]
  positions NoTopLevelDef { noTopLevelDefPos = pos } = [pos]
  positions DuplicateField { duplicateFieldPosList = poslist } = poslist
  positions NamelessField { namelessFieldPos = pos } = [pos]
  positions DuplicateTruth { duplicateTruthPosList = poslist } = poslist
  positions UndefSymbol { undefSymbolPos = pos } = pos
  positions NamelessUninitDef { namelessUninitDefPos = pos } = [pos]
  positions DuplicateBuilder { duplicateBuilderPosList = poslist } = poslist
  positions CannotFind { cannotFindPos = pos } = [pos]
  positions CannotAccess { cannotAccessPos = pos } = [pos]
  positions BadComponentName { badComponentNamePos = pos } = [pos]
  positions CannotCreate {} = []
  positions ImportNestedScope { importNestedScopePos = pos } = [pos]
  positions InternalError { internalErrorPos = poslist } = poslist
  positions CallNonFunc { callNonFuncPos = pos } = [pos]
  positions NoMatch { noMatchPos = pos } = [pos]
  positions ExpectedFunc { expectedFuncPos = pos } = [pos]
  positions CyclicDefs { cyclicDefsPos = pos } = pos
  positions CyclicInherit { cyclicInheritPos = pos } = [pos]
  positions IllegalAccess { illegalAccessPos = pos } = pos
  positions OutOfContext { outOfContextPos = pos } = pos
  positions DuplicateSyntax { duplicateSyntaxPosList = poslist } = poslist
  positions PatternBindMismatch { patternBindMismatchPos = poslist } = poslist
  positions CyclicPrecedence { cyclicPrecedencePos = poslist } = poslist
  positions PrecedenceParseError { precParseErrorPos = pos } = [pos]
  positions ExpectedRef { expectedRefPos = pos } = [pos]
  positions MissingFields { missingFieldsPos = pos } = [pos]
  positions TupleMismatch { tupleMismatchPos = pos } = [pos]
  positions DuplicateName { duplicateNamePosList = poslist } = poslist

-- | Report bad characters in lexer input.
badChars :: MonadMessages Message m =>
            Lazy.ByteString
         -- ^ The bad characters.
         -> Position
         -- ^ The position at which the bad characters occur.
         -> m ()
badChars str pos = message BadChars { badCharsContent = str, badCharsPos = pos }

-- | Report a bad escape sequence.
badEscape :: MonadMessages Message m =>
             Lazy.ByteString
          -- ^ The bad characters.
          -> Position
          -- ^ The position at which the bad characters occur.
          -> m ()
badEscape str pos = message BadEscape { badEscContent = str, badEscPos = pos }

-- | Report an empty character literal.
emptyCharLiteral :: MonadMessages Message m =>
                    Position
                 -- ^ The position at which the bad characters occur.
                 -> m ()
emptyCharLiteral = message . EmptyCharLiteral

-- | Report an empty character literal.
longCharLiteral :: MonadMessages Message m =>
                   Lazy.ByteString
                -- ^ The character literal.
                -> Position
                -- ^ The position at which the bad characters occur.
                -> m ()
longCharLiteral str pos =
  message LongCharLiteral { longCharPos = pos, longCharContent = str }

-- | Report an unescaped newline in a character literal.
newlineCharLiteral :: MonadMessages Message m =>
                      Position
                   -- ^ The position at which the bad characters occur.
                   -> m ()
newlineCharLiteral = message . NewlineCharLiteral

-- | Report an unescaped tab in a character literal.
tabCharLiteral :: MonadMessages Message m =>
                  Position
               -- ^ The position at which the bad characters occur.
               -> m ()
tabCharLiteral = message . TabCharLiteral

-- | Report an unterminated comment in lexer input.
untermComment :: MonadMessages Message m =>
                 Position
              -- ^ The position at which the hard tabs occur.
              -> m ()
untermComment = message . UntermComment

-- | Report an unescaped tab in a string literal.
tabInStringLiteral :: MonadMessages Message m =>
                      Position
                   -- ^ The position at which the bad characters occur.
                   -> m ()
tabInStringLiteral pos =
  message TabStringLiteral { tabStringPos = pos }

-- | Report an unterminated comment in lexer input.
untermString :: MonadMessages Message m =>
                Position
             -- ^ The position at which the hard tabs occur.
             -> m ()
untermString = message . UntermString

-- | Report hard tabs in lexer input.
hardTabs :: MonadMessages Message m =>
            Position
         -- ^ Position at which the hard tabs occur.
         -> m ()
hardTabs pos = message HardTabs { hardTabsPos = pos }

-- | Report trailing whitespace in lexer input.
trailingWhitespace :: MonadMessages Message m =>
                      Position
                   -- ^ Position at which the trailing whitespace occurs
                   -> m ()
trailingWhitespace = message . TrailingWhitespace

-- | Report hard tabs in lexer input.
newlineInString :: MonadMessages Message m =>
                   Position
                -- ^ The position at which the hard tabs occur.
                -> m ()
newlineInString = message . NewlineInString

-- | Report a parse error.
parseError :: MonadMessages Message m =>
              Token
           -- ^ The position at which the hard tabs occur.
           -> m ()
parseError = message . ParseError

-- | Report missing top-level definition.
noTopLevelDef :: (MonadMessages Message m, MonadSymbols m) =>
                 Symbol
              -- ^ The expected top level definition name.
              -> Position
              -- ^ The file position.
              -> m ()
noTopLevelDef sym pos =
  do
    str <- name sym
    message NoTopLevelDef { noTopLevelDefName = str, noTopLevelDefPos = pos }

-- | Report duplicate fields.
duplicateField :: (MonadMessages Message m, MonadSymbols m) =>
                  Symbol
               -- ^ The duplicate field name.
               -> [Position]
               -- ^ The position at which the duplicated field occurs.
               -> m ()
duplicateField sym poslist =
  do
    str <- name sym
    message DuplicateField { duplicateFieldName = str,
                             duplicateFieldPosList = poslist }

-- | Report a field binding with no name.
namelessField :: MonadMessages Message m =>
                 Position
              -- ^ The position at which the nameless field occurs.
              -> m ()
namelessField = message . NamelessField

-- | Report duplicate truths.
duplicateTruth :: (MonadMessages Message m, MonadSymbols m) =>
                  Symbol
               -- ^ The duplicate truth name.
               -> [Position]
               -- ^ The position at which the duplicated truth
               -- definition occurs.
               -> m ()
duplicateTruth sym poslist =
  do
    str <- name sym
    message DuplicateTruth { duplicateTruthName = str,
                             duplicateTruthPosList = poslist }

-- | Report an undefined symbol.
undefSymbol :: (MonadMessages Message m, MonadSymbols m) =>
               Symbol
            -- ^ The undefined symbol name.
            -> [Position]
            -- ^ The position at which the undefined symbol
            -- definition occurs.
            -> m ()
undefSymbol sym pos =
  do
    str <- name sym
    message UndefSymbol { undefSymbolSym = str, undefSymbolPos = pos }

-- | Report an uninitialized definition with no top-level name.
namelessUninitDef :: MonadMessages Message m =>
                     Position
                  -- ^ The position at which the nameless field occurs.
                  -> m ()
namelessUninitDef pos = message NamelessUninitDef { namelessUninitDefPos = pos }

-- | Report duplicate builders.
duplicateBuilder :: (MonadMessages Message m, MonadSymbols m) =>
                    Symbol
                 -- ^ The duplicate builder name.
                 -> [Position]
                 -- ^ The position at which the duplicated builder
                 -- definition occurs.
                 -> m ()
duplicateBuilder sym poslist =
  do
    str <- name sym
    message DuplicateBuilder { duplicateBuilderName = str,
                               duplicateBuilderPosList = poslist }

-- | Report nonexistent file.
cannotFindFile :: MonadMessages Message m =>
                  Strict.ByteString
               -- ^ The name of the file (minus any prefix path).
               -> Position
               -- ^ The position at which the file is referenced.
               -> m ()
cannotFindFile fname pos =
  message CannotFind { cannotFindName = fname, cannotFindIsFileName = True,
                       cannotFindPos = pos }

-- | Report nonexistent component.
cannotFindComponent :: (MonadMessages Message m, MonadSymbols m) =>
                       [Symbol]
                    -- ^ The name of the component.
                    -> Position
                    -- ^ The position at which the file is referenced.
                    -> m ()
cannotFindComponent cname pos =
  do
    bstrs <- mapM name cname
    message CannotFind { cannotFindName = Strict.intercalate "." bstrs,
                         cannotFindIsFileName = False,
                         cannotFindPos = pos }

-- | Report inaccessible file.
cannotAccessFile :: MonadMessages Message m =>
                    Strict.ByteString
                 -- ^ The name of the file (minus any prefix path).
                 -> Strict.ByteString
                 -- ^ The OS-provided error message.
                 -> Position
                 -- ^ The position at which the file is referenced.
                 -> m ()
cannotAccessFile fname msg pos =
  message CannotAccess { cannotAccessName = Nothing,
                         cannotAccessFileName = fname,
                         cannotAccessMsg = msg,
                         cannotAccessPos = pos }

-- | Report inaccessible component.
cannotAccessComponent :: (MonadMessages Message m, MonadSymbols m) =>
                         [Symbol]
                      -- ^ The name of the component.
                      -> Strict.ByteString
                      -- ^ The name of the file (minus any prefix path).
                      -> Strict.ByteString
                      -- ^ The OS-provided error message.
                      -> Position
                      -- ^ The position at which the file is referenced.
                      -> m ()
cannotAccessComponent cname fname msg pos =
  do
    bstrs <- mapM name cname
    message CannotAccess {
              cannotAccessName = Just $! Strict.intercalate "." bstrs,
              cannotAccessFileName = fname,
              cannotAccessMsg = msg,
              cannotAccessPos = pos
            }

badComponentName :: (MonadMessages Message m, MonadSymbols m) =>
                    [Symbol]
                 -- ^ The expected name.
                 -> Maybe [Symbol]
                 -- ^ The actual name.
                 -> Position
                 -- ^ The position of the component statement.
                 -> m ()
badComponentName expected actual pos =
  do
    expectedBstrs <- mapM name expected
    actualBstr <- case actual of
      Just actual' ->
        do
          actualBstrs <- mapM name actual'
          return $! Just $! Strict.intercalate "." actualBstrs
      Nothing -> return Nothing
    message BadComponentName {
              badComponentNameExpected = Strict.intercalate "." expectedBstrs,
              badComponentNameActual = actualBstr,
              badComponentNamePos = pos
            }

cannotCreateFile :: MonadMessages Message m =>
                    Strict.ByteString
                 -- ^ The name of the file (minus any prefix path).
                 -> Strict.ByteString
                 -- ^ The OS-provided error message.
                 -> m ()
cannotCreateFile fname msg =
  message CannotCreate { cannotCreateName = Nothing,
                         cannotCreateFileName = fname,
                         cannotCreateMsg = msg }

-- | Report error creating artifact.
cannotCreateArtifact :: (MonadMessages Message m, MonadSymbols m) =>
                        [Symbol]
                     -- ^ The name of the artifact.
                     -> Strict.ByteString
                     -- ^ The name of the file (minus any prefix path).
                     -> Strict.ByteString
                     -- ^ The OS-provided error message.
                     -> m ()
cannotCreateArtifact cname fname msg =
  do
    bstrs <- mapM name cname
    message CannotCreate { cannotCreateName =
                              Just $! Strict.intercalate "." bstrs,
                           cannotCreateFileName = fname,
                           cannotCreateMsg = msg }

-- | Report an import of a nested scope.
importNestedScope :: MonadMessages Message m =>
                     Position
                  -- ^ The position at which the nameless field occurs.
                  -> m ()
importNestedScope = message . ImportNestedScope

-- | Report an internal error.
internalError :: MonadMessages Message m =>
                 Strict.ByteString
              -- ^ An explanation of the problem
              -> [Position]
              -- ^ The position at which the nameless field occurs.
              -> m ()
internalError str pos = message InternalError { internalErrorStr = str,
                                                internalErrorPos = pos }
{-
-- | Report a call to a non-function in evaluation.
callNonFunc :: (MonadMessages Message m, MonadSymbols m, MonadPositions m,
                FormatM m bound, FormatM m free, Default bound, Eq bound) =>
               Elim bound free
            -- ^ The non-function term being called.
            -> DWARFPosition defty tydefty
            -- ^ The position at which the call occurs.
            -> m ()
callNonFunc term pos =
  let
    basicpos = basicPosition pos
  in do
    termdoc <- formatM term
    message CallNonFunc { callNonFuncTerm = termdoc, callNonFuncPos = basicpos }

-- | Report an unmatched value in a pattern match.
noMatch :: (MonadMessages Message m, MonadSymbols m, MonadPositions m,
            FormatM m bound, FormatM m free, Default bound, Eq bound) =>
           Intro bound free
        -- ^ The unmatched term.
        -> DWARFPosition defty tydefty
        -- ^ The position at which the match occurs.
        -> m ()
noMatch term pos =
  let
    basicpos = basicPosition pos
  in do
    termdoc <- formatM term
    message NoMatch { noMatchTerm = termdoc, noMatchPos = basicpos }
-}
-- | Type error when expecting a function type, but getting something else.
expectedFuncType :: (MonadMessages Message m,
                     MonadSymbols m, MonadPositions m) =>
                    DWARFPosition defty tydefty
                 -- ^ The position at which the match occurs.
                 -> m ()
expectedFuncType pos =
  let
    basicpos = basicPosition pos
  in
    message ExpectedFunc { expectedFuncPos = basicpos }

cyclicDefs :: (MonadMessages Message m,
               MonadSymbols m, MonadPositions m) =>
              [Position]
           -- ^ The positions of the cyclic definitions
           -> m ()
cyclicDefs = message . CyclicDefs

cyclicInherit :: (MonadMessages Message m,
                  MonadSymbols m, MonadPositions m) =>
                 DWARFPosition defty tydefty
              -- ^ The position at which the inheritance occurs.
              -> m ()
cyclicInherit pos =
  let
    basicpos = basicPosition pos
  in
    message CyclicInherit { cyclicInheritPos = basicpos }

illegalAccess :: (MonadMessages Message m,
                  MonadSymbols m, MonadPositions m) =>
                 Symbol
              -- ^ The symbol that was illegally accessed.
              -> Visibility
              -> [Position]
              -- ^ The position at which the access occurs.
              -> m ()
illegalAccess sym vis poslist =
  do
    str <- name sym
    message IllegalAccess { illegalAccessSym = str, illegalAccessKind = vis,
                            illegalAccessPos = poslist }

-- | Report an access to an object definition in a static context.
outOfContextAccess :: (MonadMessages Message m,
                       MonadSymbols m, MonadPositions m) =>
                      Symbol
                   -- ^ The symbol that was accessed.
                   -> ContextKind
                   -- ^ The context of the symbol.
                   -> [Position]
                   -- ^ The position at which the access occurs.
                   -> m ()
outOfContextAccess sym ctx poslist =
  do
    str <- name sym
    message OutOfContext { outOfContextSym = str, outOfContextKind = ctx,
                           outOfContextPos = poslist }

-- | Report duplicate syntax directives.
duplicateSyntax :: (MonadMessages Message m, MonadSymbols m) =>
                   Symbol
                -- ^ The duplicate syntax name.
                -> [Position]
                -- ^ The position at which the duplicated syntax
                -- definition occurs.
                -> m ()
duplicateSyntax sym poslist =
  do
    str <- name sym
    message DuplicateSyntax { duplicateSyntaxName = str,
                              duplicateSyntaxPosList = poslist }

-- | Report extra symbols in an option pattern binding.
patternBindMismatch :: (MonadMessages Message m, MonadSymbols m) =>
                       Symbol
                    -- ^ The extra binding symbol.
                    -> [Position]
                    -- ^ The position at which the extra symbol occurs.
                    -> m ()
patternBindMismatch sym poslist =
  do
    str <- name sym
    message PatternBindMismatch { patternBindMismatchSym = str,
                                  patternBindMismatchPos = poslist }

-- | Report cyclic precedence directives
cyclicPrecedence :: (MonadMessages Message m, MonadSymbols m) =>
                    [Position]
                 -- ^ The position at which the inheritance occurs.
                 -> m ()
cyclicPrecedence pos = message CyclicPrecedence { cyclicPrecedencePos = pos }

-- | Report precedence parse errors
precedenceParseError :: (MonadMessages Message m) =>
                        Position
                     -- ^ The position at which the inheritance occurs.
                     -> m ()
precedenceParseError = message . PrecedenceParseError

-- | Report non-references where a reference was expected
expectedRef :: (MonadMessages Message m) =>
               Position
            -- ^ The position at which the inheritance occurs.
            -> m ()
expectedRef = message . ExpectedRef

-- | Report missing fields in a record.
missingFields :: (MonadMessages Message m, MonadSymbols m) =>
                 [Symbol]
              -- ^ The missing field symbols.
              -> Position
              -- ^ The position at which the extra symbol occurs.
              -> m ()
missingFields sym pos =
  do
    strs <- mapM name sym
    message MissingFields { missingFieldsNames = strs, missingFieldsPos = pos }

-- | Report missing fields in a record.
tupleMismatch :: (MonadMessages Message m) =>
                 Word
              -- ^ The expected number of fields
              -> Word
              -- ^ The actual number of fields
              -> Position
              -- ^ The position at which the extra symbol occurs.
              -> m ()
tupleMismatch expected actual pos =
  message TupleMismatch { tupleMismatchExpected = expected,
                          tupleMismatchActual = actual,
                          tupleMismatchPos = pos }

-- | Report duplicate element names.
duplicateName :: (MonadMessages Message m, MonadSymbols m) =>
                 Symbol
              -- ^ The duplicate field name.
              -> [Position]
              -- ^ The position at which the duplicated field occurs.
              -> m ()
duplicateName sym poslist =
  do
    str <- name sym
    message DuplicateName { duplicateElemName = str,
                            duplicateNamePosList = poslist }
