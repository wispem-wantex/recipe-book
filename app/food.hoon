/-  *food
/+  default-agent, dbug, schooner, server, *food-init, fmt, *food-utils
::
/*  styles-css  %css  /app/styles/css
::
|%
+$  versioned-state
  $%  state-0
  ==
+$  state-0  [%0 foods=(list food) recipes=(list recipe)]
::
++  blank-state-0  [%0 foods=initial-foods recipes=*(list recipe)]
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
    def   ~(. (default-agent this %.n) bowl)
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
                ;h1: Hi!
                ;p
                  ; Hello, world
                ==
                ;form(action "/apps/server/add-item", method "POST")
                  ;label: Add new item
                  ;input(type "text", name "item");
                  ;input(type "submit", value "Submit");
                ==
                ;h3: Items (so far)
                ;ul
                  ;*  %+  turn  foods:state
                    |=  [=food]
                    ;li: {(trip name:food)}
                ==
                ;form(action "/apps/server/clear", method "POST")
                  ;input(type "submit", value "Clear all items");
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
                    ;*  %+  turn  foods:state
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
          [%apps %server %ingredients *]
        =/  the-id  +:(scan (trip (snag 3 `(list @t)`site)) bisk:so)
        ?+  method.request.inbound-request  [(send [405 ~ [%stock ~]]) state]
            %'GET'
          ::
          =+  (skim foods:state |=(=food =(id:food the-id)))  :: Find the food
          ?~  -  :_  state  [(send [404 ~ [%stock ~]])]       :: 404 if it's not found
          =/  food  (snag 0 `(list food)`-)                   :: First item from the found list
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
            foods  %+  turn  foods
              |=  [f=food]
              ^-  food
              ?.  =(id:f the-id)
                f
              =/  new-food  (parse-food (need data))
              new-food(id id:f)  :: This is kind of gross(?)
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
