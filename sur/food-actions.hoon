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
  ==
+$  resp
  $%  [%list-recipes =recipes]
      [%get-recipe =recipe-id state=versioned-state]
  ==
--
