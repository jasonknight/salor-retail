# Salor Description



Salor is a multi-user (As in multi-account),
multi-store Point of Sale software that comes with
some basic stock management features are well.

## Salor Can:

* Track Coupons and Gift Cards
* Customer Database and Loyalty Card/Point System
* Sell Items and Item Groups
* Purchase Items from Customers
* Timed Discounts on Location of Item, Category, or by SKU
* Generate Barcodes
* Interface with thermal printers, or sticky label printers
* Dynamic payment methods
* Buttons on the POS Screen for adding items without SKU (Like a head of lettuce)
* Super fast and easy to use interface
* Scale to just about any size without much issue.

# Salor Installation

Use RVM, or a clean installation...seriously. (You will need to have the RVM build tools installed)

gem install rake --version=0.8.7 [not optional, seriously!]

gem install bundle

cd path/to/salor

bundle install

If this above gives you errors, try futzing!

export RAILS_ENV=production # if you want to run in production

bundle exec rake salor:seed
