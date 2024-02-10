/-  *food, food-actions
/+  *test, food-utils
/=  recipe-book  /app/recipe-book
::
:: Create a fake bowl to use for the tests
=/  fake-bowl  %*  .  *bowl:gall
    now  ~2024.1.1
    eny  `@uvJ`0x1111.2222.3333.4444.5555.6666.7777.8888
  ==
::
=>
|%
  +$  card  card:agent:gall
  +$  task  task:agent:gall
  +$  cards  $+  cards  (list card)
  +$  agent  agent:gall
--
::
=>
::
:: Some test helpers
|%
  ::
  :: First, some helpers for dealing with cards.  I don't understand what I have to do to convince
  :: the type checker, so the ugliness is in one place here.
  ++  get-cage-from-fact-card
    |=  [=card]
    ^-  cage
    ?+  -.card  !!
        [%give]
      ?+  -.p.card  !!
          [%fact]
        cage.p.card
      ==
    ==
  ++  unwrap-pass-card
    |=  =card
    ^-  [=path =ship agent-name=term =task]
    ?+  -.card  !!
        [%pass]
      ?+  -.q.card  !!
          [%agent]
        [p.card ship.q.card name.q.card task.q.card]
      ==
    ==
  ::
  :: Call the `on-poke` arm with `%list-recipes` to get all the recipes from an agent.
  :: The returned tang is probably not that useful but it's there, w/e
  ++  get-recipes-from-agent
    |=  [current-agent=agent]
    ^-  [tang =recipes]
    =/  eyre-id=@ta  'blehblehbleh'
    :: Poke the agent to list its recipes
    =/  poke=cage  [%recipe-action !>(`action:food-actions`[%req eyre-id [%list-recipes ~]])]
    =+  [effects2=cards next=agent]=(~(on-poke `agent`current-agent fake-bowl) poke)
    =/  thecard=card  (head effects2)
    =/  thetask=task  task:(unwrap-pass-card thecard)
    ?>  ?=  %poke  -.thetask
    =/  thecage=cage  +.thetask
    :*
      %+  weld
        %+  expect-lent  effects2  1
      %+  expect-eq  !>(%recipe-action)  !>(p.thecage)
      ::
      =/  act  !<(action:food-actions q.thecage)
      ?+  -.act  !!
          [%resp]
        ?+  -.resp.act  !!
            [%list-recipes]
          recipes:(load-state state.resp.act)
        ==
      ==
    ==
  ::
  :: A typical HTTP response is 3 Gall cards:
  :: - 1 for the header
  :: - 1 for the body (data)
  :: - 1 %kick to indicate end-of-response (stop subscribing to that path).
  ++  parse-http-response-cards
    |=  [=cards]
    ^-  [=response-header:http data=(unit octs)]
    ?>  =(3 (lent cards))  :: 1 header, 1 data, and 1 kick
    :: TODO: check the third card is actually a %kick
    =/  header-card  (snag 0 cards)
    =/  header-cage  (get-cage-from-fact-card header-card)
    ?>  =(%http-response-header -.header-cage)
    =/  data-card  (snag 1 cards)
    =/  data-cage  (get-cage-from-fact-card data-card)
    ?>  =(%http-response-data -.data-cage)
    :-
      !<(response-header:http +.header-cage)
    !<((unit octs) +.data-cage)
  ::
  :: Helper function to assert that an HTTP response cardset indicates a HTTP redirection
  ++  expect-redirected-to
    |=  [=cards redirected-to=@t]
    ^-  tang
    =/  [header=response-header:http data=(unit octs)]  (parse-http-response-cards cards)
    ;:  weld
      ?:  =(302 status-code.header)  ~
        :~  leaf+"Expected: redirect (HTTP 302)"
            leaf+"Actual:   HTTP {<status-code.header>}"
        ==
      =/  actual-redirect=@t  (need (get-form-value:food-utils headers.header 'location'))
      ?:  =(actual-redirect redirected-to)  ~
        :~  leaf+"Expected redirect: {<redirected-to>}"
            leaf+"Actual redirect:   {<actual-redirect>}"
        ==
      %+  expect-eq  !>(~)  !>(data)
    ==  ::
  :: Helper function to assert that an HTTP response cardset indicates a certain HTTP status
  ++  expect-http-status
    |=  [=cards expected-status-code=@]
    ^-  tang
    =/  [header=response-header:http data=(unit octs)]  (parse-http-response-cards cards)
    ?:  =(expected-status-code status-code.header)  ~
      :~  leaf+"Expected: HTTP {<expected-status-code>}"
          leaf+"Actual:   HTTP {<status-code.header>}"
      ==
