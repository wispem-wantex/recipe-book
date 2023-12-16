/-  *food
/+  fmt
::
|%
::
:: Given a food, produce its URL path
++  url-path-for
  |=  [=food]
  ^-  tape
  (weld "/apps/server/ingredients/" (scow %ud id:food))
::
:: Given a recipe, produce its URL path
++  url-path-for-recipe
  |=  [=recipe]
  ^-  tape
  (weld "/apps/server/recipes/" (trip (en:base16:mimes:html [8 id:recipe])))
::
:: Given a food, generate Sail HTML for a form to edit it
++  form-for
  |=  [=food]
  ^-  manx  :: sail HTML node
  ;form(action (url-path-for food), method "POST")
    ;div(class "labelled-input")
      ;label: Name
      ;input(type "text", name "name", value (trip name:food));
    ==
    ;div(class "labelled-input")
      ;label: Calories
      ;input(type "text", name "calories", value (format:fmt calories:food));
    ==
    ;div(class "labelled-input")
      ;label: Carbs
      ;input(type "text", name "carbs", value (format:fmt carbs:food));
    ==
    ;div(class "labelled-input")
      ;label: Protein
      ;input(type "text", name "protein", value (format:fmt protein:food));
    ==
    ;div(class "labelled-input")
      ;label: Fat
      ;input(type "text", name "fat", value (format:fmt fat:food));
    ==
    ;div(class "labelled-input")
      ;label: Sugar
      ;input(type "text", name "sugar", value (format:fmt sugar:food));
    ==
    ;input(type "submit", value "Submit");
  ==
::
:: Parse a form-encoded body or query string
++  parse-form-body
  |=  [req=request:http]
  ^-  (unit (list [key=@t value=@t]))
  ?~  body.req
    ~
  (rush q.u.body.req yquy:de-purl:html)
::
++  get-form-value
  |=  [haystack=(list [key=@t value=@t]) needle=@t]
  ^-  (unit @t)
  ?~  haystack
    ~
  ?:  =(key:(head haystack) needle)
    [~ value:(head haystack)]
  $(haystack (tail haystack))
::
:: Parse a food body
++  parse-food
  |=  [data=(list [key=@t value=@t])]
  ^-  food
  =/  find-item  |=(val=@t (need (get-form-value data val)))
  :*  id=0
      name=(find-item 'name')
      calories=(unformat:fmt (find-item 'calories'))
      carbs=(unformat:fmt (find-item 'carbs'))
      protein=(unformat:fmt (find-item 'protein'))
      fat=(unformat:fmt (find-item 'fat'))
      sugar=(unformat:fmt (find-item 'sugar'))
      alcohol=.0.0
      water=.0.0
      potassium=.0.0
      sodium=.0.0
      calcium=.0.0
      magnesium=.0.0
      phosphorus=.0.0
      iron=.0.0
      zinc=.0.0
      mass=.100.0
      density=.-1.0
      price=.0.0
      cook-ratio=.0
  ==
::
:: Convert an ingredient to a pair [amount=@rs =food]
+$  normalized-ingredient  [amount=@rs =food]
++  normalize-ingredient
  |=  [i=ingredient all-foods=foods]
  ^-  normalized-ingredient
  =/  base-food  (need (~(get by all-foods) food-id:i))
  ?-  units.amount.i
    %g     [amount=(div:rs -:amount:i mass:base-food) food=base-food]
    %ct    [amount=-:amount:i food=base-food]
  ==
::
:: Compute the nutrition for an ingredient
::++  ingredient-to-food
::  |=  [i=ingredient all-foods=foods]
::  ^-  food

::
:: Compute the totals for a recipe
++  recipe-to-food
  |=  [=recipe all-foods=foods]
  ^-  food
  =/  all-ingredients  %+  turn
        ingredients:recipe
      |=(i=ingredient (normalize-ingredient i all-foods))
      ::(curr normalize-ingredient all-foods)
  :*  id=0
      name=name:recipe
      calories=(roll (turn all-ingredients |=(n=normalized-ingredient (mul:rs amount:n calories:food:n))) add:rs)
      carbs=(roll (turn all-ingredients |=(n=normalized-ingredient (mul:rs amount:n carbs:food:n))) add:rs)
      protein=(roll (turn all-ingredients |=(n=normalized-ingredient (mul:rs amount:n protein:food:n))) add:rs)
      fat=(roll (turn all-ingredients |=(n=normalized-ingredient (mul:rs amount:n fat:food:n))) add:rs)
      sugar=(roll (turn all-ingredients |=(n=normalized-ingredient (mul:rs amount:n sugar:food:n))) add:rs)
      alcohol=.0.0
      water=.0.0
      potassium=.0.0
      sodium=.0.0
      calcium=.0.0
      magnesium=.0.0
      phosphorus=.0.0
      iron=.0.0
      zinc=.0.0
      mass=.100.0
      density=.-1.0
      price=.0.0
      cook-ratio=.0
  ==
--
