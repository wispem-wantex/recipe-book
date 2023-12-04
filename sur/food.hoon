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
      density=@rs
      price=@rs
      cook-ratio=@rs
  ==
+$  foods
  $+  food-list
  (map food-id food)
::
:: Units of measurement that you can use to denominate an ingredient amount
+$  units
  $%  %g     :: grams
      %ml    :: milliliters
      %ct    :: item count (e.g., "3 bananas")
      :: ...etc (could add more)
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
      ingredients=(list ingredient)
      instructions=(list @t)
  ==
+$  recipes
  $+  recipe-list
  (map recipe-id recipe)
--
