include("login.js");
include("choose_register.js");
include("conventional_sales/cash_drop_100.js");
include("conventional_sales/add_item_of_10.js");
include("conventional_sales/add_item_of_5.js");
include("conventional_sales/add_item_of_20.js");
include("conventional_sales/add_item_of_40.js");
include("conventional_sales/add_buybackitem_of_10.js");
include("conventional_sales/add_buybackitem_of_10and20.js");
include("conventional_sales/add_item_of_4.js");
include("conventional_sales/add_item_of_10discount.js");
include("conventional_sales/add_item_of_20discount.js");
include("conventional_sales/check_drawer_calculator.js");
include("conventional_sales/cash_payout_167.js");
include("conventional_sales/check_detail_report.js");
var VIEW = new Chrome("ConventionalSalesMachine");

/*
  The idea here is that all the tests are made up of smaller
  tests that fit together as a chain, i.e. with calling
  test.next(other_test.run); 
  
  So at the end of the test, the next test is run, and
  either succeeds or fails. 
  
  This makes it easier for us to create/tweak tests alone, and
  then string them together to create one big test, and then
  at the very end, test the tests :) Which is essentially what
  the testing manual does. As you go along you verify order
  total, change, and drawer amount, and then at the end
  you verify the day report.
  
*/

// Conventional Sales Testing
var login             = new env.modules.LoginMachine();
    login.view        = VIEW; // We reuse the same view here because we aren't perf testing.
                              // Thus we reuse the cache, localdb, log, and cookies etc.
var choose            = new env.modules.ChooseRegister();
    choose.view       = VIEW;
var cash_drop         = new env.modules.CashDrop();
    cash_drop.view    = VIEW;
var add_10            = new env.modules.Add10();
    add_10.view       = VIEW;
var add_5             = new env.modules.Add5();
    add_5.view        = VIEW;
var add_20            = new env.modules.Add20();
    add_20.view       = VIEW
var add_40            = new env.modules.Add40();
    add_40.view       = VIEW
var add_buyback_10            = new env.modules.AddBuyback10();
    add_buyback_10.view       = VIEW;
var add_buyback_10and20       = new env.modules.AddBuyback10And20();
    add_buyback_10and20.view  = VIEW;
var add_4             = new env.modules.Add4();
    add_4.view        = VIEW;
var add_10d            = new env.modules.Add10Discount();
    add_10d.view       = VIEW;
var add_20d            = new env.modules.Add20Discount();
    add_20d.view       = VIEW;
var check_drawer_calculator            = new env.modules.CheckDrawerCalculator();
    check_drawer_calculator.view       = VIEW;
var cash_payout        = new env.modules.CashPayout();
    cash_payout.view    = VIEW;
var check_detail_report            = new env.modules.CheckDetailReport();
    check_detail_report.view       = VIEW;  
    
// Tax related modules 
include("tax_calculations/get_vendor_config.js");
include("tax_calculations/set_calculate_tax.js");
include("tax_calculations/make_taxable_order.js");
var get_vendor_config                           = new env.modules.GetVendorConfig();
    get_vendor_config.view                      = VIEW;
var set_calc_tax                                = new env.modules.SetCalculateTax();
    set_calc_tax.view                           = VIEW;
var make_taxable_order                          = new env.modules.MakeTaxableOrder();
    make_taxable_order.view                     = VIEW;

function run_with_taxes() {
  make_taxable_order.run(url + "/orders/new").next(env.report);
}

var url = "http://localhost:3000";

login.run(url).next(function () { 
  choose.run(url + "/cash_registers").next(function () {
    cash_drop.run("").next(function () {
      add_10.run("").next(function () {
        add_5.run("").next(function () {
          add_20.run("").next(function () {
            add_40.run("").next(function () {
              add_buyback_10.run("").next(function () {
                add_buyback_10and20.run("").next(function () {
                  add_4.run("").next(function () {
                    add_10d.run("").next(function () {
                      add_20d.run("").next(function () {
                        check_drawer_calculator.run("").next(function () {
                          cash_payout.run("").next(function () {
                            check_detail_report.run("").next(function () {
                            
                                env.report();
                                
                            }); //check_detail_report
                          }); //cash_payout
                        }); //check_drawer_calculator
                      }); //add_20d
                    }); //add_10d
                  }); //add_4
                }); //add_buyback_10and20
              }); //add_buyback_10
            }); //add_40
          }); //add_20
        }); //add_5
      }); //add_10
    });//cash_drop
  }); //choose
}); // login


/*login.run(url).next(function () { 
  // Use this area to test an individual function
  
  
  
}); // end login.run
*/
// Scratch Area
/* login.run(url).next(function () { 

  
}); // end login.run
*/


