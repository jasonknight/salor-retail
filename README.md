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

# Salor Technology

Salor Retail is intrinsically networked, it is meant to be installed on a central server and
be accessed by client machines. There is no need for addons to become multi-lane, and it
is possible to setup impromptu cash registers with a laptop, or iPad when existing points of
sale are bogged down. 

Salor's Feature set is above and beyond practically every other Point of Sale system out there.
Because of this, it's a resource hog, so it requires a real computer to run, you can't get
away with running it on some antiquated machine. It will require at least 512mb of ram, 2gb is
better. Our largest client to date has about 12,000 items and 70,000 sales each averaging about
4 line items per sale.

The location of the central server is arbitrary, it can be next to the screen, in the building,
or in another country. 

# i18n Support

Salor Retail has already been translated into French, Spanish, German, Greek, Russian, Chinese
and Polish. Finnish, Turkish, and Arabic and on the way.

# Salor Installation

Clone the repository

    cd salor-retail/salor-retail
    bundle install
    {{edit config/database.yml}}
    rake db:create
    rake salor:seed
    rails s

Navigate to http://localhost:3000 and login with either :
* 010
* 020
* 030
* 040

Visit http://www.salorpos.com/demo-of-salor-pos for more info and to view live demos in
various languages.

# Commercial Support and Installation

Salor Retail is not easy to install, it has many moving parts. While all of those parts
are opensource, and provided by us on github, all the compilations and configurations
require a broad understanding of the technology involved. You are welcome to install the
system yourself, but if you have trouble, we offer pre-installed systems as well as
tech-support packages.

You can purchase a pre-installed Salor Retail system on [Amazon.com](http://www.amazon.com/Salor-Retail-Point-Sale-Server/dp/B00BOOEZGG/ref=sr_1_1?ie=UTF8&qid=1363017791&sr=8-1&keywords=salor+retail)

Or contact us directly at office@red-e.eu


