|%
::
:: Split `txt` using `sep` as a separator, returning a list of tapes
++  split
  |=  [txt=tape sep=tape]
  ^-  (list tape)
  :: If it's empty, return [~]
  ?~  txt
    ~
  ::
  =/  i  (fall (find sep txt) (lent txt))
  :-  (scag i `tape`txt)                      :: the part before the sep
  $(txt (slag (add (lent sep) i) `tape`txt))  :: keep splitting the part after the sep
::
:: ++slugify:
:: Turn a tape into URL-safe slug format
::
:: "Some Text We'd Like To Slugify!!!!" -> "some-text-wed-like-to-slugify"
++  slugify
  |=  [s=tape]
  ^-  tape
  %-  roll  :_
    |=([a=tape b=tape] (weld b a))
  %+  scan  s
  %-  star  ;~  pose
    (cook |=(x=@t (cass (trip x))) mixed-case-symbol)
    (cold "-" ace)
    (cold "" next)
  ==
--
