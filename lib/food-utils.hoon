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
:: Parse a food body
++  parse-food
  |=  [data=(list [key=@t value=@t])]
  ^-  food
  =/  find-item
    |=  [item=@t]
    ^-  @t
    ?~  data
      !!  :: Not our problem
    ?:  =(key:(head data) item)
      value:(head data)
    $(data (tail data))
  ::
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
--
