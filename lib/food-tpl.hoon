/-  *food
/+  food-utils, fmt, misc-utils
::
=<
::
|_  [=state author=@p]
::
::  Renderer for a recipe detail page
++  recipe-detail
  |=  [=recipe-id is-editable=?]
  =/  recipe  (~(got by recipes.state) recipe-id)
  ^-  marl
  =;  data
    ?:  is-editable
      data
    (disable-all-inputs data)
  :~
    ;script(src "https://raw.githack.com/SortableJS/Sortable/master/Sortable.js");
    ;h1: {(trip name:recipe)}
    ?~  provenance.recipe
        ;div(class "nothing");  :: type checker requires a manx (can't use ~)
      ;h3: {<author:(need provenance.recipe)>}{"'"}s original recipe
    =/  share-link  ;:(weld "{<author>}/" (trip (en:recp-id:food-utils id.recipe)) "/" (scag 30 (slugify:misc-utils (trip name:recipe))))
    ;div(class "share-container")
      ;button(id "share-this-recipe", onclick "shareLink.classList.remove('hidden'); shareLink.disabled = false; shareLink.select(); shareLink.focus();"): Share this recipe
      ;input(type "text", class "hidden", id "shareLink", value share-link);
    ==
    ;form(action (weld (en:recp-path:food-utils recipe) "/rename"), method "POST")
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
          =/  norm-i=normalized-ingredient:food-utils  (normalize-ingredient:food-utils ingredient foods:state)
          =/  base-food  food:norm-i
          =/  amount  amount:norm-i
          =/  units-txt
            ?+  units.amount.ingredient  (trip units.amount.ingredient)
              %ct  ""
              %fl-oz  "fl oz"
            ==
          ;tr
            ;td
              ;form(action (weld (en:recp-path:food-utils recipe) "/delete-ingredient/{<index>}"), method "POST", class "x-button")
                ;input(type "submit", value "\d7", title "Delete ingredient");
              ==
            ==
            ;td: {(format:fmt -.amount.ingredient)} {units-txt}
            ;td(class "ingr-name"): {(trip name:base-food)}
            ;td: {(format:fmt (mul:rs calories:base-food amount))}
            ;td: {(format:fmt (mul:rs carbs:base-food amount))}
            ;td: {(format:fmt (mul:rs protein:base-food amount))}
            ;td: {(format:fmt (mul:rs fat:base-food amount))}
            ;td: {(format:fmt (mul:rs sugar:base-food amount))}
          ==
        ::
        ;+
          =/  recipe-food  (recipe-to-food:food-utils recipe foods:state)
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
    ;form(action (weld (en:recp-path:food-utils recipe) "/add-ingredient"), method "POST", class "add-ingr")
      ;label: Ingredient:
      ;select(name "food-id", id "foodIdSelect")
        ;*  %+  turn  ~(val by foods:state)
          |=  [=food]
          ;option(value (a-co:co id.food)): {(trip name.food)}
      ==
      ;label: Amount:
      ;input(type "text", name "amount");
      ;label: Units:
      ;select(name "units")
        ;option(value "ct"): servings
        ;option(value "g"): g
        ;option(value "lbs"): lbs
        ;option(value "oz"): oz
        ;option(value "ml"): ml
        ;option(value "cups"): cups
        ;option(value "tsp"): tsp
        ;option(value "tbsp"): tbsp
        ;option(value "fl-oz"): fl oz
      ==
      ;input(type "submit", value "Add ingredient");
    ==
    ;h2: Instructions
    ;ol(id "instructions")
      ;*  %-  head  %-  spin  :+  instructions:recipe  0
        |=  [instr=@t index=@]
        :_  +(index)
        ;li
          ;form(action (weld (en:recp-path:food-utils recipe) "/delete-instr/{<index>}"), method "POST", class "x-button")
            ;input(type "submit", value "\d7", title "Delete instruction");
          ==
          ;span(class "instr-number"): {(a-co:co (add 1 index))}.
          ;span
            ;*  %+  turn  (split:misc-utils (trip instr) "\0a")
              |=  [line=tape]
              ;p: {line}
          ==
        ==
    ==
    ;form(action (weld (en:recp-path:food-utils recipe) "/add-instr"), method "POST", class "add-instr")
      ;textarea(name "instr", rows "4", cols "50");
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

      $('#foodIdSelect').select2();
      '''
  ==
::
:: Renderer for the recipe list
++  recipe-list
  =/  base-path  "/apps/recipe-book"
  |=  [is-editable=?]
  ^-  marl
  =;  data
    ?:  is-editable
      data
    (disable-all-inputs data)
  :~
    ;h1: Recipes
    ;input(type "submit", value "New recipe", onclick "window.location.pathname = '/apps/recipe-book/recipes/new'");
    ;ul
      ;*  %+  turn  ~(val by recipes:state)
        |=  [=recipe]
        ;li
          ;a(href (~(en recp-path:food-utils base-path) recipe)): {(trip name:recipe)}
        ==
    ==
  ==
--
::
:: Some helper functions for rendering
|%
::  Disable an '<input>' manx
++  disable
  |=  [input=manx]
  ^-  manx
  %=  input
    a.g  %+  snoc  %+  snoc  a.g.input
      [%disabled "true"]
      [%title "You are viewing someone else's recipe.  Make a copy to edit it"]
  ==
++  disable-all-inputs
  |=  [data=marl]
  ^-  marl
  %+  turn  data
    |=  [item=manx]
    ^-  manx
    ?+  n.g.item  item(c (disable-all-inputs c.item))
      %input     (disable item)
      %select    (disable item)
      %textarea  (disable item)
    ==
--
