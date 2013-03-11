# Salor Retail

Salor Retail is a Rails based Point of Sale system that is intended for
desktop or web deployment. It can be deployed like any Rails application,
and will work in all modern browsers, even I.E.

Salor Retail has a flexible deployment strategy:

* Deploy it like a simple website and access it via a browser
* Deploy it as a desktop application coupled with salor-bin thin client
* Deploy it as a SaaS

To facilitate desktop deployment, all the components for Salor Retail are packaged
as .debs and can easily be installed on any Debian based distribution (Ubuntu, Kubunut etc).

To deploy to windows, a virtual box running a supported Linux distribution is needed
along with port forwarding. salor-bin has been ported to both Mac and Windows, and client
downloads are available upon request.



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
