# Salor Retail

Salor Retail is an extremely innovative Point of Sale system. It has been conceived to provide you with all the features that standard, currently available, POS systems  have, but with the possibility of extending and expanding features as your business and technology grows.

Salor Retail is a Ruby-on-Rails based Point of Sale system that is intended for standalone or web deployment. It can be deployed like any standard Rails application, and will work in all modern browsers.

To facilitate desktop deployment, all the components for Salor Retail are packaged as Debian .deb packages and can easily be installed on any Debian based distribution.



## Main features

* Convenient and easy-to-use JS-based POS interface which has been optimized in real stores around the world
* Stock management including stock transactions
* Stock management for piece-package-container unit relationships
* Shipments tracking including stock transactions
* Track Coupons and Gift Cards
* Customer Database and Loyalty Card/Point System
* Sell Items and Item Groups
* Purchase Items from Customers
* Sell variable-priced lottery products and pay out lottery wins
* Timed Discounts on Location of Item, Category, or by SKU
* Generate Barcodes, Labels and Stickers
* Interface with thermal printers, or sticky label printers
* Dynamic payment methods
* Multi-lane, Multi-user, Multi-device
* Change money calculation
* Weighing and price-per-weight
* Buttons on the POS Screen for adding items without SKU
* Flexible Invoice and delivery note generation
* Scale to just about any size without much issue.
* Integration with the woocommerce webstore plugin for Wordpress
* etc.


## Technology

Salor's Feature set is above and beyond practically every other Point of Sale system out there. Salor Retail is intrinsically networked, it is meant to be installed as a server and be accessed by clients. The location of the central server is arbitrary, it can be next to the screen, in the building, or in another country. 

## I18n Support

The user interface of Salor Retail has already been translated into French, Spanish, German, Greek, Russian, Chinese, Finnish and Polish.

## Development Installation

You will need to have the correct ruby system installed. We suggest using RVM for this see: [rvm.io](http://rvm.io)

In this case we are working with a Debian based distro, for rpm based distros, you're on your own as we don't use or test on them. Sorry. (It shouldn't be so hard tho...you'll probably know the equivalent commands)

Install Ruby 1.9.2

    rvm install 2.2.
    rvm use 1.9.2 --default

If you are installing another version of ruby, you may run into a problem with bundler not having the
ruby source code. You will need to:

    rvm fetch 1.9.x
    rvm reinstall 1.9.x --disable-binary



Then install libmagickwand-dev

    apt-get install libmagickwand-dev libxslt-dev libmysqlclient-dev barcode imagemagick libmagickwand-dev



Now you should be able to continue with the main development setup!


Clone the repository

    cd salor-retail/salor-retail
    bundle install

Copy `config/database.yml.default` to `config/database.yml` and specify database name and database user.

    rake db:create
    rake db:migrate
    rake db:seed
    rails s

Then browse to `http://localhost:3000`. The default password is 000.



## Demo

[http://srdemo1.salorpos.com](http://srdemo1.salorpos.com)

Log in with the password for the English user interface: 000