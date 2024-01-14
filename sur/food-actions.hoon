/-  *food
::
|%
+$  action
  $%  [%req original-eyre-id=@ta =req]
      [%resp original-eyre-id=@ta =resp]
  ==

+$  req
  $%  [%list-recipes ~]
      [%get-recipe =recipe-id]
      [%copy-recipe =recipe-id]
  ==
+$  resp
  $%  [%list-recipes state=versioned-state]
      [%get-recipe =recipe-id state=versioned-state]
      [%copy-recipe =recipe-id state=versioned-state]
  ==
--
