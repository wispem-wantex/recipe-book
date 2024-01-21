/-  *food
/+  *test, food-utils
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
--
