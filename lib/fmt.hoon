|%
++  format
  |=  [num=@rs]
  ^-  tape
  (slag 1 (scow %rs num))
++  unformat
  |=  [str=@t]
  ^-  @rs
  (scan (trip str) royl-rs:so)
--