--
::
|%
  ::
  ::  Assert that, on loading a %recipe-book agent for the first time, the two default recipes are
  ::  available
  ++  test-on-init
    :: Init the agent
    =+  [effects=cards next=agent]=~(on-init recipe-book fake-bowl)
    :: Check that it has a Help and a Default recipe
    =/  [tangs=tang recipes=recipes]  (get-recipes-from-agent next)
    ;:  weld
      tangs
      %-  expect  !>((~(has by recipes) (de:recp-id:food-utils '80345cb237c34773')))
      %-  expect  !>((~(has by recipes) (de:recp-id:food-utils 'de32bc69c2e6b69f')))
      %+  expect-lent  ~(val by recipes)  2
    ==
  ::
  ::  After saving and reloading the state, it should come back the same
  ++  test-on-load
    =/  [effects=cards next=agent]  ~(on-init recipe-book fake-bowl)         :: Init the agent
    =/  state-vase  ~(on-save `agent`next fake-bowl)                         :: Save it
    =/  [effects=cards next2=agent]  (~(on-load next fake-bowl) state-vase)  :: Load it
    :: Check state of the reloaded agent
    =/  [tangs=tang recipes=recipes]  (get-recipes-from-agent next2)
    ;:  weld
      tangs
      %-  expect  !>((~(has by recipes) (de:recp-id:food-utils '80345cb237c34773')))
      %-  expect  !>((~(has by recipes) (de:recp-id:food-utils 'de32bc69c2e6b69f')))
      %+  expect-lent  ~(val by recipes)  2
    ==
