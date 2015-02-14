-- Copyright (c) 2013 Eric McCorkle.
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License as
-- published by the Free Software Foundation; either version 2 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
-- 02110-1301 USA

{-# OPTIONS_GHC -funbox-strict-fields -Wall -Werror #-}
{-# LANGUAGE FlexibleContexts #-}

-- | A module containing
module Language.Salt.Message(
       Message,
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
       parseError,
       noTopLevelDef,
       duplicateField,
       namelessField,
       duplicateTruth,
       badSyntax,
       badSyntaxKind,
       badSyntaxName,
       badSyntaxAssoc,
       badSyntaxPrec,
       badSyntaxRef,
       multipleFixity,
       undefSymbol,
       namelessUninitDef,
       duplicateBuilder,
       cannotFindFile,
       cannotFindComponent,
       cannotAccessFile,
       cannotAccessComponent
       ) where

import Control.Monad.Messages
import Control.Monad.Symbols
import Data.Hashable
import Data.Position
import Language.Salt.Surface.Token
import Data.Symbol
import Text.Format
--import Language.Salt.Core.Syntax

import qualified Data.ByteString.Lazy as Lazy
import qualified Data.ByteString.UTF8 as Strict
import qualified Data.Message as Msg

-- | A representation of proof errors that can be generated by a proof
-- checker.
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
    -- | A long character literal.
  | LongCharLiteral {
      -- | The bad characters from input (error).
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
      untermCommentPos :: !Position
    }
    -- | A hard tab in a string literal.
  | TabStringLiteral {
      -- | The position of the bad character literal.
      tabStringPos :: !Position
    }
    -- | Unterminated string literal (error).
  | UntermString {
      untermStringPos :: !Position
    }
    -- | Hard tabs in input (remark).
  | HardTabs {
      hardTabsPos :: !Position
    }
    -- | Trailing whitespace.
  | TrailingWhitespace {
      trailingWhitespacePos :: !Position
    }
    -- | Newline in a string constant.
  | NewlineInString {
      newlineInStringPos :: !Position
    }
    -- | Parse error.
  | ParseError {
      parseErrorToken :: !Token
    }
    -- | Missing expected module definition.
  | NoTopLevelDef {
      noTopLevelDefName :: !Strict.ByteString,
      noTopLevelDefPos :: !Position
    }
    -- | Duplicate record field binding.
  | DuplicateField {
      duplicateFieldName :: !Strict.ByteString,
      duplicateFieldPos :: !Position
    }
  | NamelessField {
      namelessFieldPos :: !Position
    }
    -- | Duplicate truth definition in the current environment.
  | DuplicateTruth {
      duplicateTruthName :: !Strict.ByteString,
      duplicateTruthPos :: !Position
    }
    -- | A bad syntax directive kind.
  | BadSyntax {
      badSyntaxPos :: !Position
    }
    -- | A bad syntax directive kind.
  | BadSyntaxKind {
      badSyntaxKindPos :: !Position
    }
    -- | An invalid name in a syntax directive.
  | BadSyntaxName {
      badSyntaxNamePos :: !Position
    }
    -- | An invalid associativity in a syntax directive.
  | BadSyntaxAssoc {
      badSyntaxAssocPos :: !Position
    }
    -- | An invalid precedence relation in a syntax directive.
  | BadSyntaxPrec {
      badSyntaxPrecPos :: !Position
    }
    -- | An invalid reference in a syntax directive
  | BadSyntaxRef {
      badSyntaxRefPos :: !Position
    }
  | MultipleFixity {
      multipleFixityPos :: !Position
    }
  -- | The undefined symbol.
  | UndefSymbol {
      undefSymbolSym :: !Strict.ByteString,
      undefSymbolPos :: !Position
    }
  -- | An uninitialized definition with no top-level name.
  | NamelessUninitDef {
      namelessUninitDefPos :: !Position
    }
    -- | Duplicate truth definition in the current environment.
  | DuplicateBuilder {
      duplicateBuilderName :: !Strict.ByteString,
      duplicateBuilderPos :: !Position
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
                                  duplicateFieldPos = pos } =
    s `hashWithSalt` (14 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s NamelessField { namelessFieldPos = pos } =
    s `hashWithSalt` (15 :: Int) `hashWithSalt` pos
  hashWithSalt s DuplicateTruth { duplicateTruthName = sym,
                                  duplicateTruthPos = pos } =
    s `hashWithSalt` (16 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s BadSyntax { badSyntaxPos = pos } =
    s `hashWithSalt` (17 :: Int) `hashWithSalt` pos
  hashWithSalt s BadSyntaxKind { badSyntaxKindPos = pos } =
    s `hashWithSalt` (18 :: Int) `hashWithSalt` pos
  hashWithSalt s BadSyntaxName { badSyntaxNamePos = pos } =
    s `hashWithSalt` (19 :: Int) `hashWithSalt` pos
  hashWithSalt s BadSyntaxAssoc { badSyntaxAssocPos = pos } =
    s `hashWithSalt` (20 :: Int) `hashWithSalt` pos
  hashWithSalt s BadSyntaxPrec { badSyntaxPrecPos = pos } =
    s `hashWithSalt` (21 :: Int) `hashWithSalt` pos
  hashWithSalt s BadSyntaxRef { badSyntaxRefPos = pos } =
    s `hashWithSalt` (22 :: Int) `hashWithSalt` pos
  hashWithSalt s MultipleFixity { multipleFixityPos = pos } =
    s `hashWithSalt` (23 :: Int) `hashWithSalt` pos
  hashWithSalt s UndefSymbol { undefSymbolSym = sym, undefSymbolPos = pos } =
    s `hashWithSalt` (24 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s NamelessUninitDef { namelessUninitDefPos = pos } =
    s `hashWithSalt` (25 :: Int) `hashWithSalt` pos
  hashWithSalt s DuplicateBuilder { duplicateBuilderName = sym,
                                    duplicateBuilderPos = pos } =
    s `hashWithSalt` (26 :: Int) `hashWithSalt` sym `hashWithSalt` pos
  hashWithSalt s CannotFind { cannotFindName = cname,
                              cannotFindIsFileName = isfile,
                              cannotFindPos = pos } =
    s `hashWithSalt` (27 :: Int) `hashWithSalt`
    cname `hashWithSalt` isfile `hashWithSalt` pos
  hashWithSalt s CannotAccess { cannotAccessName = cname,
                                cannotAccessFileName = filename,
                                cannotAccessMsg = msg,
                                cannotAccessPos = pos } =
    s `hashWithSalt` (28 :: Int) `hashWithSalt` cname `hashWithSalt`
    filename `hashWithSalt` msg `hashWithSalt` pos

instance Msg.Message Message where
  severity BadChars {} = Msg.Error
  severity BadEscape {} = Msg.Error
  severity LongCharLiteral {} = Msg.Error
  severity NewlineCharLiteral {} = Msg.Error
  severity TabCharLiteral {} = Msg.Error
  severity EmptyCharLiteral {} = Msg.Error
  severity UntermComment {} = Msg.Error
  severity TabStringLiteral {} = Msg.Error
  severity UntermString {} = Msg.Error
  severity HardTabs {} = Msg.Warning
  severity TrailingWhitespace {} = Msg.Warning
  severity NewlineInString {} = Msg.Error
  severity ParseError {} = Msg.Error
  severity NoTopLevelDef {} = Msg.Error
  severity DuplicateField {} = Msg.Error
  severity NamelessField {} = Msg.Error
  severity DuplicateTruth {} = Msg.Error
  severity BadSyntax {} = Msg.Error
  severity BadSyntaxKind {} = Msg.Error
  severity BadSyntaxName {} = Msg.Error
  severity BadSyntaxAssoc {} = Msg.Error
  severity BadSyntaxPrec {} = Msg.Error
  severity BadSyntaxRef {} = Msg.Error
  severity MultipleFixity {} = Msg.Error
  severity UndefSymbol {} = Msg.Error
  severity NamelessUninitDef {} = Msg.Warning
  severity DuplicateBuilder {} = Msg.Error
  severity CannotFind {} = Msg.Error
  severity CannotAccess {} = Msg.Error

  position BadChars { badCharsPos = pos } = Just pos
  position BadEscape { badEscPos = pos } = Just pos
  position NewlineCharLiteral { newlineCharPos = pos } = Just pos
  position TabCharLiteral { tabCharPos = pos } = Just pos
  position LongCharLiteral { longCharPos = pos } = Just pos
  position EmptyCharLiteral { emptyCharPos = pos } = Just pos
  position UntermComment { untermCommentPos = pos } = Just pos
  position TabStringLiteral { tabStringPos = pos } = Just pos
  position UntermString { untermStringPos = pos } = Just pos
  position HardTabs { hardTabsPos = pos } = Just pos
  position TrailingWhitespace { trailingWhitespacePos = pos } = Just pos
  position NewlineInString { newlineInStringPos = pos } = Just pos
  position ParseError { parseErrorToken = tok } = Just (position tok)
  position NoTopLevelDef { noTopLevelDefPos = pos } = Just pos
  position DuplicateField { duplicateFieldPos = pos } = Just pos
  position NamelessField { namelessFieldPos = pos } = Just pos
  position DuplicateTruth { duplicateTruthPos = pos } = Just pos
  position BadSyntax { badSyntaxPos = pos } = Just pos
  position BadSyntaxKind { badSyntaxKindPos = pos } = Just pos
  position BadSyntaxName { badSyntaxNamePos = pos } = Just pos
  position BadSyntaxAssoc { badSyntaxAssocPos = pos } = Just pos
  position BadSyntaxPrec { badSyntaxPrecPos = pos } = Just pos
  position BadSyntaxRef { badSyntaxRefPos = pos } = Just pos
  position MultipleFixity { multipleFixityPos = pos } = Just pos
  position UndefSymbol { undefSymbolPos = pos } = Just pos
  position NamelessUninitDef { namelessUninitDefPos = pos } = Just pos
  position DuplicateBuilder { duplicateBuilderPos = pos } = Just pos
  position CannotFind { cannotFindPos = pos } = Just pos
  position CannotAccess { cannotAccessPos = pos } = Just pos

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
  brief HardTabs {} = string "Hard tabs are discouraged"
  brief TrailingWhitespace {} = string "Trailing whitespace"
  brief NewlineInString {} = string "Unescaped newline in string literal"
  brief ParseError {} = string "Syntax error"
  brief NoTopLevelDef { noTopLevelDefName = namestr } =
    string "Expected top-level definition" <+> bytestring namestr
  brief DuplicateField { duplicateFieldName = namestr } =
    string "Duplicate field name" <+> bytestring namestr
  brief NamelessField {} = string "Field binding has no name"
  brief DuplicateTruth { duplicateTruthName = namestr } =
    string "Duplicate truth definition" <+> bytestring namestr
  brief BadSyntax {} = string "Invalid syntax directive"
  brief BadSyntaxKind {} = string "Invalid syntax directive"
  brief BadSyntaxName {} = string "Invalid syntax directive"
  brief BadSyntaxAssoc {} = string "Invalid syntax directive"
  brief BadSyntaxPrec {} = string "Invalid syntax directive"
  brief BadSyntaxRef {} = string "Invalid syntax directive"
  brief MultipleFixity {} = string "Multiple fixity directives"
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
    string "Cannot access file " <+> dquoted (bytestring fname)
  brief CannotAccess { cannotAccessName = Just cname } =
    string "Cannot access component" <+> bytestring cname

  details LongCharLiteral {} =
    Just $! string "Use a string literal to represent multiple characters"
  details BadSyntaxKind {} =
    Just $! string "Expected \"infix\", \"postfix\", or \"prec\""
  details BadSyntaxName {} = Just $! string "Expected a name here"
  details BadSyntaxAssoc {} =
    Just $! string "Expected \"left\", \"right\", or \"nonassoc\""
  details BadSyntaxPrec {} =
    Just $! string "Expected \">\", \"<\", or \"==\""
  details BadSyntaxRef {} = Just $! string "Expected a name here"
  details CannotAccess { cannotAccessName = Nothing,
                         cannotAccessMsg = msg } =
    Just $! string "Error while accessing file:" <+> bytestring msg
  details CannotAccess { cannotAccessName = Just _,
                         cannotAccessFileName = fname,
                         cannotAccessMsg = msg } =
    Just $! string "Error while accessing file" <+>
            dquoted (bytestring fname) <+> colon <+>
            bytestring msg
  details _ = Nothing

  highlighting HardTabs {} = Msg.Background
  highlighting TrailingWhitespace {} = Msg.Background
  highlighting TabStringLiteral {} = Msg.Background
  highlighting _ = Msg.Foreground

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
emptyCharLiteral pos =
  message EmptyCharLiteral { emptyCharPos = pos }

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
newlineCharLiteral pos =
  message NewlineCharLiteral { newlineCharPos = pos }

-- | Report an unescaped tab in a character literal.
tabCharLiteral :: MonadMessages Message m =>
                  Position
               -- ^ The position at which the bad characters occur.
               -> m ()
tabCharLiteral pos =
  message TabCharLiteral { tabCharPos = pos }

-- | Report an unterminated comment in lexer input.
untermComment :: MonadMessages Message m =>
                 Position
              -- ^ The position at which the hard tabs occur.
              -> m ()
untermComment pos = message UntermComment { untermCommentPos = pos }

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
untermString pos = message UntermString { untermStringPos = pos }

-- | Report hard tabs in lexer input.
hardTabs :: MonadMessages Message m =>
            Position
         -- ^ The position at which the hard tabs occur.
         -> m ()
hardTabs pos = message HardTabs { hardTabsPos = pos }

-- | Report trailing whitespace in lexer input.
trailingWhitespace :: MonadMessages Message m =>
                      Position
                   -- ^ The position at which the hard tabs occur.
                   -> m ()
trailingWhitespace pos =
  message TrailingWhitespace { trailingWhitespacePos = pos }

-- | Report hard tabs in lexer input.
newlineInString :: MonadMessages Message m =>
                   Position
                -- ^ The position at which the hard tabs occur.
                -> m ()
newlineInString pos = message NewlineInString { newlineInStringPos = pos }

-- | Report a parse error.
parseError :: MonadMessages Message m =>
              Token
           -- ^ The position at which the hard tabs occur.
           -> m ()
parseError tok = message ParseError { parseErrorToken = tok }

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
               -> Position
               -- ^ The position at which the duplicated field occurs.
               -> m ()
duplicateField sym pos =
  do
    str <- name sym
    message DuplicateField { duplicateFieldName = str, duplicateFieldPos = pos }

-- | Report a field binding with no name.
namelessField :: MonadMessages Message m =>
                 Position
              -- ^ The position at which the nameless field occurs.
              -> m ()
namelessField pos = message NamelessField { namelessFieldPos = pos }

-- | Report duplicate truths.
duplicateTruth :: (MonadMessages Message m, MonadSymbols m) =>
                  Symbol
               -- ^ The duplicate truth name.
               -> Position
               -- ^ The position at which the duplicated truth
               -- definition occurs.
               -> m ()
duplicateTruth sym pos =
  do
    str <- name sym
    message DuplicateTruth { duplicateTruthName = str, duplicateTruthPos = pos }

-- | Report a bad syntax directive.
badSyntax :: MonadMessages Message m =>
             Position
          -- ^ The position at which the bad syntax kind occurs.
          -> m ()
badSyntax pos = message BadSyntax { badSyntaxPos = pos }

-- | Report a bad syntax directive.
badSyntaxKind :: MonadMessages Message m =>
                 Position
              -- ^ The position at which the bad syntax kind occurs.
              -> m ()
badSyntaxKind pos = message BadSyntaxKind { badSyntaxKindPos = pos }

-- | Report a bad syntax directive.
badSyntaxName :: MonadMessages Message m =>
                 Position
              -- ^ The position at which the bad syntax name occurs.
              -> m ()
badSyntaxName pos = message BadSyntaxName { badSyntaxNamePos = pos }

-- | Report a bad associativity syntax directive.
badSyntaxAssoc :: MonadMessages Message m =>
                 Position
              -- ^ The position at which the bad syntax associativity occurs.
              -> m ()
badSyntaxAssoc pos = message BadSyntaxAssoc { badSyntaxAssocPos = pos }

-- | Report a bad precedence in a syntax directive.
badSyntaxPrec :: MonadMessages Message m =>
                 Position
              -- ^ The position at which the bad syntax precedence occurs.
              -> m ()
badSyntaxPrec pos = message BadSyntaxPrec { badSyntaxPrecPos = pos }

-- | Report a bad reference syntax directive.
badSyntaxRef :: MonadMessages Message m =>
                Position
             -- ^ The position at which the bad syntax name occurs.
             -> m ()
badSyntaxRef pos = message BadSyntaxRef { badSyntaxRefPos = pos }

-- | Report a bad reference syntax directive.
multipleFixity :: MonadMessages Message m =>
                  Position
               -- ^ The position at which the bad syntax name occurs.
               -> m ()
multipleFixity pos = message MultipleFixity { multipleFixityPos = pos }

-- | Report an undefined symbol.
undefSymbol :: (MonadMessages Message m, MonadSymbols m) =>
               Symbol
            -- ^ The undefined symbol name.
            -> Position
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
                 -> Position
                 -- ^ The position at which the duplicated builder
                 -- definition occurs.
                 -> m ()
duplicateBuilder sym pos =
  do
    str <- name sym
    message DuplicateBuilder { duplicateBuilderName = str,
                               duplicateBuilderPos = pos }

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
cannotFindComponent :: MonadMessages Message m =>
                       Strict.ByteString
                    -- ^ The name of the component.
                    -> Position
                    -- ^ The position at which the file is referenced.
                    -> m ()
cannotFindComponent cname pos =
  message CannotFind { cannotFindName = cname, cannotFindIsFileName = False,
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
cannotAccessComponent :: MonadMessages Message m =>
                         Strict.ByteString
                      -- ^ The name of the component.
                      -> Strict.ByteString
                      -- ^ The name of the file (minus any prefix path).
                      -> Strict.ByteString
                      -- ^ The OS-provided error message.
                      -> Position
                      -- ^ The position at which the file is referenced.
                      -> m ()
cannotAccessComponent cname fname msg pos =
  message CannotAccess { cannotAccessName = Just cname,
                         cannotAccessFileName = fname,
                         cannotAccessMsg = msg,
                         cannotAccessPos = pos }
