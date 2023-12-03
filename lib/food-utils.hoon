/-  *food
/+  fmt
::
|%
::
:: Given a food, produce its URL path
++  url-path-for
  |=  [=food]
  ^-  tape
  (weld "/apps/server/ingredients/" (scow %ud id:food))
--
