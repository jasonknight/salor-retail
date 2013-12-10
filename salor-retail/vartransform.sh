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
  perl -i -pe "s/([^\.]*)${fn_in}\(/\1${fn_out}(/g" $file
done

# ./vartransform.sh add_item sr.fn.pos_core.addItem
# ./vartransform.sh updateOrder sr.fn.pos_core.updateOrder
# ./vartransform.sh updateOrderItems sr.fn.pos_core.updateOrderItems
# ./vartransform.sh addPosItem sr.fn.pos_core.addPosItem
# ./vartransform.sh updatePosItem sr.fn.pos_core.updatePosItem
# ./vartransform.sh drawOrderItemRow sr.fn.pos_core.drawOrderItemRow
# ./vartransform.sh trigger_click sr.fn.pos_core.triggerClick
# ./vartransform.sh makeItemMenu sr.fn.pos_core.makeItemMenu
# ./vartransform.sh showOrderOptions sr.fn.pos_core.showOrderOptions
# ./vartransform.sh detailedOrderItemMenu sr.fn.pos_core.detailedOrderItemMenu
# ./vartransform.sh editItemAndOrderItem sr.fn.pos_core.editItemAndOrderItem
# ./vartransform.sh getBehaviorById sr.fn.pos_core.getBehaviorById
# ./vartransform.sh orderItemNameOption sr.fn.pos_core.orderItemNameOption
# ./vartransform.sh getOrderItemId sr.fn.pos_core.getOrderItemId
# ./vartransform.sh highlight sr.fn.pos_core.highlight
# ./vartransform.sh clearOrder sr.fn.pos_core.clearOrder

#./vartransform.sh makeSortable sr.fn.buttons.makeSortable

#./vartransform.sh displayCalculatorTotal sr.fn.coin_calculator.displayTotal
#./vartransform.sh setupCoinCalculator sr.fn.coin_calculator.setup

# ./vartransform.sh display_change sr.fn.change.display_change
# ./vartransform.sh show_denominations sr.fn.change.show_denominations
# ./vartransform.sh get_highest sr.fn.change.get_highest
# ./vartransform.sh recommend sr.fn.change.recommend

# ./vartransform.sh add_payment_method sr.fn.payment.add
# ./vartransform.sh payment_method_options sr.fn.payment.getOptions
# ./vartransform.sh get_payment_total sr.fn.payment.getTotal
# ./vartransform.sh paymentMethodItems sr.fn.payment.getItems

# ./vartransform.sh enablePrintReceiptButton sr.fn.complete.enablePrintReceiptButton
# ./vartransform.sh disablePrintReceiptButton sr.fn.complete.disablePrintReceiptButton
# ./vartransform.sh complete_order_show sr.fn.complete.showPopup
# ./vartransform.sh set_invoice_button sr.fn.complete.setInvoiceButton
# ./vartransform.sh complete_order_hide sr.fn.complete.hidePopup
# ./vartransform.sh complete_order_send sr.fn.complete.send
# ./vartransform.sh complete_order_process sr.fn.complete.process
# ./vartransform.sh show_password_dialog sr.fn.complete.showPasswordPopup

# ./vartransform.sh allow_complete_order sr.fn.complete.allowSending
# ./vartransform.sh callback_printing_done sr.fn.complete.printingDoneCallback

# ./vartransform.sh remove_note_fields sr.fn.customers.removeNoteFields
# ./vartransform.sh add_note_fields sr.fn.customers.addNoteFields