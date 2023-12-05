/-  *food
/+  default-agent, dbug, schooner, server, *food-init, fmt, *food-utils
::
/*  styles-css  %css  /app/styles/css
::
|%
+$  versioned-state
  $%  state-0
  ==
+$  state-0  [%0 =foods =recipes]
::
++  blank-state-0
  :*  %0
      (molt (turn initial-foods |=(f=food `(pair food-id food)`[id.f f])))
      =/  id  q:(need (de:base16:mimes:html 'de32bc69c2e6b69f'))
      %+  ~(put by *recipes)
        id
      ^-  recipe
      :*  id=id
          name='My First Recipe'
          ingredients=:~(`ingredient`[44 [.100 %g]] `ingredient`[75 [.200 %g]] `ingredient`[252 [.3 %g]])
          instructions=:~('Add the beef' 'add the chicken' 'spice it with cinnamon')
      ==
  ==
::
+$  card  card:agent:gall
--
::
:: All the boilerplate gibberish
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this) bowl)
::
:: Register this agent for handling incoming HTTP requests at the path /apps/server.   This
:: allows us to serve a web front end without needing a "glob".
::
:: `desk.docket-0` will specify that /apps/server is the entrypoint for this app, so it will
:: take us to that path if you click this desk's tile in landscape.
++  on-init
  ^-  (quip card _this)
  :_  this(state blank-state-0)  :: Initialize to a new blank state
  :~
    [%pass /eyre/connect %arvo %e %connect [~ /apps/server] %food]
  ==
::
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state old-state)
  |-
    ?-  -.old
      %0  `this(state old)       :: drop it and reinit the state
    ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  |^
  ?>  =(src.bowl our.bowl)
  ?+  mark  (on-poke:def mark vase)
      %handle-http-request
    =^  cards  state
      (handle-http !<([@ta =inbound-request:eyre] vase))
    [cards this]
  ==
  ::
  ++  handle-http
    |=  [eyre-id=@ta =inbound-request:eyre]
    ^-  (quip card _state)
    =/  ,request-line:server
      (parse-request-line:server url.request.inbound-request)
    =+  send=(cury response:schooner eyre-id)
    ?.  authenticated.inbound-request
      :_  state  %-  send  [302 ~ [%login-redirect '/apps/server']]
    ::
    |^
      ?+  site  [(send [404 ~ [%stock ~]]) state]
          [%apps %server ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          =/  sailhtml
            ;html
              ;body
                ;h1: Recipe book
                ;p: Check out:
                ;ul
                  ;li
                    ;a(href "/apps/server/recipes"): Recipes
                  ==
                  ;li
                    ;a(href "/apps/server/ingredients"): Ingredients
                  ==
                ==
              ==
            ==
          :_  state
          %-  send  [200 ~ [%html (crip (en-xml:html sailhtml))]]
        ==
        ::
          [%apps %server %static *]
        ?.  ?=  %'GET'  method.request.inbound-request
          [(send [405 ~ [%stock ~]]) state]
        [(send (handle-static (slag 3 `(list @ta)`site))) state]  :: Delegate to static handler
        ::
          [%apps %server %ingredients ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          =/  sailhtml
            ;html
              ;body
                ;h1: Ingredients
                ;table
                  ;thead
                    ;*  %+  turn  `(list tape)`["Name" "Cals" "Carbs" "Protein" "Fat" "Sugar" ~]
                      |=  [labl=tape]
                      ;th: {labl}
                  ==
                  ;tbody
                    ;*  %+  turn  ~(val by foods:state)
                      |=  [=food]
                      ;tr
                        ;td
                          ;a(href (url-path-for food)): {(trip name:food)}
                        ==
                        ;td: {(format:fmt calories:food)}
                        ;td: {(format:fmt carbs:food)}
                        ;td: {(format:fmt protein:food)}
                        ;td: {(format:fmt fat:food)}
                        ;td: {(format:fmt sugar:food)}
                      ==
                  ==
                ==
              ==
            ==
          :_  state
          %-  send  [200 ~ [%html (crip (en-xml:html sailhtml))]]
        ==
        ::
          [%apps %server %ingredients @ ~]
        =/  the-id  +:(scan (trip (snag 3 `(list @t)`site)) bisk:so)
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          ::
          =+  (~(get by foods:state) the-id)                :: Find the recipe
          ?~  -  :_  state  [(send [404 ~ [%stock ~]])]     :: 404 if it's not found
          =/  food  (need -)                                :: First item from the found list
          =/  sailhtml
            ;html
              ;head
                ;link(rel "stylesheet", href "/apps/server/static/styles/css");
              ==
              ;body
                ;h1: {(trip name:food)}
                ;+  (form-for food)
              ==
            ==
          :_  state
          %-  send  [200 ~ [%html (crip (en-xml:html sailhtml))]]
          ::
            %'POST'
          =/  data  (parse-form-body request.inbound-request)
          ?~  data
            :_  state  %-  send  [400 ~ [%plain "No data received"]]
          :-
            %-  send  [302 ~ [%redirect '/apps/server/ingredients']]
          %=  state
            foods  %+  ~(put by foods)
              the-id
            =/  new-food  (parse-food (need data))
            new-food(id the-id)  :: This is kind of gross(?)
          ==
        ==
        ::
          [%apps %server %recipes ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          =/  sailhtml
            ;html
              ;body
                ;h1: Recipes
                ;input(type "submit", value "New recipe", onclick "window.location.pathname = '/apps/server/recipes/new'");
                ;ul
                  ;*  %+  turn  ~(val by recipes:state)
                    |=  [=recipe]
                    ;li
                      ;a(href (url-path-for-recipe recipe)): {(trip name:recipe)}
                    ==
                ==
              ==
            ==
          :_  state
          %-  send  [200 ~ [%html (crip (en-xml:html sailhtml))]]
        ==
        ::
          [%apps %server %recipes %new ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          =/  sailhtml
            ;html
              ;body
                ;h1: New Recipe
                ;form(method "POST")
                  ;input(type "text", name "name");
                  ;input(type "submit", value "Create");
                ==
              ==
            ==
          :_  state
          %-  send  [200 ~ [%html (crip (en-xml:html sailhtml))]]
          ::
            %'POST'
          =/  data  (parse-form-body request.inbound-request)
          ?~  data
            :_  state  %-  send  [400 ~ [%plain "No data received"]]
          =/  name  (need (get-form-value (need data) 'name'))
          ?~  name
            :_  state  %-  send  [400 ~ [%plain "'name' field is required"]]
          =/  =recipe  *recipe
          =.  name.recipe  name
          =.  id.recipe  (mod eny.bowl 0xffff.ffff.ffff.ffff)
          :-
            %-  send  [302 ~ [%redirect (crip (url-path-for-recipe recipe))]]
          %=  state
            recipes  (~(put by recipes:state) id.recipe recipe)
          ==
        ==
        ::
          [%apps %server %recipes @ ~]
        =/  the-id  q:(need (de:base16:mimes:html (snag 3 `(list @t)`site)))
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          ::
          =+  (~(get by recipes:state) the-id)                :: Find the recipe
          ?~  -  :_  state  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
          =/  recipe  (need -)                                :: First item from the found list
          =/  sailhtml
            ;html
              ;head
                ;link(rel "stylesheet", href "/apps/server/static/styles/css");
              ==
              ;body
                ;h1: {(trip name:recipe)}
                ;form(action (weld (url-path-for-recipe recipe) "/rename"), method "POST")
                  ;input(type "text", name "new-name");
                  ;input(type "submit", value "Rename recipe");
                ==
                ;table
                  ;thead
                    ;th: Amount
                    ;th: Ingredient
                    ;th: Calories
                    ;th: Carbs
                    ;th: Protein
                    ;th: Fat
                    ;th: Sugar
                  ==
                  ;tbody
                    ;*  %+  turn  ingredients:recipe
                      |=  [=ingredient]
                      =/  base-food  (need (~(get by foods:state) food-id:ingredient))
                      =/  amount  ?-  units.amount.ingredient
                          %g  (div:rs -:amount:ingredient mass:base-food)
                          %ml  !!
                          %ct  -:amount:ingredient
                        ==
                      =/  units-txt  ?-  units.amount.ingredient
                          %g   "g"
                          %ml  !!
                          %ct  ""
                        ==
                      =/  amount-display=@rs  ?-  units.amount.ingredient
                          %g   (mul:rs amount mass:base-food)
                          %ml  !!
                          %ct  amount
                        ==
                      ;tr
                        ;td: {(format:fmt amount-display)} {units-txt}
                        ;td: {(trip name:base-food)}
                        ;td: {(format:fmt (mul:rs calories:base-food amount))}
                        ;td: {(format:fmt (mul:rs carbs:base-food amount))}
                        ;td: {(format:fmt (mul:rs protein:base-food amount))}
                        ;td: {(format:fmt (mul:rs fat:base-food amount))}
                        ;td: {(format:fmt (mul:rs sugar:base-food amount))}
                      ==
                    ::
                    ;+
                      =/  recipe-food  (recipe-to-food recipe foods)
                    ;tr
                      ;td;
                      ;td: Total
                      ;td: {(format:fmt calories:recipe-food)}
                      ;td: {(format:fmt carbs:recipe-food)}
                      ;td: {(format:fmt protein:recipe-food)}
                      ;td: {(format:fmt fat:recipe-food)}
                      ;td: {(format:fmt sugar:recipe-food)}
                    ==
                  ==
                ==
                ;form(action (weld (url-path-for-recipe recipe) "/add-ingredient"), method "POST")
                  ;label: Ingredient
                  ;input(type "text", name "food-id");
                  ;label: Amount
                  ;input(type "text", name "amount");
                  ;label: Units
                  ;input(type "text", name "units");
                  ;input(type "submit", value "Add ingredient");
                ==
                ;h2: Instructions
                ;ol
                  ;*  %+  turn  instructions:recipe
                    |=  [instr=@t]
                    ;li: {(trip instr)}
                ==
                ;form(action (weld (url-path-for-recipe recipe) "/add-instr"), method "POST")
                  ;input(type "text", name "instr");
                  ;input(type "submit", value "Add instruction");
                ==
              ==
            ==
          :_  state
          %-  send  [200 ~ [%html (crip (en-xml:html sailhtml))]]
        ==
        ::
          [%apps %server %recipes @ %add-instr ~]
        =/  the-id=@t  q:(need (de:base16:mimes:html (snag 3 `(list @t)`site)))
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          =+  (~(get by recipes:state) the-id)                :: Find the recipe
          ?~  -  :_  state  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
          =/  the-recipe  (need -)                            :: First item from the found list
          =/  data  (parse-form-body request.inbound-request)
          ?~  data
            :_  state  %-  send  [400 ~ [%plain "No data received"]]
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(url-path-for-recipe the-recipe))]]
          %=  state
            recipes  %+  ~(put by recipes)
              the-id
            the-recipe(instructions (snoc instructions:the-recipe (need (get-form-value (need data) 'instr'))))
          ==
        ==
        ::
          [%apps %server %recipes @ %add-ingredient ~]
        =/  the-id=@t  q:(need (de:base16:mimes:html (snag 3 `(list @t)`site)))
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          =+  (~(get by recipes:state) the-id)                :: Find the recipe
          ?~  -  :_  state  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
          =/  the-recipe  (need -)                            :: First item from the found list
          =/  data  (parse-form-body request.inbound-request)
          ?~  data
            :_  state  %-  send  [400 ~ [%plain "No data received"]]
          ~&  >>>  data
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(url-path-for-recipe the-recipe))]]
          =/  new-ingredient=ingredient
            :-
              food-id=(scan (trip (need (get-form-value (need data) 'food-id'))) dem)
            :-  (sun:rs (scan (trip (need (get-form-value (need data) 'amount'))) dem))
              ?+  (need (get-form-value (need data) 'units'))  !!
                  %g
                %g
                  %ml
                %ml
                  %ct
                %ct
              ==
          %=  state
            recipes  %+  ~(put by recipes)
              id.the-recipe
            the-recipe(ingredients (snoc ingredients:the-recipe new-ingredient))
          ==
        ==
        ::
          [%apps %server %recipes @ %rename ~]
        =/  the-id=@t  q:(need (de:base16:mimes:html (snag 3 `(list @t)`site)))
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          =+  (~(get by recipes:state) the-id)                :: Find the recipe
          ?~  -  :_  state  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
          =/  the-recipe  (need -)                            :: First item from the found list
          =/  data  (parse-form-body request.inbound-request)
          ?~  data
            :_  state  %-  send  [400 ~ [%plain "No data received"]]
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(url-path-for-recipe the-recipe))]]
          %=  state
            recipes  %+  ~(put by recipes)
              the-id
            the-recipe(name (need (get-form-value (need data) 'new-name')))
          ==
        ==
      ==
    ::
    ++  handle-static
      |=  [site=(list @ta)]
      ^-  http-response:schooner
      ?+  site  [404 ~ [%stock ~]]
          [%styles %css ~]
        [200 ~ [%css styles-css]]
      ==
    --
  --
::
:: Each time Eyre pokes a request to us, it will subscribe for the response.  We will just accept
:: those connections (wire = /http-response/[eyre-id]) and reject any others.
:: See: https://docs.urbit.org/system/kernel/eyre/reference/tasks#connect
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path  (on-watch:def path)
      [%http-response *]
    `this
  ==
::
:: Arvo will respond when we initially connect to Eyre in `on-init`.  We will accept (and ignore)
:: that and reject any other communications.
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+  sign-arvo  (on-arvo:def wire sign-arvo)
      [%eyre %bound *]
    `this
  ==
::
:: Don't need any of these
++  on-agent  on-agent:def
++  on-leave  on-leave:def
++  on-peek  on-peek:def
++  on-fail   on-fail:def
--
