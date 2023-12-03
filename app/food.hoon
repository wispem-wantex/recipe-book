/-  *food
/+  default-agent, dbug, schooner, server, *food-init, fmt, *food-utils
::
|%
+$  versioned-state
  $%  state-0
      state-1
      state-2
  ==
+$  state-0  [%0 ~]
+$  state-1  [%1 items=(list @t)]
+$  state-2  [%2 foods=(list food) recipes=(list recipe)]
::
++  blank-state-2  [%2 foods=initial-foods recipes=*(list recipe)]
+$  card  card:agent:gall
--
::
:: All the boilerplate gibberish
%-  agent:dbug
=|  state-2
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
  :_  this(state blank-state-2)  :: Initialize to a new blank state
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
      %0  $(old *state-1)       :: drop it and reinit the state
      %1  $(old blank-state-2)  :: drop it and reinit the state
      %2  `this(state old)      :: All up to date; keep it as is
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
