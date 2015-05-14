-- Copyright (c) 2015 Eric McCorkle.  All rights reserved.
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
{-# OPTIONS_GHC -Wall -Werror #-}
{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses,
             UndecidableInstances #-}

module Control.Monad.Components(
       MonadComponents(..),
       ComponentsT,
       Components,
       runComponentsT,
       mapComponentsT,
       runComponents
       ) where

import Control.Applicative
import Control.Monad.Artifacts.Class
import Control.Monad.CommentBuffer
import Control.Monad.Comments
import Control.Monad.Components.Class
import Control.Monad.Cont
import Control.Monad.Error
import Control.Monad.Genpos
import Control.Monad.Gensym
import Control.Monad.Keywords
import Control.Monad.Loader.Class
import Control.Monad.Messages
import Control.Monad.Reader
import Control.Monad.SourceFiles
import Control.Monad.SourceBuffer
import Control.Monad.State
import Control.Monad.Symbols
import Control.Monad.Writer
import Data.HashTable.IO(BasicHashTable)
import Data.Symbol
import Language.Salt.Surface.Syntax

import qualified Data.HashTable.IO as HashTable

type Table = BasicHashTable [Symbol] Component

newtype ComponentsT m a = ComponentsT { unpackComponentsT :: ReaderT Table m a }

type Components = ComponentsT IO

runComponentsT :: Monad m =>
                  ComponentsT m a
               -- ^ The @ComponentsT@ monad transformer to execute.
               -> Table
               -- ^ The components table to use.
               -> m a
runComponentsT c = runReaderT (unpackComponentsT c)

runComponents :: Components a
              -- ^ The @Components@ monad to execute.
              -> Table
              -- ^ The components table to use.
              -> IO a
runComponents = runComponentsT

mapComponentsT :: (Monad m, Monad n) =>
                  (m a -> n b) -> ComponentsT m a -> ComponentsT n b
mapComponentsT f = ComponentsT . mapReaderT f . unpackComponentsT

component' :: MonadIO m => [Symbol] -> ReaderT Table m Component
component' cname =
  do
    tab <- ask
    res <- liftIO (HashTable.lookup tab cname)
    case res of
      Just out -> return out
      Nothing -> error $! "Looking up nonexistent component"

components' :: MonadIO m => ReaderT Table m [([Symbol], Component)]
components' =
  do
    tab <- ask
    liftIO (HashTable.toList tab)

instance Monad m => Monad (ComponentsT m) where
  return = ComponentsT . return
  s >>= f = ComponentsT $ unpackComponentsT s >>= unpackComponentsT . f

instance Monad m => Applicative (ComponentsT m) where
  pure = return
  (<*>) = ap

instance (Monad m, Alternative m) => Alternative (ComponentsT m) where
  empty = lift empty
  s1 <|> s2 = ComponentsT (unpackComponentsT s1 <|> unpackComponentsT s2)

instance Functor (ComponentsT m) where
  fmap = fmap

instance MonadIO m => MonadComponents (ComponentsT m) where
  component = ComponentsT . component'
  components = ComponentsT components'

instance MonadIO m => MonadIO (ComponentsT m) where
  liftIO = ComponentsT . liftIO

instance MonadTrans ComponentsT where
  lift = ComponentsT . lift

instance MonadArtifacts path m => MonadArtifacts path (ComponentsT m) where
  artifact path = lift . artifact path
  artifactBytestring path = lift . artifactBytestring path
  artifactLazyBytestring path = lift . artifactLazyBytestring path

instance MonadCommentBuffer m => MonadCommentBuffer (ComponentsT m) where
  startComment = lift startComment
  appendComment = lift . appendComment
  finishComment = lift finishComment
  addComment = lift . addComment
  saveCommentsAsPreceeding = lift . saveCommentsAsPreceeding
  clearComments = lift clearComments

instance MonadComments m => MonadComments (ComponentsT m) where
  preceedingComments = lift . preceedingComments

instance MonadCont m => MonadCont (ComponentsT m) where
  callCC f =
    ComponentsT (callCC (\c -> unpackComponentsT (f (ComponentsT . c))))

instance (Error e, MonadError e m) => MonadError e (ComponentsT m) where
  throwError = lift . throwError
  m `catchError` h =
    ComponentsT (unpackComponentsT m `catchError` (unpackComponentsT . h))

instance MonadGenpos m => MonadGenpos (ComponentsT m) where
  point = lift . point
  filename = lift . filename

instance MonadGensym m => MonadGensym (ComponentsT m) where
  symbol = lift . symbol
  unique = lift . unique

instance MonadKeywords p t m => MonadKeywords p t (ComponentsT m) where
  mkKeyword p = lift . mkKeyword p

instance MonadMessages msg m => MonadMessages msg (ComponentsT m) where
  message = lift . message

instance MonadLoader path info m => MonadLoader path info (ComponentsT m) where
  load = lift . load

instance MonadPositions m => MonadPositions (ComponentsT m) where
  pointInfo = lift . pointInfo
  fileInfo = lift . fileInfo

instance MonadSourceFiles m => MonadSourceFiles (ComponentsT m) where
  sourceFile = lift . sourceFile

instance MonadSourceBuffer m => MonadSourceBuffer (ComponentsT m) where
  linebreak = lift . linebreak
  startFile fname = lift . startFile fname
  finishFile = lift finishFile

instance MonadState s m => MonadState s (ComponentsT m) where
  get = lift get
  put = lift . put

instance MonadSymbols m => MonadSymbols (ComponentsT m) where
  nullSym = lift nullSym
  allNames = lift allNames
  allSyms = lift allSyms
  name = lift . name

instance MonadReader r m => MonadReader r (ComponentsT m) where
  ask = lift ask
  local f = mapComponentsT (local f)

instance MonadWriter w m => MonadWriter w (ComponentsT m) where
  tell = lift . tell
  listen = mapComponentsT listen
  pass = mapComponentsT pass

instance MonadPlus m => MonadPlus (ComponentsT m) where
  mzero = lift mzero
  mplus s1 s2 = ComponentsT (mplus (unpackComponentsT s1)
                                   (unpackComponentsT s2))

instance MonadFix m => MonadFix (ComponentsT m) where
  mfix f = ComponentsT (mfix (unpackComponentsT . f))
