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
                  order_request.magic=id;
                  order_request.symbol=symbol;
                  order_request.volume=calculate_lotsize(symbol);
                  order_request.sl=sl;
                  order_request.tp=tp_1;                  
                  order_request.price=price;
                  order_request.type_time=ORDER_TIME_SPECIFIED;
                  order_request.expiration=TimeCurrent()+PeriodSeconds(PERIOD_H4);
                  MqlTradeResult order_result={};
                                 
                  if(!OrderSend(order_request, order_result)){
                     PrintFormat("OrderSend error %d",GetLastError());
                  }
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
   static double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double exchange_rate = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE) * (account_balance * (risk_percentage/100));
   return exchange_rate/sl_pips;
}
