/-  *food
/+  *test, misc-utils
::
|%
:: Slugify should turn strings into URL-safe slugs
++  test-slugify
  ;:  weld
    %+  expect-eq
      !>("some-text-wed-like-to-slugify")
      !>((slugify:misc-utils "Some Text We'd Like To Slugify!!!"))
    :: TODO =>
    ::%+  expect-eq
    ::  !>("how-to-use-this-app")
    ::  !>((slugify:misc-utils "How to use this app :)"))
  ==
--
