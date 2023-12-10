|%
++  format
  |=  [num=@rs]
  ^-  tape
  (slag 2 (scow %s (need (toi:rs num))))
++  unformat
  |=  [str=@t]
  ^-  @rs
  (scan (trip str) royl-rs:so)
--
