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

-- | A module implementing a data type for proof scripts.
module Language.Salt.Core.Proofs.ProofScript(
       ProofScriptElem(..),
       ProofScript,
       runScriptElem,
       runScript
       ) where

import Control.Monad.Proof.Class
import Data.Default
import Data.Hashable
import Data.Pos
import Language.Salt.Core.Syntax

-- XXX Maybe encapsulate this more, make it just a monoid on the outside?
type ProofScript sym = [ProofScriptElem sym]

-- | An element in a proof script.  Each of these corresponds to one
-- of the five axioms for Salt's intuitionistic predicate logic.
data ProofScriptElem sym =
  -- |
  --   -------------
  --    Env, P |- P
    Exact {
      -- | The name of the proposition in the truth environment.
      exactName :: !sym,
      -- | The position of this script element.
      exactPos :: !Pos
    }
  -- |   Env, P |- Q
  --   ---------------
  --    Env |- P -> Q
  | Intro {
      -- | The name under which to introduce the new proposition.
      introName :: !sym,
      -- | The position of this script element.
      introPos :: !Pos
    }
  -- |  Env, x_1 : T_1 ... x_n : T_n |- P
  --   -----------------------------------
  --     Env |- forall (pattern) : T. P
  | IntroVars {
      -- | The position of this script element.
      introVarsPos :: !Pos
    }
  -- |  Env |- P -> Q    Env |- P
  --   ---------------------------
  --            Env |- Q
  | Cut {
      -- | The cut proposition (what must imply the current goal, and
      -- what the envirenment must prove).
      cutProp :: Term sym sym,
      -- | The position of this script element.
      cutPos :: !Pos
    }
  -- |  Env |- forall (pattern) : T. P   Env |- V : T
  --   -----------------------------------------------
  --                 Env |- [V/(pattern)]P
  | Apply {
      -- | The proposition to apply.
      applyProp :: Term sym sym,
      -- | The argument to the proposition.
      applyArg :: Term sym sym,
      -- | The position of this script element.
      applyPos :: !Pos
    }
  deriving (Ord, Eq)

-- | Perform the action represented by a proof script element inside a
-- proof monad.
runScriptElem :: MonadProof sym m => ProofScriptElem sym -> m ()
runScriptElem Exact { exactName = name, exactPos = p } = exact p name
runScriptElem Intro { introName = name, introPos = p } = intro p name
runScriptElem IntroVars { introVarsPos = p } = introVars p
runScriptElem Cut { cutProp = prop, cutPos = p } = cut p prop
runScriptElem Apply { applyProp = prop, applyArg = arg, applyPos = p } =
  apply p prop arg

-- | Perform the actions represented by a proof script inside a proof monad.
runScript :: MonadProof sym m => ProofScript sym -> m ()
runScript = mapM_ runScriptElem

instance Position (ProofScriptElem sym) where
  pos Exact { exactPos = p } = p
  pos Intro { introPos = p } = p
  pos IntroVars { introVarsPos = p } = p
  pos Cut { cutPos = p } = p
  pos Apply { applyPos = p } = p

instance (Default sym, Hashable sym) => Hashable (ProofScriptElem sym) where
  hashWithSalt s Exact { exactName = name, exactPos = p } =
    s `hashWithSalt` (1 :: Int) `hashWithSalt` name `hashWithSalt` p
  hashWithSalt s Intro { introName = name, introPos = p } =
    s `hashWithSalt` (2 :: Int) `hashWithSalt` name `hashWithSalt` p
  hashWithSalt s IntroVars { introVarsPos = p } =
    s `hashWithSalt` (3 :: Int) `hashWithSalt` p
  hashWithSalt s Cut { cutProp = prop, cutPos = p } =
    s `hashWithSalt` (4 :: Int) `hashWithSalt` prop `hashWithSalt` p
  hashWithSalt s Apply { applyProp = prop, applyArg = arg, applyPos = p } =
    s `hashWithSalt` (5 :: Int) `hashWithSalt`
    prop `hashWithSalt` arg `hashWithSalt` p