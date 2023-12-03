/-  *slam
|%
++  dejs-action
  =,  dejs:format
  |=  jon=json
  ^-  action
  %.  jon
  %-  of
  :~  hiscore+ni
      invaded+(se %p)
  ==
++  enjs-profiles
  =,  enjs:format
  |=  profs=profiles
  ^-  json
  %-  pairs
  %+  turn 
    %~  tap  by  profs
  |=  prof=[@p [[@ud @ud] (list [@t @t @p])]]
  :-  `@t`(scot %p -.prof)
  :-  %a
  :~ 
    (numb +<-:prof)
    (numb +<+.prof)
    :-  %a
    %+  turn
      +>.prof
    |=  gora=[@t @t @p]
    :-  %a
    :~
        [%s -.gora]
        [%s +<.gora]
        [%s (scot %p +>.gora)]
    ==
  ==
--