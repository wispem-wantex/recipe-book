/-  v0=state-versions-v0, v1=state-versions-v1, v2=state-versions-v2
::
=+  v2
|%
::
:: App state
+$  versioned-state
  $%  state:v0
      state:v1
      state:v2
  ==
+$  state-0  state:v0
+$  state-1  state:v1
+$  state-2  state:v2
::
++  load-state
  |=  [old=versioned-state]
  ^-  state
  |-  :: Update state to latest version if needed
    ?-  -.old
      %2  old       :: Up to date
      %1  $(old (from-v1:v2 old))
      %0  $(old (from-v0:v1 old))
    ==
--
