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

# ./vartransform.sh echo sr.fn.debug.echo
# ./vartransform.sh ajax_log sr.fn.debug.ajaxLog
# ./vartransform.sh send_email sr.fn.debug.sendEmail

# ./vartransform.sh show_cash_drop sr.fn.drawer.showTransactionPopup
# ./vartransform.sh hide_cash_drop sr.fn.drawer.hideTransactionPopup
# ./vartransform.sh cash_drop_save sr.fn.drawer.saveTransaction
# ./vartransform.sh updateDrawer sr.fn.drawer.update

# ./vartransform.sh displayUserLogins sr.fn.user_logins.display
# ./vartransform.sh remove_user_login sr.fn.user_logins.remove

# ./vartransform.sh focusSetup sr.fn.focus.setup
# ./vartransform.sh focusInput sr.fn.focus.set

#./vartransform.sh showClockin sr.fn.user_logins.showPopup

# ./vartransform.sh make_in_place_edit sr.fn.inplace_edit.make
# ./vartransform.sh inplaceEditBindEnter sr.fn.inplace_edit.bindEnter
# ./vartransform.sh in_place_edit_go sr.fn.inplace_edit.submit

# ./vartransform.sh invoiceSetup sr.fn.invoice.setup
# ./vartransform.sh make_editabl_pm sr.fn.invoice.edit_pm

# ./vartransform.sh Round sr.fn.math.round
# ./vartransform.sh RoundFixed sr.fn.math.roundFixed
# ./vartransform.sh toFloat sr.fn.math.toFloat
# ./vartransform.sh roundNumber sr.fn.math.roundNumber
# ./vartransform.sh toDelimited sr.fn.math.toDelimited
# ./vartransform.sh toCurrency sr.fn.math.toCurrency
# ./vartransform.sh toPercent sr.fn.math.toPercent

# ./vartransform.sh displayMessage sr.fn.messages.displayMessage
# ./vartransform.sh displayMessages sr.fn.messages.displayMessages
# ./vartransform.sh fadeMessages sr.fn.messages.fadeMessages

# ./vartransform.sh onScreenKeyboardSetup sr.fn.onscreen_keyboard.setup
# ./vartransform.sh make_keyboardable sr.fn.onscreen_keyboard.make
# ./vartransform.sh make_keyboardable_with_options sr.fn.makeWithOptions

# ./vartransform.sh remoteSupportSetup sr.fn.remotesupport.setup
# ./vartransform.sh update_connection_status sr.fn.remotesupport.getStatus
# ./vartransform.sh connect_service sr.fn.remotesupport.connect

# ./vartransform.sh isSalorBin sr.fn.salor_bin.is
# ./vartransform.sh usePole sr.fn.salor_bin.usePole
# ./vartransform.sh useMimo sr.fn.salor_bin.useMimo
# ./vartransform.sh onCashDrawerClose sr.fn.salor_bin.onCashDrawerClose
# ./vartransform.sh stop_drawer_observer sr.fn.salor_bin.stopDrawerObserver
# ./vartransform.sh quick_open_drawer sr.fn.salor_bin.quickOpenDrawer
# ./vartransform.sh open_drawer_condition sr.fn.salor_bin.shouldOpenDrawer
# ./vartransform.sh conditionally_open_drawer sr.fn.salor_bin.maybeOpenDrawer
# ./vartransform.sh conditionally_observe_drawer sr.fn.salor_bin.maybeObserveDrawer
# ./vartransform.sh print_order sr.fn.salor_bin.printOrder
# ./vartransform.sh print_url sr.fn.salor_bin.printUrl
# ./vartransform.sh playsound sr.fn.salor_bin.playSound
# ./vartransform.sh updateCustomerDisplay sr.fn.salor_bin.updateCustomerDisplay
# ./vartransform.sh format_pole sr.fn.salor_bin.formatPole
# ./vartransform.sh observe_drawer sr.fn.salor_bin.observeDrawer
# ./vartransform.sh weigh_item sr.fn.salor_bin.weighItem
# ./vartransform.sh print_dialog sr.fn.salor_bin.showPrintDialog
