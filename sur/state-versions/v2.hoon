/-  v1=state-versions-v1
|%
::
:: A `food` is a piece of food.  It has a specified unit size (mass) and other physical parameters
:: such as density.  `cook_ratio` is how much it shrinks after cooking (e.g., 0.7 means 100g of it
:: will be 70g after cooking).
+$  food-id  @
+$  food
  $+  food-type
  $:  id=food-id
      name=@t
      calories=@rs
      carbs=@rs
      protein=@rs
      fat=@rs
      sugar=@rs
      alcohol=@rs
      water=@rs
      potassium=@rs
      sodium=@rs
      calcium=@rs
      magnesium=@rs
      phosphorus=@rs
      iron=@rs
      zinc=@rs
      mass=@rs
      density=(unit @rs)
      price=@rs
      cook-ratio=@rs
  ==
+$  foods
  $+  food-list
  (map food-id food)
::
:: Units of measurement that you can use to denominate an ingredient amount
+$  units
  $+  unit-type
  $?  %ct    :: servings / item count (e.g., "3 bananas")
      ::
      ::  Mass
      %g     :: grams
      %lbs   :: pounds
      %oz    :: ounces
      ::
      :: Volume
      %ml    :: milliliters
      %cups  :: cups
      %tsp   :: teaspoons
      %tbsp  :: tablespoons
      %fl-oz :: fluid ounces
  ==
::
:: An `ingredient` is an amount of a food.
+$  ingredient
  $+  ingredient-type
  $:  food-id=@
      amount=[=@rs =units]  :: e.g., [100 %g] => 100 grams; [3 %ct] => three of them
  ==
::
:: A recipe is a list of ingredients and a list of instructions, with a name
+$  recipe-id  @
+$  recipe
  $+  recipe-type
  $:  id=recipe-id
      name=@ta
      created-at=@da
      last-modified-at=(unit @da)
      ingredients=(list ingredient)
      blurb=@t
      instructions=(list @t)
      provenance=(unit $:(author=@p id=recipe-id))
      comments=(list [author=@p posted-at=@da txt=@t])
  ==
+$  recipes
  $+  recipe-list
  (map recipe-id recipe)
::
:: App state
+$  state  [%2 =foods =recipes]
::
++  from-v1
  |=  [prev-state=state:v1]
  ^-  state
  =|  new=state
  %_  new
    :: Make density amounts a `(unit @rs)`, making negative vals empty
    foods  %-  molt
      %+  turn  ~(val by foods.prev-state)
        |=  [f=food:v1]
        ^-  (pair food-id food)
        :-  id.f
        =/  new-density  ?:  (lth:rs density.f .0)  [~]  [~ density.f]
        %=  f
          density  new-density
        ==
    :: Add `comments` field to recipes
    recipes  %-  molt
      %+  turn  ~(val by recipes.prev-state)
        |=  [r=recipe:v1]
        ^-  (pair recipe-id recipe)
        :-  id.r
        :*  id=id.r
            name=name.r
            created-at=~2024.1.1  :: Have to pick something
            last-modified-at=~
            ingredients=ingredients.r
            blurb=blurb.r
            instructions=instructions.r
            provenance=provenance.r
            comments=[~]
        ==
  ==
--
