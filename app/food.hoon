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
          :_  state
          %-  send
            =;  sailhtml
              [200 ~ (render-sail-html "Home" sailhtml)]
            :~
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
        ::
          [%apps %server %static *]
        ?.  ?=  %'GET'  method.request.inbound-request
          [(send [405 ~ [%stock ~]]) state]
        [(send (handle-static (slag 3 `(list @ta)`site))) state]  :: Delegate to static handler
        ::
          [%apps %server %ingredients ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          :_  state
          %-  send
            =;  sailhtml
              [200 ~ (render-sail-html "Ingredients" sailhtml)]
            :~
              ;h1: Ingredients
              ;form(action "/apps/server/ingredients/new", method "POST")
                ;input(type "submit", value "New ingredient");
              ==
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
          [%apps %server %ingredients %new ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          =/  next-id  (mod eny.bowl 0xffff.ffff.ffff.ffff)
          =/  new-food  *food
          =.  id.new-food  next-id
          :-
            %-  send  [302 ~ [%redirect (crip (url-path-for new-food))]]
          %=  state
            foods  (~(put by foods) next-id new-food)
          ==
        ==
        ::
          [%apps %server %ingredients @ ~]
        =/  the-id  (scan (trip (snag 3 `(list @t)`site)) dem) ::bisk:so)
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          ::
          :_  state
          =+  (~(get by foods:state) the-id)     :: Find the recipe
          ?~  -  [(send [404 ~ [%stock ~]])]     :: 404 if it's not found
          =/  food  (need -)                     :: First item from the found list
          %-  send
            =;  sailhtml
              [200 ~ (render-sail-html "Ingredient: {(trip name.food)}" sailhtml)]
            :~
              ;h1: {(trip name:food)}
              ;form(action (url-path-for food), method "POST")
                ;div(class "labelled-input")
                  ;label: Name:
                  ;input(type "text", name "name", value (trip name:food));
                ==
                ;div(class "labelled-input")
                  ;label: Calories:
                  ;input(type "text", name "calories", value (format:fmt calories:food));
                ==
                ;div(class "labelled-input")
                  ;label: Carbs:
                  ;input(type "text", name "carbs", value (format:fmt carbs:food));
                ==
                ;div(class "labelled-input")
                  ;label: Protein:
                  ;input(type "text", name "protein", value (format:fmt protein:food));
                ==
                ;div(class "labelled-input")
                  ;label: Fat:
                  ;input(type "text", name "fat", value (format:fmt fat:food));
                ==
                ;div(class "labelled-input")
                  ;label: Sugar:
                  ;input(type "text", name "sugar", value (format:fmt sugar:food));
                ==
                ;input(type "submit", value "Save");
              ==
            ==
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
          :_  state
          %-  send
            =;  sailhtml
              [200 ~ (render-sail-html "Recipes" sailhtml)]
            :~
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
        ::
          [%apps %server %recipes %new ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          :_  state
          %-  send
            =;  sailhtml
              [200 ~ (render-sail-html "New recipe" sailhtml)]
            :~
              ;h1: New Recipe
              ;form(method "POST")
                ;input(type "text", name "name");
                ;input(type "submit", value "Create");
              ==
            ==
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
          :_  state
          =+  (~(get by recipes:state) the-id)     :: Find the recipe
          ?~  -  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
          =/  recipe  (need -)                     :: First item from the found list
          %-  send
            =;  sailhtml
              [200 ~ (render-sail-html (trip name.recipe) sailhtml)]
            :~
              ;script(src "https://raw.githack.com/SortableJS/Sortable/master/Sortable.js");
              ;h1: {(trip name:recipe)}
              ;form(action (weld (url-path-for-recipe recipe) "/rename"), method "POST")
                ;input(type "text", name "new-name");
                ;input(type "submit", value "Rename recipe");
              ==
              ;table
                ;thead
                  ;th;  :: "X" button
                  ;th: Amount
                  ;th: Ingredient
                  ;th: Calories
                  ;th: Carbs
                  ;th: Protein
                  ;th: Fat
                  ;th: Sugar
                ==
                ;tbody
                  ;*  %-  head  %-  spin  :+  ingredients:recipe  0
                    |=  [=ingredient index=@]
                    :_  +(index)
                    =/  base-food  (need (~(get by foods:state) food-id:ingredient))
                    =/  amount  ?-  units.amount.ingredient
                        %g  (div:rs -:amount:ingredient mass:base-food)
                        %ct  -:amount:ingredient
                      ==
                    =/  units-txt  ?-  units.amount.ingredient
                        %g   "g"
                        %ct  ""
                      ==
                    =/  amount-display=@rs  ?-  units.amount.ingredient
                        %g   (mul:rs amount mass:base-food)
                        %ct  amount
                      ==
                    ;tr
                      ;td
                        ;form(action (weld (url-path-for-recipe recipe) "/delete-ingredient/{<index>}"), method "POST", class "x-button")
                          ;input(type "submit", value "\d7", title "Delete ingredient");
                        ==
                      ==
                      ;td: {(format:fmt amount-display)} {units-txt}
                      ;td(class "ingr-name"): {(trip name:base-food)}
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
                    ;td;
                    ;td(class "total"): Total:
                    ;td(class "total"): {(format:fmt calories:recipe-food)}
                    ;td(class "total"): {(format:fmt carbs:recipe-food)}
                    ;td(class "total"): {(format:fmt protein:recipe-food)}
                    ;td(class "total"): {(format:fmt fat:recipe-food)}
                    ;td(class "total"): {(format:fmt sugar:recipe-food)}
                  ==
                ==
              ==
              ;form(action (weld (url-path-for-recipe recipe) "/add-ingredient"), method "POST", class "add-ingr")
                ;label: Ingredient:
                ;input(type "text", list "ingredient-options", name "food-id");
                ;datalist(id "ingredient-options")
                  ;*  %+  turn  ~(val by foods:state)
                    |=  [=food]
                    ;option(value (a-co:co id.food)): {(trip name.food)}
                ==
                ;label: Amount:
                ;input(type "text", name "amount");
                ;label: Units:
                ;select(name "units")
                  ;option(value "g"): g
                  ;option(value "ct"): count
                ==
                ;input(type "submit", value "Add ingredient");
              ==
              ;h2: Instructions
              ;ol(id "instructions")
                ;*  %-  head  %-  spin  :+  instructions:recipe  0
                  |=  [instr=@t index=@]
                  :_  +(index)
                  ;li
                    ;form(action (weld (url-path-for-recipe recipe) "/delete-instr/{<index>}"), method "POST", class "x-button")
                      ;input(type "submit", value "\d7", title "Delete instruction");
                    ==
                    ;span(class "instr-number"): {(a-co:co (add 1 index))}.
                    ;span
                      ; {(trip instr)}
                    ==
                  ==
              ==
              ;form(action (weld (url-path-for-recipe recipe) "/add-instr"), method "POST", class "add-instr")
                ;textarea(name "instr", rows "3", cols "50");
                ;input(type "submit", value "Add instruction");
              ==
              =;  thescript
                ;script: {(trip thescript)}
                '''
                Sortable.create(instructions, {
                  handle: ".instr-number",
                  onEnd: function(evt) {
                    console.log(window.location.href + "/move-instr/" + evt.oldIndex + "/" + evt.newIndex);
                    window.location.href = window.location.href + "/move-instr/" + evt.oldIndex + "/" + evt.newIndex;
                  },
                });
                '''
            ==
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
          [%apps %server %recipes @ %move-instr @ @ ~]
        =/  the-id=@t  q:(need (de:base16:mimes:html (snag 3 `(list @t)`site)))
        =/  from-index  (rash (snag 5 `(list @t)`site) dem)
        =/  to-index  (rash (snag 6 `(list @t)`site) dem)
        ~&  >>>  "{<from-index>}, {<to-index>}"
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          =+  (~(get by recipes:state) the-id)                :: Find the recipe
          ?~  -  :_  state  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
          =/  the-recipe  (need -)                            :: First item from the found list
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(url-path-for-recipe the-recipe))]]
          %=  state
            recipes  %+  ~(put by recipes)
              the-id
            :: Oust the moved ingredient from "from-index" and put it at "to-index"
            %=  the-recipe
              instructions  %:  into
                (oust [from-index 1] instructions:the-recipe)
                to-index
                (snag from-index instructions:the-recipe)
              ==
            ==
          ::`(list ingredient)`(move-list-item instructions:the-recipe from-index to-index))
          ==
        ==
        ::
          [%apps %server %recipes @ %delete-instr @ ~]
        =/  the-id=@t  q:(need (de:base16:mimes:html (snag 3 `(list @t)`site)))
        =/  instruction-index  (rash (snag 5 `(list @t)`site) dem)
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          =+  (~(get by recipes:state) the-id)                :: Find the recipe
          ?~  -  :_  state  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
          =/  the-recipe  (need -)                            :: First item from the found list
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(url-path-for-recipe the-recipe))]]
          %=  state
            recipes  %+  ~(put by recipes)
              the-id
            the-recipe(instructions (oust [instruction-index 1] instructions:the-recipe))
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
          [%apps %server %recipes @ %delete-ingredient @ ~]
        =/  the-id=@t  q:(need (de:base16:mimes:html (snag 3 `(list @t)`site)))
        =/  ingredient-index  (rash (snag 5 `(list @t)`site) dem)
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          =+  (~(get by recipes:state) the-id)                :: Find the recipe
          ?~  -  :_  state  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
          =/  the-recipe  (need -)                            :: First item from the found list
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(url-path-for-recipe the-recipe))]]
          %=  state
            recipes  %+  ~(put by recipes)
              the-id
            the-recipe(ingredients (oust [ingredient-index 1] ingredients:the-recipe))
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
    ::
    ++  render-sail-html
      |=  [title=tape content=marl]
      ^-  resource:schooner
      :-
        %html
      %-  crip  %-  en-xml:html
      ;html
        ;head
          ;link(rel "stylesheet", href "/apps/server/static/styles/css");
          ;title: {title}
        ==
        ;body
          ;nav
            ;ul
              ;li
                ;a(href "/apps/server/ingredients"): Ingredients
              ==
              ;li
                ;a(href "/apps/server/recipes"): Recipes
              ==
            ==
          ==
          ;main
            ;*  content
          ==
        ==
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
