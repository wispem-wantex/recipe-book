/-  *food
/+  *test, food-init, *food-utils
::
=>
|%
  ++  sample-state-0
    ^-  state:v0
    =/  initial-foods=(list food:v0)  :~
        [id=37 name='onion' calories=.88.0 carbs=.20.0 protein=.2.0 fat=.0.0 sugar=.9.0 alcohol=.0.0 water=.0.0 potassium=.0.312 sodium=.0.008 calcium=.0.023 magnesium=.0.01 phosphorus=.0.029 iron=.0.0002 zinc=.0.0002 mass=.220.0 density=.-1.0 price=.17.0 cook-ratio=.0.62]
        [id=92 name='butter' calories=.714.0 carbs=.0.0 protein=.1.0 fat=.81.0 sugar=.0.0 alcohol=.0.0 water=.0.0 potassium=.0.02 sodium=.0.7 calcium=.0.024 magnesium=.0.002 phosphorus=.0.024 iron=.0.0 zinc=.0.0001 mass=.100.0 density=.0.911 price=.95.0 cook-ratio=.0]
        [id=239 name='salt' calories=.0.0 carbs=.0.0 protein=.0.0 fat=.0.0 sugar=.0.0 alcohol=.0.0 water=.0.0 potassium=.0.0 sodium=.40.0 calcium=.0.0 magnesium=.0.0 phosphorus=.0.0 iron=.0.0 zinc=.0.0 mass=.100.0 density=.2.2 price=.17.0 cook-ratio=.0]
        [id=245 name='chili flakes' calories=.307.0 carbs=.28.0 protein=.12.0 fat=.16.0 sugar=.10.0 alcohol=.0.0 water=.0.0 potassium=.1.9 sodium=.0.03 calcium=.0.0 magnesium=.0.0 phosphorus=.0.0 iron=.0.0 zinc=.0.0 mass=.100.0 density=.0.357 price=.300.0 cook-ratio=.0]
        [id=3.000 name='chicken stock' calories=.22 carbs=.0.4 protein=.2.2 fat=.1.2 sugar=.0.2 alcohol=.0.0 water=.0.0 potassium=.0.105 sodium=.0.140 calcium=.0.003 magnesium=.0.0 phosphorus=.0.0 iron=.0.0002 zinc=.0.0 mass=.100.0 density=.1.0 price=.0.0 cook-ratio=.1.0]
      ==
    :*  %0
        (molt (turn initial-foods |=(f=food:v0 `(pair food-id:v0 food:v0)`[id.f f])))
        %-  molt  :~
          =/  id=recipe-id:v0  (de:recp-id 'de32bc69c2e6b69f')
          :-  id
          ^-  recipe:v0
          :: Create a default recipe as a welcome
          =/  ingredients  ^-  (list ingredient:v0)
            :~  [food-id=37 amount=[rs=.2 units=%ct]]
                [food-id=92 amount=[rs=.30 units=%g]]
                [food-id=239 amount=[rs=.2 units=%g]]
                [food-id=245 amount=[rs=.5 units=%g]]
                [food-id=3.000 amount=[rs=.1000 units=%g]]
            ==
          =/  instrs  ^-  (list @t)
            :~  'In large pot, heat butter and oil.  Cook onions to 1/2 cooked (translucent and soft, starting to turn golden-brown)'
                'Add garlic, cook 1-2 minutes'
                'add tomatoes and chicken broth, bring to a simmer'
                'salt and season the soup, tasting until seasonings are right'
                'cut chicken into bite-sized pieces, add to soup and boil until fully cooked'
                'add pasta and boil until it is cooked "al dente"; add more stock as needed'
                'add half the cheese and stir it into the soup'
                'sprinkle remaining cheese on top and serve'
            ==
          :*  id=id
              name='Chicken Parmigiana Soup'
              ingredients=ingredients
              instructions=instrs
              provenance=[~ [~wispem-wantex id]]
          ==
          ::
          :: The help recipe
          :-  help-recipe-id:food-init
          ^-  recipe:v0
          =/  ingredients  ^-  (list ingredient:v0)
            :~  [food-id=44 amount=[rs=.300 units=%g]]
                [food-id=10 amount=[rs=.200 units=%g]]
            ==
          :*  id=help-recipe-id:food-init
              name='How to use this app :)'
              ingredients=ingredients
              instructions=help-instrs:food-init
              provenance=~
          ==
        ==
    ==
--
::
|%
++  test-state-0-to-1
  =/  state0=state:v0  sample-state-0
  =/  new-state=state:v1  (from-v0:v1 state0)
  ;:  weld
    :: All base foods should be identical
    %+  expect-eq  !>(foods.new-state)  !>(foods.state0)
    %+  expect-eq  !>(~(key by recipes.new-state))  !>(~(key by recipes.state0))
    %+  expect-eq  !>(name:(~(got by recipes.new-state) help-recipe-id:food-init))
                   !>(name:(~(got by recipes.state0) help-recipe-id:food-init))
    %+  expect-eq  !>(id:(~(got by recipes.new-state) help-recipe-id:food-init))
                   !>(id:(~(got by recipes.state0) help-recipe-id:food-init))
    %+  expect-eq  !>(ingredients:(~(got by recipes.new-state) help-recipe-id:food-init))
                   !>(ingredients:(~(got by recipes.state0) help-recipe-id:food-init))
    %+  expect-eq  !>('')  !>(blurb:(~(got by recipes.new-state) help-recipe-id:food-init))
  ==
++  test-state-1-to-2
  =/  state0=state:v0  sample-state-0
  =/  state1=state:v1  (from-v0:v1 state0)
  =/  state2=state:v2  (from-v1:v2 state1)
  ;:  weld
    :: ".-1" default densities should be converted to empty units
    %+  expect-eq  !>(`(unit @rs)`[~])  !>(density:(~(got by foods.state2) 37))
    :: non-default densities should become units of themselves
    %+  expect-eq  !>(`(unit @rs)`[~ .0.911])  !>(density:(~(got by foods.state2) 92))
    %+  expect-eq  !>(`(unit @rs)`[~ .1])  !>(density:(~(got by foods.state2) 3.000))
    ::
    :: Recipes should have a comments field
    %+  expect-eq  !>(`(list [author=@p posted-at=@da txt=@t])`[~])  !>(comments:(~(got by recipes.state2) (de:recp-id 'de32bc69c2e6b69f')))
    :: Recipes should have a last-modified-at field
    %+  expect-eq  !>(`(unit @da)`[~])  !>(last-modified-at:(~(got by recipes.state2) (de:recp-id 'de32bc69c2e6b69f')))
  ==
--
