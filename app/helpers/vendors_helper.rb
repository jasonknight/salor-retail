module VendorsHelper
  def drawer_transaction_path(d,*args)
    return "/vendors/edit_drawer_transaction/#{d.id}"
  end
end
