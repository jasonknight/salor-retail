window.Drawer ||= {}
calculator_total = 0
dt = Drawer.amount
window.displayCalculatorTotal = ->
  calculator_total = 0
  for elem in $('.eod-calculator-input')
    ttl = parseInt(elem.value) * toFloat($(elem).attr('amount'))
    calculator_total += ttl if ttl > 0 
  calculator_total = Math.round(calculator_total * 100) / 100
  $(cls).removeClass('eod-error') for cls in ['.eod-drawer-total', '.eod-calculator-total']
  $(cls).removeClass('eod-ok') for cls in ['.eod-drawer-total', '.eod-calculator-total']
  $('.eod-calculator-difference').html(toCurrency(0));
  diff = 0
  if Drawer.amount > calculator_total
    diff = Math.round((Drawer.amount - calculator_total) * 100) / 100
    $('.eod-calculator-total').addClass('eod-error')
  if calculator_total > Drawer.amount
    diff = Math.round((calculator_total - Drawer.amount) * 100) / 100
    $('.eod-drawer-total').addClass('eod-error')
  $('.eod-calculator-difference').html(toCurrency(diff));
  $('.eod-calculator-total').html(toCurrency(calculator_total));
window.eodPayout = ->
  $.ajax
    type: 'POST'
    url: '/vendors/new_drawer_transaction'
    data:
      transaction:
        amount: Drawer.amount
        notes: 'end_of_day_payout'
        tag: 'end_of_day'
        trans_type: 'payout'
    dataType: 'script'
    success: (data) ->
      $(cls).html(toCurrency(0)) for cls in ['.eod-drawer-total','.eod-calculator-total','.eod-calculator-difference']
    error: (data,status,err) ->
      alert(err)
 $ ->
   for elem in $('.eod-calculator-input')
     if not $(elem).hasClass('calculator-done')
       $(elem).blur -> 
         displayCalculatorTotal()
       $(elem).addClass('calculator-done')
         
