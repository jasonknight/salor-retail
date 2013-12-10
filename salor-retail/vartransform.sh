#!/bin/bash

fn_in=$1
fn_out=$2

for file in `find app -name *.js`
do
  echo "Processing ${file}"
  perl -i -pe "s/function ${fn_in}\(/${fn_out} = function(/g" $file
done

for file in `find app -name *.js -o -name *.erb -o -name *.haml`
do
  echo "Processing ${file}"
  perl -i -pe "s/([^\.])${fn_in}\(/\1${fn_out}(/g" $file
done

# ./vartransform.sh add_item sr.fn.pos_core.addItem
# ./vartransform.sh updateOrder sr.fn.pos_core.updateOrder

# ./vartransform.sh updateOrderItems sr.fn.pos_core.updateOrderItems
# ./vartransform.sh addPosItem sr.fn.pos_core.addPosItem
# ./vartransform.sh updatePosItem sr.fn.pos_core.updatePosItem
# ./vartransform.sh drawOrderItemRow sr.fn.pos_core.drawOrderItemRow
# ./vartransform.sh trigger_click sr.fn.pos_core.triggerClick
# ./vartransform.sh makeItemMenu sr.fn.pos_core.makeItemMenu
