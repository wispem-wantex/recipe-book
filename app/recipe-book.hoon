/-  *food, food-actions, changelog
/+  default-agent, dbug, schooner, server, *food-init, fmt, *food-utils, food-tpl
::
/=  the-changelog  /doc/changelog
::
/*  styles-css  %css  /app/styles/css
/*  chili-garlic-png  %png  /app/chili-garlic/png
::
|%
+$  card  card:agent:gall
--
::
%-  agent:dbug
=|  state
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this) bowl)
    http  ~(. +> bowl)
::
:: Register this agent for handling incoming HTTP requests at the path /apps/recipe-book.   This
:: allows us to serve a web front end without needing a "glob".
::
:: `desk.docket-0` will specify that /apps/recipe-book is the entrypoint for this app, so it will
:: take us to that path if you click this desk's tile in landscape.
++  on-init
  ^-  (quip card _this)
  :_  this(state initial-state)  :: Initialize to a new blank state
  :~
    [%pass /eyre/connect %arvo %e %connect [~ /apps/recipe-book] %recipe-book]
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
  =/  updated-state  (load-state old)
  :-  ~  :: No cards
  %=  this
    :: Load the updated state
    state  %=  updated-state
      :: Update help recipe with any new instrs
      recipes  (~(put by recipes.updated-state) help-recipe-id help-recipe)
    ==
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
      %handle-http-request
    =^  cards  state
      (handle-local-http:http !<([@ta =inbound-request:eyre] vase))
    [cards this]
    ::
      %recipe-action
    =/  act  !<(action:food-actions vase)
    ?-  -.act
      ::
      :: remote request for our data; poke it back to them
        %req
      ~&  "Serving req from {<src.bowl>}"
      =;  resp=action:food-actions
        :_  this
        :~  [%pass /whatever %agent [src.bowl %recipe-book] %poke %recipe-action !>(resp)]  ==
      ?-  -.req.act
          %list-recipes
        [%resp original-eyre-id.act [%list-recipes [%2 ~ recipes.state]]]
        ::
          %get-recipe
        =/  the-recipe=recipe
          (~(got by recipes.state) recipe-id.req.act)
        =/  filtered-foods
          %-  molt  %+  turn  ingredients.the-recipe
            |=  [i=ingredient]
            :-  food-id.i
            (~(got by foods:state) food-id.i)
        [%resp original-eyre-id.act [%get-recipe recipe-id.req.act [%2 filtered-foods (molt :~([recipe-id.req.act the-recipe]))]]]
        ::
          %copy-recipe
        =/  the-recipe=recipe
          (~(got by recipes.state) recipe-id.req.act)
        =/  filtered-foods
          %-  molt  %+  turn  ingredients.the-recipe
            |=  [i=ingredient]
            :-  food-id.i
            (~(got by foods:state) food-id.i)
        [%resp original-eyre-id.act [%copy-recipe recipe-id.req.act [%2 filtered-foods (molt :~([recipe-id.req.act the-recipe]))]]]
      ==
      ::
      :: remote ship replied; now render HTML for it
        %resp
      ?-  -.resp.act
          %list-recipes
        :_  this
        %-  response:schooner  :*
          original-eyre-id.act
          200
          ~
          %-  render-sail-html
            :-  "Recipes ({<src.bowl>}"
            %+  weld
              ;+  ;h2: from {<src.bowl>}
            =/  renderer  ~(recipe-list food-tpl [(load-state state.resp.act) src.bowl])
            (renderer(base-path "/apps/recipe-book/pals/{<src.bowl>}") %.n)
        ==
        ::
          %get-recipe
        :_  this
        %-  response:schooner  :*
          original-eyre-id.act
          200
          ~
          %-  render-sail-html
            =/  the-recipe  (~(got by recipes:(load-state state.resp.act)) recipe-id.resp.act)
            =/  copy-recipe-path
              %+  weld  (~(en recp-path "/apps/recipe-book/pals/{<src.bowl>}") the-recipe)
              "/copy"
            :-
              (trip name:the-recipe)
            %+  weld
              ;+  ;div(class "original-author-container")
                ;h2: from {<src.bowl>}
                ;form(action copy-recipe-path, method "POST")
                  ;input(type "submit", value "Make your own copy");
                ==
              ==
            (~(recipe-detail food-tpl [(load-state state.resp.act) src.bowl]) recipe-id.resp.act %.n)
        ==
        ::
          %copy-recipe
        =/  old-recipe  (~(got by recipes:(load-state state.resp.act)) recipe-id.resp.act)
        =/  new-foods  %+  turn  ingredients.old-recipe
          |=  [i=ingredient]
          ^-  (pair food ingredient)
          =/  our-food=(unit food)  (~(get by foods:state) food-id.i)
          =/  their-food=food  (~(got by foods:(load-state state.resp.act)) food-id.i)
          ?~  our-food
            [their-food i]  :: New food with new ID
          ?:  =(their-food (need our-food))
            [their-food i]  :: Same ingredient with same ID; clobbering is OK
          :: Otherwise, they've modified the ingredient; give it a new ID to avoid clobbering
          =/  new-id  (mod (add eny.bowl id.their-food) 0x1.0000.0000.0000.0000)
          [their-food(id new-id) i(food-id new-id)]
        =/  new-recipe
          %_  old-recipe
            id  (mod (add eny.bowl id.old-recipe) 0x1.0000.0000.0000.0000)
            ingredients  (turn new-foods |=([=food =ingredient] ingredient))
            provenance  ?~  provenance.old-recipe
              [~ [src.bowl id.old-recipe]]
            provenance.old-recipe
          ==
        :_
          %=  this
            state  %=  state
              foods  (~(uni by (molt (turn new-foods |=([=food =ingredient] [id.food food])))) foods.state)
              recipes  (~(put by recipes:state) id.new-recipe new-recipe)
            ==
          ==
        %-  response:schooner  :*
          original-eyre-id.act
          302
          ~
          %redirect  (crip (en:recp-path new-recipe))
        ==
      ==
    ==
  ==
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
++  on-fail   on-fail:def
++  on-peek
  :: TODO: this probably isn't needed until/unless we switch from pokes to subscriptions for
  :: inter-ship requests
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
      [%x %ingredients ~]
      :: .^(noun %gx /=recipe-book=/ingredients/noun)
    :^  ~  ~  %noun
      !>  ~(val by foods:state)
  ==
--
::
=>
|%
++  render-sail-html
  |=  [title=tape content=marl]
  ^-  resource:schooner
  :-
    %html
  %-  crip  %-  en-xml:html
  ;html
    ;head
      ;title: {title} | Recipe book
      ;link(rel "stylesheet", href "/apps/recipe-book/static/styles/css");
      ;link(rel "icon", href "/apps/recipe-book/static/chili-garlic/png");
      ::
      :: JQuery: use Select2 plugin to make comboboxes
      ;script(src "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", integrity "sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=", crossorigin "anonymous");
      ;script(src "https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js", integrity "sha256-9yRP/2EFlblE92vzCA10469Ctd0jT48HnmmMw5rJZrA=", crossorigin "anonymous");
      ;link(rel "stylesheet", href "https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css", integrity "sha256-zaSoHBhwFdle0scfGEFUCwggPN7F+ip9XRglo8IWb4w=", crossorigin "anonymous");
    ==
    ;body
      ;nav
        ;img(id "logo", src "/apps/recipe-book/static/chili-garlic/png");
        ;ul
          ;li
            ;a(href "/apps/recipe-book/ingredients"): Ingredients
          ==
          ;li
            ;a(href "/apps/recipe-book/recipes"): Recipes
          ==
        ==
        ;ul
          ;li
            ;a(href "/apps/recipe-book/about"): About this app
          ==
          ;li
            ;a(href "/apps/recipe-book/help"): Help
          ==
          ;li
            ;a(href "/apps/recipe-book/changelog"): Changelog
          ==
        ==
        ;div
          ;form(action "/apps/recipe-book/pals", method "POST")
            :: Enclosed in {} to fix syntax highlighter
            ;label: {"Check out a friend's recipes"}
            ;input(name "pal", id "search-bar", placeholder "~zod");
            ;input(type "submit", id "search-bar-submit", value "Go");
          ==
        ==
      ==
      ;main
        ;*  content
      ==
    ==
  ==
--
::
|_  =bowl:gall
++  handle-local-http
  |=  [eyre-id=@ta =inbound-request:eyre]
  ^-  (quip card _state)
  =/  ,request-line:server
    (parse-request-line:server url.request.inbound-request)
  =+  send=(cury response:schooner eyre-id)
  ?.  ?&  authenticated.inbound-request  =(src.bowl our.bowl)  ==
    :_  state  %-  send  [302 ~ [%login-redirect '/apps/recipe-book']]
  ::
  |^
    ?+  site  [(send [404 ~ [%stock ~]]) state]
        [%apps %recipe-book ~]
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'GET'
        :_  state
        %-  send  [302 ~ [%redirect '/apps/recipe-book/about']]
      ==
      ::
        [%apps %recipe-book %static *]
      ?.  ?=  %'GET'  method.request.inbound-request
        [(send [405 ~ [%stock ~]]) state]
      [(send (handle-static (slag 3 `(list @ta)`site))) state]  :: Delegate to static handler
      ::
        [%apps %recipe-book %about *]
      ?.  ?=  %'GET'  method.request.inbound-request
        [(send [405 ~ [%stock ~]]) state]
      :_  state
      %-  send
        =;  sailhtml
          [200 ~ (render-sail-html "About" sailhtml)]
        :~
          ;h1: About %recipe-book
          ;p
            This is an app for you to create and share your favorite recipes.
            It also tells you the macros (macronutrients) for each recipe you create.
          ==
          ;p
            ; For help getting started, check out the sandbox recipe
            ;a(href "/apps/recipe-book/help"): here
            ; .
          ==
          ;p
            ; Or, check out your recipes
            ;a(href "/apps/recipe-book/recipes"): here
            ; .
          ==
        ==
      ::
        [%apps %recipe-book %help ~]
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'GET'
        :_  state
        %-  send  [302 ~ [%redirect '/apps/recipe-book/recipes/80345cb237c34773']]
      ==
      ::
        [%apps %recipe-book %changelog ~]
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'GET'
        :_  state
        %-  send
          =;  sailhtml
            [200 ~ (render-sail-html "Changelog" sailhtml)]
          :~
            ;h1: Changelog
            ;div
              ;*  %+  turn  (flop the-changelog)
                |=  [=version-number:changelog =patch-notes:changelog]
                ;div
                  ;h3: {<major.version-number>}.{<minor.version-number>}.{<patch.version-number>}
                  ;ul
                    ;*  %+  turn  patch-notes
                      |=  [msg=@t]
                      ;li: {(trip msg)}
                  ==
                ==
            ==
          ==
      ==
      ::
        [%apps %recipe-book %ingredients ~]
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'GET'
        :_  state
        %-  send
          =;  sailhtml
            [200 ~ (render-sail-html "Ingredients" sailhtml)]
          :~
            ;h1: Ingredients
            ;form(action "/apps/recipe-book/ingredients/new", method "POST")
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
        [%apps %recipe-book %ingredients %new ~]
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'POST'
        =/  next-id  (mod eny.bowl 0x1.0000.0000.0000.0000)
        =/  new-food  *food
        =.  id.new-food  next-id
        :-
          %-  send  [302 ~ [%redirect (crip (url-path-for new-food))]]
        %=  state
          foods  (~(put by foods) next-id new-food)
        ==
      ==
      ::
        [%apps %recipe-book %ingredients @ ~]
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
            ;form(action (url-path-for food), method "POST", class "ingredient-editor")
              ;div(class "labelled-input")
                ;label: Name:
                ;input(type "text", name "name", value (trip name:food));
              ==
              ;div(class "labelled-input")
                ;label
                  ;span(class "mass-title-parent")
                    ; (?)
                    ;div(class "title"): Mass of one serving or 'unit' of this food
                  ==
                  ; Serving size (grams):
                ==
                ;input(type "text", name "mass", value (format:fmt mass:food));
              ==
              ;div(class "labelled-input")
                ;label: Density:
                :: TODO: get rid of ".-1"
                ;input(type "text", name "density", value (format:fmt (fall density:food .-1)));
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
          %-  send  [302 ~ [%redirect '/apps/recipe-book/ingredients']]
        %=  state
          foods  %+  ~(put by foods)
            the-id
          =/  new-food  (parse-food (need data))
          new-food(id the-id)  :: This is kind of gross(?)
        ==
      ==
      ::
        [%apps %recipe-book %recipes ~]
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'GET'
        :_  state
        %-  send
          =;  sailhtml
            [200 ~ (render-sail-html "Recipes" sailhtml)]
          (~(recipe-list food-tpl [state our.bowl]) %.y)
      ==
      ::
        [%apps %recipe-book %recipes %new ~]
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
        =.  id.recipe  (mod eny.bowl 0x1.0000.0000.0000.0000)
        :-
          %-  send  [302 ~ [%redirect (crip (en:recp-path recipe))]]
        %=  state
          recipes  (~(put by recipes:state) id.recipe recipe)
        ==
      ==
      ::
        [%apps %recipe-book %recipes @ *]
      =/  the-id  (de:recp-id (snag 3 `(list @t)`site))
      =+  (~(get by recipes:state) the-id)                :: Find the recipe
      ?~  -  :_  state  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
      =/  the-recipe  (need -)                            :: First item from the found list
      ?+  (slag 4 `(list @t)`site)  [(send [404 ~ [%stock ~]]) state]
          [~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          ::
          :_  state
          %-  send
            =;  sailhtml=marl
              [200 ~ (render-sail-html (trip name.the-recipe) sailhtml)]
            (~(recipe-detail food-tpl [state our.bowl]) the-id %.y)
        ==
        ::
          [%add-instr ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          =/  data  (parse-form-body request.inbound-request)
          ?~  data
            :_  state  %-  send  [400 ~ [%plain "No data received"]]
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(en:recp-path the-recipe))]]
          %=  state
            recipes  %+  ~(put by recipes)
              the-id
            the-recipe(instructions (snoc instructions:the-recipe (need (get-form-value (need data) 'instr'))))
          ==
        ==
        ::
          [%move-instr @ @ ~]
        =/  from-index  (rash (snag 5 `(list @t)`site) dem)
        =/  to-index  (rash (snag 6 `(list @t)`site) dem)
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(en:recp-path the-recipe))]]
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
          [%delete-instr @ ~]
        =/  instruction-index  (rash (snag 5 `(list @t)`site) dem)
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(en:recp-path the-recipe))]]
          %=  state
            recipes  %+  ~(put by recipes)
              the-id
            the-recipe(instructions (oust [instruction-index 1] instructions:the-recipe))
          ==
        ==
        ::
          [%add-ingredient ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          =/  data  (parse-form-body request.inbound-request)
          ?~  data
            :_  state  %-  send  [400 ~ [%plain "No data received"]]
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(en:recp-path the-recipe))]]
          =/  new-ingredient=ingredient
            :-
              food-id=(scan (trip (need (get-form-value (need data) 'food-id'))) dem)
            :-  (unformat:fmt (need (get-form-value (need data) 'amount')))
              =/  u  (need (get-form-value (need data) 'units'))
              ?>  ?=  units  u
              u
          %=  state
            recipes  %+  ~(put by recipes)
              id.the-recipe
            the-recipe(ingredients (snoc ingredients:the-recipe new-ingredient))
          ==
        ==
        ::
          [%delete-ingredient @ ~]
        =/  ingredient-index  (rash (snag 5 `(list @t)`site) dem)
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(en:recp-path the-recipe))]]
          %=  state
            recipes  %+  ~(put by recipes)
              the-id
            the-recipe(ingredients (oust [ingredient-index 1] ingredients:the-recipe))
          ==
        ==
        ::
          [%rename ~]
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'POST'
          =/  data  (parse-form-body request.inbound-request)
          ?~  data
            :_  state  %-  send  [400 ~ [%plain "No data received"]]
          :-
            %-  send  [302 ~ [%redirect `@t`(crip `tape`(en:recp-path the-recipe))]]
          %=  state
            recipes  %+  ~(put by recipes)
              the-id
            the-recipe(name (need (get-form-value (need data) 'new-name')))
          ==
        ==
      ==
      ::
        [%apps %recipe-book %pals ~]
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'POST'  :: TODO: why is this POST?
        :_  state
        =/  query=tape
          (trip (need (get-form-value (need (parse-form-body request.inbound-request)) 'pal')))
        =/  result
          (parse-recipe-link query)
        ?~  result
          %-  send  [427 ~ [%plain "Invalid ship or path: {<pal>}"]]
        ?~  id.u.result
          %-  send  [302 ~ [%redirect (crip (weld "/apps/recipe-book/pals/" (scow %p pal.u.result)))]]
        =/  the-path  (~(en recp-path (weld "/apps/recipe-book/pals/" (scow %p pal.u.result))) %*(. *recipe id u.id.u.result))
        %-  send  [302 ~ [%redirect (crip the-path)]]
      ==
      ::
        [%apps %recipe-book %pals @ *]
      =/  pal=@p  (rash (snag 3 `(list @t)`site) ;~(pfix sig fed:ag))
      :_  state
      ?+  (slag 4 `(list @t)`site)  (send [404 ~ [%stock ~]])
          [~]
        ?+  method.request.inbound-request  (send [405 ~ [%stock ~]])
            %'GET'
          =/  data=action:food-actions  [%req eyre-id [%list-recipes ~]]
          :~
            [%pass /whatever %agent [pal %recipe-book] %poke %recipe-action !>(data)]
          ==
        ==
        ::
          [%recipes @ *]
        =/  the-id=@t  (de:recp-id (snag 5 `(list @t)`site))
        ?+  (slag 6 `(list @t)`site)  (send [404 ~ [%stock ~]])
            [~]
          ?+  method.request.inbound-request  (send [405 ~ [%stock ~]])
              %'GET'
            =/  data=action:food-actions  [%req eyre-id [%get-recipe the-id]]
            :~
              [%pass /whatever %agent [pal %recipe-book] %poke %recipe-action !>(data)]
            ==
          ==
          ::
            [%copy ~]
          ?+  method.request.inbound-request  (send [405 ~ [%stock ~]])
              %'POST'
            =/  data=action:food-actions  [%req eyre-id [%copy-recipe the-id]]
            :~
              [%pass /whatever %agent [pal %recipe-book] %poke %recipe-action !>(data)]
            ==
          ==
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
        [%chili-garlic %png ~]
      [200 ~ [%image-png chili-garlic-png]]
    ==
  ::
  --
::++  handle-remote-read-req
::  |=  [=req:food-actions]
::  ^-  resp:food-actions
::  ?+  -.req  !!
::      %list-recipes
::    [%list-recipes recipes.state]
::  ==

::  ~  :: TODO
::++  handle-remote-recipe-resp
::  |=  [=resp:food-actions]
::  ^-  (quip card _state)

--
