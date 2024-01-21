/-  *food, food-actions, changelog
/+  default-agent, dbug, schooner, server, *food-init, fmt, *food-utils, food-tpl
::
/=  the-changelog  /doc/changelog
::
/*  styles-css  %css  /app/styles/css
/*  chili-garlic-png  %png  /app/chili-garlic/png
::
|%
++  help-recipe-id
  ^-  recipe-id
  (de:recp-id '80345cb237c34773')
++  help-instrs
  ^-  (list @t)
  :~  'This isn\'t a real recipe, it\'s just a sandbox for you to play in.  (It can get reset, so don\'t put an important recipe here.)'
      'Try adding an ingredient to the recipe! Start typing the ingredient name, then pick the right one from the dropdown menu.\0a\0aFor example, try typing "chicken" to filter for chicken options, and add your favorite type of chicken.'
      'Next, enter the amount of that ingredient by typing a number and picking a unit from the dropdown.\0a\0aUnits can be either a "count" (like "2 bananas", so you would type "2" and pick "count"), or a measurement (like "200 grams of ground beef", so you would type "200" and pick "g").'
      'Press "Add ingredient" to add it to the recipe.'
      'The nutritional information of the recipe will be computed automatically.'
      'You can add instructions for the recipe. Just enter them into the box at the bottom of the page, one at a time, pressing "Add instruction".'
      'Ingredients and instructions can be deleted by clicking the "x" button next to them.'
      'You can also re-order the instructions. Click on the instruction number (like "8." for this instruction) to drag-and-drop an instruction to its new place.'
      'If you want an ingredient type that isn\'t in the app yet, you can create it. Click "Ingredients" in the sidebar and then click "New Ingredient".'
      'You can view your list of recipes by clicking "Recipes" in the sidebar.'
      'You can also view your friends\'s recipes (or your enemies\', I guess) by searching their urbit ID in the sidebar.'
  ==
++  help-recipe
  ^-  recipe
  =/  ingredients  ^-  (list ingredient)
    :~  [food-id=44 amount=[rs=.300 units=%g]]
        [food-id=10 amount=[rs=.200 units=%g]]
    ==
  :*  id=help-recipe-id
      name='How to use this app :)'
      ingredients=ingredients
      instructions=help-instrs
      provenance=~
  ==
++  blank-state-0
  ^-  state-0
  :*  %0
      (molt (turn initial-foods |=(f=food `(pair food-id food)`[id.f f])))
      %-  molt  :~
        =/  id=recipe-id  (de:recp-id 'de32bc69c2e6b69f')
        :-  id
        ^-  recipe
        :: Create a default recipe as a welcome
        =/  ingredients  ^-  (list ingredient)
          :~  [food-id=37 amount=[rs=.2 units=%ct]]
              [food-id=92 amount=[rs=.30 units=%g]]
              [food-id=20 amount=[rs=.30 units=%g]]
              [food-id=41 amount=[rs=.40 units=%g]]
              [food-id=121 amount=[rs=.800 units=%g]]
              [food-id=75 amount=[rs=.450 units=%g]]
              [food-id=6 amount=[rs=.300 units=%g]]
              [food-id=98 amount=[rs=.150 units=%g]]
              [food-id=101 amount=[rs=.150 units=%g]]
              [food-id=239 amount=[rs=.2 units=%g]]
              [food-id=241 amount=[rs=.2 units=%g]]
              [food-id=245 amount=[rs=.5 units=%g]]
              [food-id=3.000 amount=[rs=.1000 units=%g]]
          ==
        =/  instrs  ^-  (list @t)
          :~  'In large pot, heat butter and oil.  Cook onions to 1/2 cooked (translucent and soft, starting to turn golden-brown)'
              'Add garlic, cook 1-2 minutes'
              'add tomatoes and chicken broth, bring to a simmer'
              'salt and season the soup, tasting until seasonings are right'
              'cut chicken into bite-sized pieces, add to soup and boil until fully cooked'
              'add pasta and boil until it is cooked "al dente"; add more stock as needed'
              'add half the cheese and stir it into the soup'
              'sprinkle remaining cheese on top and serve'
          ==
        :*  id=id
            name='Chicken Parmigiana Soup'
            ingredients=ingredients
            instructions=instrs
            provenance=[~ [~wispem-wantex id]]
        ==
        ::
        :: The help recipe
        :-  help-recipe-id  help-recipe
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
  :_  this(state blank-state-0)  :: Initialize to a new blank state
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
  =/  updated-state  |-  :: Update state to latest version if needed
    ?-  -.old
      %0  old       :: Up to date
    ==
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
        [%resp original-eyre-id.act [%list-recipes [%0 ~ recipes.state]]]
        ::
          %get-recipe
        =/  the-recipe=recipe
          (~(got by recipes.state) recipe-id.req.act)
        =/  filtered-foods
          %-  molt  %+  turn  ingredients.the-recipe
            |=  [i=ingredient]
            :-  food-id.i
            (~(got by foods:state) food-id.i)
        [%resp original-eyre-id.act [%get-recipe recipe-id.req.act [%0 filtered-foods (molt :~([recipe-id.req.act the-recipe]))]]]
        ::
          %copy-recipe
        =/  the-recipe=recipe
          (~(got by recipes.state) recipe-id.req.act)
        =/  filtered-foods
          %-  molt  %+  turn  ingredients.the-recipe
            |=  [i=ingredient]
            :-  food-id.i
            (~(got by foods:state) food-id.i)
        [%resp original-eyre-id.act [%copy-recipe recipe-id.req.act [%0 filtered-foods (molt :~([recipe-id.req.act the-recipe]))]]]
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
            =/  renderer  ~(recipe-list food-tpl state.resp.act)
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
            =/  the-recipe  (~(got by recipes.state.resp.act) recipe-id.resp.act)
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
            (~(recipe-detail food-tpl state.resp.act) recipe-id.resp.act %.n)
        ==
        ::
          %copy-recipe
        =/  old-recipe  (~(got by recipes.state.resp.act) recipe-id.resp.act)
        =/  new-foods  %+  turn  ingredients.old-recipe
          |=  [i=ingredient]
          ^-  (pair food ingredient)
          =/  our-food=(unit food)  (~(get by foods:state) food-id.i)
          =/  their-food=food  (~(got by foods.state.resp.act) food-id.i)
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
      ;link(rel "stylesheet", href "/apps/recipe-book/static/styles/css");
      ;link(rel "icon", href "/apps/recipe-book/static/chili-garlic/png");
      ;title: {title} | Recipe book
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
            ;input(name "pal", placeholder "~zod");
            ;input(type "submit", value "Go");
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
          (~(recipe-list food-tpl state) %.y)
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
            (~(recipe-detail food-tpl state) the-id %.y)
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
          %'POST'
        :_  state
        =/  pal=tape
          (trip (need (get-form-value (need (parse-form-body request.inbound-request)) 'pal')))
        ?~  (rust pal ;~(pfix sig crub:so))
          %-  send  [427 ~ [%plain "Invalid ship: {<pal>}"]]
        %-  send  [302 ~ [%redirect (crip (weld "/apps/recipe-book/pals/" pal))]]
      ==
      ::
        [%apps %recipe-book %pals @ ~]
      =/  pal  (rash (snag 3 `(list @t)`site) ;~(pfix sig crub:so))
      ?>  =(-.pal %p)  :: make sure it parsed as a ship-name
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'GET'
        :_  state
        =/  data=action:food-actions  [%req eyre-id [%list-recipes ~]]
        :~
          [%pass /whatever %agent [`@p`+.pal %recipe-book] %poke %recipe-action !>(data)]
        ==
      ==
      ::
        [%apps %recipe-book %pals @ %recipes @ ~]
      =/  pal  (rash (snag 3 `(list @t)`site) ;~(pfix sig crub:so))
      ?>  =(-.pal %p)  :: make sure it parsed as a ship-name
      =/  the-id=@t  (de:recp-id (snag 5 `(list @t)`site))
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'GET'
        :_  state
        =/  data=action:food-actions  [%req eyre-id [%get-recipe the-id]]
        :~
          [%pass /whatever %agent [`@p`+.pal %recipe-book] %poke %recipe-action !>(data)]
        ==
      ==
      ::
        [%apps %recipe-book %pals @ %recipes @ %copy ~]
      =/  pal  (rash (snag 3 `(list @t)`site) ;~(pfix sig crub:so))
      ?>  =(-.pal %p)  :: make sure it parsed as a ship-name
      =/  the-id=@t  (de:recp-id (snag 5 `(list @t)`site))
      ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
          %'POST'
        :_  state
        =/  data=action:food-actions  [%req eyre-id [%copy-recipe the-id]]
        :~
          [%pass /whatever %agent [`@p`+.pal %recipe-book] %poke %recipe-action !>(data)]
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
