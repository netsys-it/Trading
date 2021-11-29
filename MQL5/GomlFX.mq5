//+------------------------------------------------------------------+
//|                                                       GomlFX.mq5 |
//|                                                   Daniel Plaskur |
//|                                               https://plaskur.sk |
//+------------------------------------------------------------------+
#property copyright "Daniel Plaskur"
#property link      "https://plaskur.sk"
#property version   "1.00"
#property script_show_inputs
#include <jason.mqh>
input double risk_percentage = 1;
input int sl_pips = 400;
input string auth_code = "XXXXX";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      check_signals();
  }
//+------------------------------------------------------------------+

void check_signals(){
//---
   CJAVal jv;
   string cookie = "auth="+auth_code;
   string referer = NULL;
   int timeout = 500;
   string headers = "Content-Type: application/json\r\n";
   char post[];
   char result[];
   string url = "http://plaskur.sk/goml/v1.0/signals";
   
   ResetLastError();

   int res = WebRequest("GET", url, cookie, referer, timeout, post, 0, result, headers);
   if(res == -1){
      Print("Error in WebRequest. Error code  =", GetLastError());
      MessageBox("Add the address '"+url+"' to the list of allowed URLs on tab 'Expert Advisors'", "Error", MB_ICONINFORMATION);
   }else{
      if(res == 200){
         jv.Deserialize(result);
         for(int i=0;i<10;i++){
         	long id = jv["signals"][i]["id"].ToInt();
         	if(id > 0){
         	   if(canTrade(id)){
         	      string operation=jv["signals"][i]["operation"].ToStr();
               	string symbol=jv["signals"][i]["symbol"].ToStr();
               	double price=jv["signals"][i]["price"].ToDbl();
               	double tp_1=jv["signals"][i]["tp_1"].ToDbl();
               	double sl=jv["signals"][i]["sl"].ToDbl();
               	
               	double symbol_point = SymbolInfoDouble(symbol,SYMBOL_POINT);

               	MqlTradeRequest order_request={};
               	               	
               	order_request.action=TRADE_ACTION_PENDING;
               	if(operation == "BUY"){
               	   order_request.type = ORDER_TYPE_BUY_LIMIT;
               	   if(symbol_point == 0.00001){
                        price = price - 0.001;
                     }
                     else if(symbol_point == 0.001){
                        price = price - 0.1;
                     }
               	}else{
               	   order_request.type = ORDER_TYPE_SELL_LIMIT;
               	   if(symbol_point == 0.00001){
                        price = price + 0.001;
                     }
                     else if(symbol_point == 0.001){
                        price = price + 0.1;
                     }
               	}
               	double lot_size = calculate_lotsize(symbol);
               	
                  order_request.magic=id;
                  order_request.symbol=symbol;
                  order_request.volume=lot_size;
                  order_request.sl=sl;
                  order_request.tp=tp_1;                  
                  order_request.price=price;
                  order_request.type_time=ORDER_TIME_SPECIFIED;
                  order_request.expiration=TimeCurrent()+PeriodSeconds(PERIOD_H4);
                  MqlTradeResult order_result={};
                  
                  check_trend(symbol, operation, price);
                  
                  //if(check_trend(symbol, operation, price)){  
                     if(!OrderSend(order_request, order_result)){
                        // https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes
                        Print("retcode=",order_result.retcode);
                        PrintFormat("OrderSend error %d",GetLastError());
                        Print("symbol=",symbol," operation=",operation," price=",price," tp=",tp_1, " sl=",sl," lotsize=",lot_size);
                     }
                  //}
         	   }
         	}else{
         	   break;
         	}
          }         
      }
   }
}

bool canTrade(long id){
   for(int i=0;i<OrdersTotal();i++){
      if(OrderGetTicket(i)>0){
         if(OrderGetInteger(ORDER_MAGIC)==id){
            return false;
         }
      }
   }
   for(int i=0;i<PositionsTotal();i++){
      if(PositionGetTicket(i) > 0){
         if(PositionGetInteger(POSITION_MAGIC) == id){
            return false;
         }
      }
   }
   return true;  
}

double calculate_lotsize(string symbol){
   int lot_digits;
   double min_lot_size = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max_lot_size = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   
   if(min_lot_size == 0.001){
      lot_digits = 3;
   }else if(min_lot_size == 0.01){
      lot_digits = 2;
   }else{
      lot_digits = 1;
   }   
   
   static double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double exchange_rate = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE) * (account_balance * (risk_percentage/100));
   double lot_size = NormalizeDouble(exchange_rate/sl_pips, lot_digits);
   
   if (lot_size>=max_lot_size){
      lot_size = max_lot_size;
   }
   if (lot_size<min_lot_size){ 
      lot_size = min_lot_size;
   }   
   
   return lot_size;
}
//bool check_trend(string symbol, string operation, double price){
void check_trend(string symbol, string operation, double price){
   int ima_30m = iMA(symbol, PERIOD_M30, 200, 0, MODE_SMA, PRICE_CLOSE);
   int ima_1h = iMA(symbol, PERIOD_H1, 200, 0, MODE_SMA, PRICE_CLOSE);
   int ima_2h = iMA(symbol, PERIOD_H2, 200, 0, MODE_SMA, PRICE_CLOSE);
   int ima_4h = iMA(symbol, PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE);
   
   if(operation == "BUY"){
      if(price > ima_30m && price > ima_1h && price > ima_2h && price > ima_4h){
         Print("BUY trend for ", symbol);
         //return true;
      }else{
         if(price > ima_30m){
            Print("NOT BUY 30m trend for ", symbol);
         }else{
            Print("BUY trend 30m for ", symbol);
         }
         if(price > ima_1h){
            Print("NOT BUY 1h trend for ", symbol);
         }else{
            Print("BUY trend 1h for ", symbol);
         }
         if(price > ima_2h){
            Print("NOT BUY 2h trend for ", symbol);
         }else{
            Print("BUY trend 2h for ", symbol);
         }
         if(price > ima_4h){
            Print("NOT BUY 4h trend for ", symbol);
         }else{
            Print("BUY trend 4h for ", symbol);
         }
      }
   }else{
      if(price < ima_30m && price < ima_1h && price < ima_2h && price < ima_4h){
         Print("SELL trend for ", symbol);
         //return true;
      }else{
         if(price < ima_30m){
            Print("NOT SELL 30m trend for ", symbol);
         }else{
            Print("SELL trend 30m for ", symbol);
         }
         if(price < ima_1h){
            Print("NOT SELL 1h trend for ", symbol);
         }else{
            Print("SELL trend 1h for ", symbol);
         }
         if(price < ima_2h){
            Print("NOT SELL 2h trend for ", symbol);
         }else{
            Print("SELL trend 2h for ", symbol);
         }
         if(price < ima_4h){
            Print("NOT SELL 4h trend for ", symbol);
         }else{
            Print("SELL trend 4h for ", symbol);
         }
      }
   }
   //return false;
}
