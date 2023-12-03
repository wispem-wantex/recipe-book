|%
+$  score  [defend=@ud invade=@ud]
+$  invader  [name=@t image-url=@t issuer=@p]
+$  team  (list invader)
+$  profile  [score team]
+$  profiles  (map name=@p profile)
+$  action
  $%  [%hiscore newscore=@ud]
      [%invaded name=@p]
  ==
+$  update
  $%  [%profile-update =profile]
      [%invasion-success name=@p]
  ==
--