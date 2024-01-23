/-  *food
/+  *test, food-init, *food-utils
::
=>
|%
  ++  sample-state-0
    ^-  state:v0
    :*  %0
        (molt (turn initial-foods:food-init |=(f=food `(pair food-id food)`[id.f f])))
        %-  molt  :~
          =/  id=recipe-id  (de:recp-id 'de32bc69c2e6b69f')
          :-  id
          ^-  recipe:v0
          :: Create a default recipe as a welcome
          =/  ingredients  ^-  (list ingredient)
            :~  [food-id=37 amount=[rs=.2 units=%ct]]
                [food-id=92 amount=[rs=.30 units=%g]]
                [food-id=20 amount=[rs=.30 units=%g]]
                [food-id=41 amount=[rs=.40 units=%g]]
                [food-id=121 amount=[rs=.800 units=%g]]
                [food-id=75 amount=[rs=.450 units=%g]]
                [food-id=6 amount=[rs=.300 units=%g]]
                [food-id=98 amount=[rs=.150 units=%g]]
                [food-id=101 amount=[rs=.150 units=%g]]
                [food-id=239 amount=[rs=.2 units=%g]]
                [food-id=241 amount=[rs=.2 units=%g]]
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
          =/  ingredients  ^-  (list ingredient)
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
--
