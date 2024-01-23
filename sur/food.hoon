/-  v0=state-versions-v0, v1=state-versions-v1
::
=+  v1
|%
::
:: App state
+$  versioned-state
  $%  state:v0
      state:v1
  ==
+$  state-0  state:v0
+$  state-1  state:v1
::
++  load-state
  |=  [old=versioned-state]
  ^-  state
  |-  :: Update state to latest version if needed
    ?-  -.old
      %1  old       :: Up to date
      %0  $(old (from-v0:v1 old))
    ==
--
