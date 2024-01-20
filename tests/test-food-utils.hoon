/-  *food
/+  *test, food-utils
::
|%
++  test-url-path-for-recipe
  =|  =recipe
  =.  id.recipe  0x1111.2222.3333.cdef
  =/  url-helper  url-path-for-recipe:food-utils
  ;:  weld
    %+  expect-eq
      !>  %-  url-helper  recipe
      !>  "/apps/recipe-book/recipes/111122223333cdef"
    %+  expect-eq
      !>  %-  url-helper(base-path "/apps/recipe-book/pals/~sampel-palnet")  recipe
      !>  "/apps/recipe-book/pals/~sampel-palnet/recipes/111122223333cdef"
  ==
--
