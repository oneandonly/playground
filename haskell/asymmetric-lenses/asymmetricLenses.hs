{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE KindSignatures #-}
--
-- See "Asymmetric Lenses" by Tony Morris
--   http://dl.dropbox.com/u/7810909/media/doc/lenses.pdf
--

import Control.Arrow ((>>>))

import Person

modifyAge :: (Int -> Int) -> Person -> Person
modifyAge f p = p {age = f (age p)}

modifyAddress :: (Address -> Address) -> Person -> Person
modifyAddress f p = p {address = f (address p)}

getPersonStreet :: Person -> String
getPersonStreet = address >>> street

setPersonStreet :: Person -> String -> Person
setPersonStreet person street = person {address = (address person) {street = street}}

data Lens record field = Lens
  { get :: record -> field
  , set :: (record, field) -> record
  }

ageL :: Lens Person Int
ageL = Lens 
  { get = age
  , set = \(p, a) -> p {age = a}
  }

modify :: Lens record field -> (field -> field) -> record -> record
modify l f p = (set l) (p, (f ((get l) p)))

addressL :: Lens Person Address
addressL = Lens
  { get = address
  , set = \(p, a) -> p {address = a}
  }

streetL :: Lens Address String
streetL = Lens
  { get = street
  , set = \(p, a) -> p {street = a}
  }

stateL :: Lens Address String
stateL = Lens
  { get = state
  , set = \(p, a) -> p {state = a}
  }

composeL :: Lens b c -> Lens a b -> Lens a c
composeL l1 l2 = Lens
  { get = (get l1) . (get l2)
  , set = \(r, f) -> (set l2) (r, (set l1) ((get l2) r, f))
  }

idL :: Lens a a
idL = Lens
  { get = Prelude.id
  , set = \(a, _) -> a
  }

data Category (cat :: * -> * -> *) = Category
  { id :: forall a. cat a a
  , compose :: forall a b c. cat b c -> cat a b -> cat a c
  }

lensCat = Category
  { Main.id = idL
  , compose = composeL
  }

personStreetL = streetL `composeL` addressL
streetOfPerson = get personStreetL person
newPerson = set personStreetL (person, "Elizabeth Street")

foldLens :: [Lens a a] -> Lens a a
foldLens xs = foldr composeL idL xs

--
-- from 5.1 Lens Product Morphism
--
(***) :: Lens r1 f1 -> Lens r2 f2 -> Lens (r1, r2) (f1, f2)
(***) l1 l2 = Lens
  { get = \r -> (get l1 (fst r), get l2 (snd r))
  , set = \(r, f) -> (set l1 ((fst r), (fst f))
                     ,set l2 ((snd r), (snd f))
                     )
  }

eg1 = get (personStreetL *** ageL) (person1, person2)

eg2 = set (personStreetL *** ageL) ((person1, person2), ("Ann Street", 33))
