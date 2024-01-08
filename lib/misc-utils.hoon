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
  :-  (scag i `tape`txt) :: the part before the sep
  $(txt (slag (add (lent sep) i) `tape`txt)) :: keep splitting the part after the sep
--
