/-  *food
/+  *test, food-utils, food-init
::
|%
:: Encode a recipe id as a hex string (@t)
++  test-encode-recp-id
  ;:  weld
    %+  expect-eq  !>((en:recp-id:food-utils 0x1111.2222.3333.cdef))  !>('111122223333cdef')
    %+  expect-eq  !>((en:recp-id:food-utils 0x8034.5cb2.37c3.4773))  !>('80345cb237c34773')
  ==

++  test-encode-recp-path
  =|  =recipe
  =.  id.recipe  0x1111.2222.3333.cdef
  ;:  weld
    %+  expect-eq
      !>  %-  en:recp-path:food-utils  recipe
      !>  "/apps/recipe-book/recipes/111122223333cdef"
    %+  expect-eq
      !>  %-  ~(en recp-path:food-utils "/apps/recipe-book/pals/~sampel-palnet")  recipe
      !>  "/apps/recipe-book/pals/~sampel-palnet/recipes/111122223333cdef"
  ==
::
++  test-parse-recipe-link
  ;:  weld
    :: ID only
    %+  expect-eq
      !>  `parse-result:food-utils`[~ [~sampel-palnet ~]]
      !>  %-  parse-recipe-link:food-utils  "~sampel-palnet"
    :: ID with path
    %+  expect-eq
      !>  `parse-result:food-utils`[~ [~sampel-palnet [~ 0x1234.abcd]]]
      !>  %-  parse-recipe-link:food-utils  "~sampel-palnet/1234abcd"
    :: ID with path including some slug
    %+  expect-eq
      !>  `parse-result:food-utils`[~ [~sampel-palnet [~ 0x1234.abcd]]]
      !>  %-  parse-recipe-link:food-utils  "~sampel-palnet/1234abcd/some-slug"
    :: Nonsense
    %+  expect-eq
      !>  `parse-result:food-utils`[~]
      !>  %-  parse-recipe-link:food-utils  "fjwekf"
  ==
::
++  test-normalize-ingredient
  =/  test-cases=(list [=ingredient normalized-amount=@rs])  :~
        :: Salt, density 2.2 g/ml, mass 100g
        :-  [food-id=239 amount=[.2 %ct]]  .2
        :-  [food-id=239 amount=[.100 %g]]  .1
        :-  [food-id=239 amount=[.1.5 %lbs]]  .6.81
        :-  [food-id=239 amount=[.3 %oz]]  .0.850485
        :-  [food-id=239 amount=[.100 %ml]]  .2.20
        :-  [food-id=239 amount=[.0.25 %cups]]  .1.375
        :-  [food-id=239 amount=[.4 %tsp]]  .0.44
        :-  [food-id=239 amount=[.1.3333333 %tbsp]]  .0.44
        :-  [food-id=239 amount=[.2.6666666 %fl-oz]]  .0.44
        :: Onions, no density, mass 220g
        :-  [food-id=239 amount=[.2 %ct]]  .2
        :-  [food-id=239 amount=[.100 %g]]  .0.454545
        :-  [food-id=239 amount=[.1.5 %lbs]]  .3.095454
        :-  [food-id=239 amount=[.3 %oz]]  .0.38658
        :-  [food-id=239 amount=[.100 %ml]]  .0.454545
        :-  [food-id=239 amount=[.0.25 %cups]]  .1.13636
        :-  [food-id=239 amount=[.4 %tsp]]  .0.090909
        :-  [food-id=239 amount=[.1.333 %tbsp]]  .0.090909
        :-  [food-id=239 amount=[.2.666 %fl-oz]]  .0.090909
      ==
  %-  zing  %+  turn  test-cases
    |=  [i=ingredient expected-amount=@rs]
    ^-  tang
    =/  result=normalized-ingredient:food-utils
        (normalize-ingredient:food-utils i `foods`(molt (turn initial-foods:food-init |=(f=food `(pair food-id food)`[id.f f]))))
    %-  expect-eq-float  :+
      expected-amount
      amount:result
      .0.00001
--