::
:: HTTP pokes
::
:: ----------
  ::
  ::  Create a new recipe; should be redirected to that recipe detail page
  ++  test-new-recipe
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]
    =/  [=cards next2=agent]  :: Poke it to create a new recipe
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  'some eyre id whatever'
      [%.y %.y *address:eyre %'POST' '/apps/recipe-book/recipes/new' ~ `(as-octs:mimes:html 'name=New+Recipe')]
    =/  [tangs=tang recipes=recipes]  (get-recipes-from-agent next2)
    =/  the-id  0x5555.6666.7777.8888
    ;:  weld
      :: Check state updates
      ;:  weld
        %+  expect-lent  ~(val by recipes)  3
        %-  expect  !>((~(has by recipes) the-id))
        %+  expect-eq  !>(id:(~(got by recipes) the-id))  !>(the-id)
        tangs
      ==
      :: Check HTTP response
      %+  expect-redirected-to  cards  (crip (en:recp-path:food-utils (~(got by recipes) the-id)))
    ==
  ::
  ::  Recipe detail page
  ++  test-recipe-detail
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    ;:  weld
      ::  Load a recipe properly
      =/  [=cards next2=agent]
        %+  ~(on-poke next fake-bowl)
          %handle-http-request
        !>  ^-  [@ta inbound-request:eyre]
        :-  'some eyre id whatever'
        [%.y %.y *address:eyre %'GET' '/apps/recipe-book/recipes/80345cb237c34773' ~ ~]
      :: Check HTTP response
      =/  [header=response-header:http data=(unit octs)]  (parse-http-response-cards cards)
      %+  expect-eq  !>(200)  !>(status-code.header)
      ::  Load a nonexistent recipe
      =/  [=cards next2=agent]
        %+  ~(on-poke next fake-bowl)
          %handle-http-request
        !>  ^-  [@ta inbound-request:eyre]
        :-  'some eyre id whatever'
        [%.y %.y *address:eyre %'GET' '/apps/recipe-book/recipes/378987923789382' ~ ~]
      :: Check HTTP response
      =/  [header=response-header:http data=(unit octs)]  (parse-http-response-cards cards)
      %+  expect-eq  !>(404)  !>(status-code.header)
    ==
  ::
  ::  Rename a recipe
  ++  test-recipe-rename
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    =/  the-id=recipe-id  (de:recp-id:food-utils '80345cb237c34773')
    ;:  weld
      ::  Check recipe initial
      =/  =recipes  recipes:(get-recipes-from-agent next)
      %+  expect-eq  !>('How to use this app :)')  !>(name:(~(got by recipes) the-id))
      ::  Rename the recipe
      =/  [=cards next2=agent]
        %+  ~(on-poke next fake-bowl)
          %handle-http-request
        !>  ^-  [@ta inbound-request:eyre]
        :-  'some eyre id whatever'
        [%.y %.y *address:eyre %'POST' '/apps/recipe-book/recipes/80345cb237c34773/rename' ~ `(as-octs:mimes:html 'new-name=How+to+not+use+this+app+%3A%29')]
      ;:  weld
        :: Check state updates
        =/  =recipes  recipes:(get-recipes-from-agent next2)
        %+  expect-eq  !>('How to not use this app :)')  !>(name:(~(got by recipes) the-id))
        :: Check HTTP response
        %+  expect-redirected-to  cards  '/apps/recipe-book/recipes/80345cb237c34773'
      ==
    ==
  ::
  ::  Add ingredient to recipe
  ++  test-recipe-add-ingredient
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    =/  the-id=recipe-id  (de:recp-id:food-utils '80345cb237c34773')
    =/  initial-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next)) the-id)
    =/  test-cases=(list [req-data=@t expected-new-ingr=ingredient])  :~
          ['food-id=9&amount=300&units=ct' [food-id=9 amount=[.300 %ct]]]
          ['food-id=9&amount=3.3&units=g' [food-id=9 amount=[.3.3 %g]]]
        ==
    %-  zing  %+  turn  test-cases
      |=  [req-data=@t expected-new-ingr=ingredient]
      ^-  tang
      ::  Add an ingredient
      =/  [=cards next2=agent]
        %+  ~(on-poke next fake-bowl)
          %handle-http-request
        !>  ^-  [@ta inbound-request:eyre]
        :-  'some eyre id whatever'
        [%.y %.y *address:eyre %'POST' '/apps/recipe-book/recipes/80345cb237c34773/add-ingredient' ~ `(as-octs:mimes:html req-data)]
      ;:  weld
        :: Check HTTP response
        %+  expect-redirected-to  cards  '/apps/recipe-book/recipes/80345cb237c34773'
        :: Check state updates
        =/  new-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next2)) the-id)
        ;:  weld
          %+  expect-eq  !>((add 1 (lent ingredients.initial-recipe)))  !>((lent ingredients.new-recipe))
          %+  expect-eq  !>(expected-new-ingr)  !>((rear ingredients.new-recipe))
        ==
      ==
  ::
  ::  Delete ingredient
  ++  test-recipe-delete-ingredient
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    =/  the-id=recipe-id  (de:recp-id:food-utils '80345cb237c34773')
    =/  initial-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next)) the-id)
    ::  Delete an ingredient
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  'some eyre id whatever'
      [%.y %.y *address:eyre %'POST' '/apps/recipe-book/recipes/80345cb237c34773/delete-ingredient/0' ~ ~]
    ;:  weld
      :: Check HTTP response
      %+  expect-redirected-to  cards  '/apps/recipe-book/recipes/80345cb237c34773'
      :: Check state updates
      =/  new-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next2)) the-id)
      ;:  weld
        %+  expect-eq  !>((sub (lent ingredients.initial-recipe) 1))  !>((lent ingredients.new-recipe))
        ^-  tang  %-  zing  %+  turn  :: Check that each item in `initial-recipe` from 1..end is now in position 0..end-1
          `(list @)`(gulf 0 (dec (lent ingredients.new-recipe)))
          |=  [i=@]
          ^-  tang
          %+  expect-eq  !>((snag i ingredients.new-recipe))  !>((snag +(i) ingredients.initial-recipe))
      ==
    ==
  ::
  ::  Add instruction to recipe
  ++  test-recipe-add-instruction
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    =/  the-id=recipe-id  (de:recp-id:food-utils '80345cb237c34773')
    =/  initial-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next)) the-id)
    ::  Add an instruction
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  'some eyre id whatever'
      [%.y %.y *address:eyre %'POST' '/apps/recipe-book/recipes/80345cb237c34773/add-instr' ~ `(as-octs:mimes:html 'instr=Blah+blah+blah+something%2C+something+else%21')]
    ;:  weld
      :: Check HTTP response
      %+  expect-redirected-to  cards  '/apps/recipe-book/recipes/80345cb237c34773'
      :: Check state updates
      =/  new-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next2)) the-id)
      ;:  weld
        %+  expect-eq  !>((add 1 (lent instructions.initial-recipe)))  !>((lent instructions.new-recipe))
        %+  expect-eq  !>('Blah blah blah something, something else!')  !>((rear instructions.new-recipe))
      ==
    ==
  ::
  ::  Delete instruction
  ++  test-recipe-delete-instruction
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    =/  the-id=recipe-id  (de:recp-id:food-utils 'de32bc69c2e6b69f')
    =/  initial-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next)) the-id)
    ::  Delete an instruction
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  'some eyre id whatever'
      [%.y %.y *address:eyre %'POST' '/apps/recipe-book/recipes/de32bc69c2e6b69f/delete-instr/4' ~ ~]
    ;:  weld
      :: Check HTTP response
      %+  expect-redirected-to  cards  '/apps/recipe-book/recipes/de32bc69c2e6b69f'
      :: Check state updates
      =/  new-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next2)) the-id)
      ;:  weld
        %+  expect-eq  !>((sub (lent instructions.initial-recipe) 1))  !>((lent instructions.new-recipe))
        ^-  tang  %-  zing  %+  turn  :: Check that each item in `initial-recipe` from 0..3 is unchanged
          `(list @)`(gulf 0 3)
          |=  [i=@]
          ^-  tang
          %+  expect-eq  !>((snag i instructions.new-recipe))  !>((snag i instructions.initial-recipe))
        ^-  tang  %-  zing  %+  turn  :: Check that each item in `initial-recipe` from 5..end is now in position 4..end-1
          `(list @)`(gulf 5 (dec (lent instructions.new-recipe)))
          |=  [i=@]
          ^-  tang
          %+  expect-eq  !>((snag i instructions.new-recipe))  !>((snag +(i) instructions.initial-recipe))
      ==
    ==
  ::
  ::  Move instruction
  ++  test-recipe-move-instruction
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    =/  the-id=recipe-id  (de:recp-id:food-utils 'de32bc69c2e6b69f')
    =/  initial-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next)) the-id)
    ::  Move an instruction
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  'some eyre id whatever'
      [%.y %.y *address:eyre %'GET' '/apps/recipe-book/recipes/de32bc69c2e6b69f/move-instr/4/1' ~ ~]
    ;:  weld
      :: Check HTTP response
      %+  expect-redirected-to  cards  '/apps/recipe-book/recipes/de32bc69c2e6b69f'
      :: Check state updates
      =/  new-recipe=recipe  (~(got by recipes:(get-recipes-from-agent next2)) the-id)
      ;:  weld
        %+  expect-eq  !>((lent instructions.initial-recipe))  !>((lent instructions.new-recipe))
        ^-  tang  %-  zing  %+  turn  :: Check that each item in `initial-recipe` from 0..0 is unchanged
          `(list @)`(gulf 0 0)
          |=  [i=@]
          ^-  tang
          %+  expect-eq  !>((snag i instructions.new-recipe))  !>((snag i instructions.initial-recipe))
        %+  expect-eq  !>((snag 1 instructions.new-recipe))  !>((snag 4 instructions.initial-recipe))
        ^-  tang  %-  zing  %+  turn  :: Check that each item in `initial-recipe` from 1..3 is moved ahead 1 position
          `(list @)`(gulf 1 3)
          |=  [i=@]
          ^-  tang
          %+  expect-eq  !>((snag +(i) instructions.new-recipe))  !>((snag i instructions.initial-recipe))
        ^-  tang  %-  zing  %+  turn  :: Check that each item in `initial-recipe` from 5..end is unchanged
          `(list @)`(gulf 5 (dec (lent instructions.new-recipe)))
          |=  [i=@]
          ^-  tang
          %+  expect-eq  !>((snag i instructions.new-recipe))  !>((snag i instructions.initial-recipe))
      ==
    ==
  ::
  :: Search bar queries
  :: ------------------
  ::
  ::  Search for just a user (~sampel-palnet)
  ++  test-search-bar-pal-only
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    :: Do a search for "~sampel-palnet"
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  'some eyre id whatever'
      [%.y %.y *address:eyre %'POST' '/apps/recipe-book/pals' ~ `(as-octs:mimes:html 'pal=~sampel-palnet')]
    :: Check HTTP response
    %+  expect-redirected-to  cards  '/apps/recipe-book/pals/~sampel-palnet'
  ::
  ::  Search for a friend's recipe
  ++  test-search-bar-with-recipe-link
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    :: Do a search for "~sampel-palnet/123456789abcdef0/some-recipe-link"
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  'some eyre id whatever'
      [%.y %.y *address:eyre %'POST' '/apps/recipe-book/pals' ~ `(as-octs:mimes:html 'pal=~sampel-palnet%2F123456789abcdef0%2Fsome-recipe-link')]
    :: Check HTTP response
    %+  expect-redirected-to  cards  '/apps/recipe-book/pals/~sampel-palnet/recipes/123456789abcdef0'
  ::
  ::  Search for nonsense
  ++  test-search-bar-with-gibberish
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    :: Do a search for "fjakwelfj"
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  'some eyre id whatever'
      [%.y %.y *address:eyre %'POST' '/apps/recipe-book/pals' ~ `(as-octs:mimes:html 'pal=fjakwelfj')]
    :: Check HTTP response
    %+  expect-http-status  cards  427
  ::
  ::  Trigger remote request for recipes
  ++  test-trigger-remote-recipes-query
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    =/  eyre-id  'some eyre id whatever'
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  eyre-id
      [%.y %.y *address:eyre %'GET' '/apps/recipe-book/pals/~sampel-palnet' ~ ~]
    :: Check Ames response
    ;:  weld
      %+  expect-lent  cards  1
      =/  card-contents  (unwrap-pass-card (head cards))
      ;:  weld
        %+  expect-eq  !>(~sampel-palnet)  !>(ship.card-contents)
        %+  expect-eq  !>(%recipe-book)    !>(agent-name.card-contents)
        %+  expect-eq  !>(`task`[%poke `cage`[%recipe-action !>(`action:food-actions`[%req eyre-id %list-recipes ~])]])    !>(task.card-contents)
      ==
    ==
  ::
  ::  Trigger remote request for a particular recipe
  ++  test-trigger-remote-recipe-detail-query
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    =/  eyre-id  'some eyre id whatever'
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  eyre-id
      [%.y %.y *address:eyre %'GET' '/apps/recipe-book/pals/~sampel-palnet/recipes/12345678' ~ ~]
    :: Check Ames response
    ;:  weld
      %+  expect-lent  cards  1
      =/  card-contents  (unwrap-pass-card (head cards))
      ;:  weld
        %+  expect-eq  !>(~sampel-palnet)  !>(ship.card-contents)
        %+  expect-eq  !>(%recipe-book)    !>(agent-name.card-contents)
        %+  expect-eq  !>(`task`[%poke `cage`[%recipe-action !>(`action:food-actions`[%req eyre-id %get-recipe 0x1234.5678])]])    !>(task.card-contents)
      ==
    ==
  ::
  ::  Trigger remote request to copy a recipe
  ++  test-trigger-remote-copy-recipe-query
    =/  next=agent  +:[~(on-init recipe-book fake-bowl)]  :: Init the agent
    =/  eyre-id  'some eyre id whatever'
    =/  [=cards next2=agent]
      %+  ~(on-poke next fake-bowl)
        %handle-http-request
      !>  ^-  [@ta inbound-request:eyre]
      :-  eyre-id
      [%.y %.y *address:eyre %'POST' '/apps/recipe-book/pals/~sampel-palnet/recipes/12345678/copy' ~ ~]
    :: Check Ames response
    ;:  weld
      %+  expect-lent  cards  1
      =/  card-contents  (unwrap-pass-card (head cards))
      ;:  weld
        %+  expect-eq  !>(~sampel-palnet)  !>(ship.card-contents)
        %+  expect-eq  !>(%recipe-book)    !>(agent-name.card-contents)
        %+  expect-eq  !>(`task`[%poke `cage`[%recipe-action !>(`action:food-actions`[%req eyre-id %copy-recipe 0x1234.5678])]])    !>(task.card-contents)
      ==
    ==
--
