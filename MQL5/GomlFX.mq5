//+------------------------------------------------------------------+
//|                                                       GomlFX.mq5 |
//|                                                   Daniel Plaskur |
//|                                               https://plaskur.sk |
//+------------------------------------------------------------------+
#property copyright "Daniel Plaskur"
#property link      "https://plaskur.sk"
#property version   "1.03"
#property script_show_inputs
#include <jason.mqh>
input double risk_percentage = 1;
input double risk_reward = 1;
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
      CheckSignals();
  }
//+------------------------------------------------------------------+

void CheckSignals(){
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
         	   if(TradesFilter(id)){
         	        string symbol = jv["signals"][i]["symbol"].ToStr();        
                  if(EconomicFilter(symbol)){
                    string operation = jv["signals"][i]["operation"].ToStr();
                  	double price; //= jv["signals"][i]["price"].ToDbl();
                  	double tp_1 = jv["signals"][i]["tp_1"].ToDbl();
                  	double sl = jv["signals"][i]["sl"].ToDbl();
                  	
                  	double symbol_point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
                  	MqlTradeRequest order_request={};
                  	               	
                  	//order_request.action = TRADE_ACTION_PENDING;
                  	order_request.action = TRADE_ACTION_DEAL;
                  	if(operation == "BUY"){
                  	   /*
                  	    order_request.type = ORDER_TYPE_BUY_LIMIT;
                  	    if(symbol_point == 0.00001){
                           price = price - 0.001;
                        }else if(symbol_point == 0.001){
                           price = price - 0.1;
                        }
                        */
                        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
                        order_request.type = ORDER_TYPE_BUY;
                        order_request.price = price;
                  	}else{
                  	   /*
                  	    order_request.type = ORDER_TYPE_SELL_LIMIT;
                  	    if(symbol_point == 0.00001){
                           price = price + 0.001;
                        }else if(symbol_point == 0.001){
                           price = price + 0.1;
                        }
                        */
                        price = SymbolInfoDouble(symbol, SYMBOL_BID);
                        order_request.type = ORDER_TYPE_SELL;
                        order_request.price = price;
                  	}
                  	double lot_size = CalculateLotsize(symbol, price,  sl);
                  	double tp = CalculateTP(price, sl);
                  	
                    order_request.magic=id;
                    order_request.symbol=symbol;
                    order_request.volume=lot_size;
                    order_request.sl=sl;
                    order_request.tp=tp;
                    order_request.deviation=5; // allowed deviation from the price
                    //order_request.price=price;
                    //order_request.type_time=ORDER_TIME_SPECIFIED;
                    //order_request.expiration=TimeCurrent()+PeriodSeconds(PERIOD_H4);
                    MqlTradeResult order_result={};
                     
                    // if(TrendFilter(symbol, operation, price)){
                       if(!OrderSend(order_request, order_result)){
                           // https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes
                           PrintFormat("retcode= %d",order_result.retcode);
                           PrintFormat("OrderSend error %d", GetLastError());
                           Print("symbol=", symbol, " operation=", operation, " price=", price, " tp=", tp_1, " sl=", sl, " lotsize=", lot_size);
                        }
                    // }
                  }
         	    }
         	  }else{
         	    continue;
         	  }
          }         
      }
   }
}

bool TradesFilter(long id){
   for(int i=0;i<OrdersTotal();i++){
      if(OrderGetTicket(i)>0){
         if(OrderGetInteger(ORDER_MAGIC) == id){
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

double CalculateLotsize(string symbol, double price, double sl){
   int lot_digits;
   int sl_pips;
   double min_lot_size = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max_lot_size = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   
   if(min_lot_size == 0.001){
      lot_digits = 3;
   }else if(min_lot_size == 0.01){
      lot_digits = 2;
   }else{
      lot_digits = 1;
   }
   
   if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5){
      sl_pips = (int)(MathAbs(price - sl) * 100000);
   }else{
      sl_pips = (int)(MathAbs(price - sl) * 1000);
   }
   
   static double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double exchange_rate = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE) * (account_balance * (risk_percentage/100));
   double lot_size = NormalizeDouble(exchange_rate/sl_pips, lot_digits);
   
   if (lot_size >= max_lot_size){
      lot_size = max_lot_size;
   }
   if (lot_size < min_lot_size){ 
      lot_size = min_lot_size;
   }   
   
   return lot_size;
}

bool TrendFilter(string symbol, string operation, double price){
   double ma_4h_200[];
   double ma_4h_50[];
   double ma_4h_21[];
   double ma_2h_200[];
   double ma_2h_50[];
   double ma_2h_21[];
   double ma_1h_200[];
   double ma_1h_50[];
   double ma_1h_21[];
   int handle_4h_200 = iMA(symbol, PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE);
   int handle_4h_50 = iMA(symbol, PERIOD_H4, 50, 0, MODE_SMA, PRICE_CLOSE);
   int handle_4h_21 = iMA(symbol, PERIOD_H4, 21, 0, MODE_SMA, PRICE_CLOSE);
   int handle_2h_200 = iMA(symbol, PERIOD_H2, 200, 0, MODE_SMA, PRICE_CLOSE);
   int handle_2h_50 = iMA(symbol, PERIOD_H2, 50, 0, MODE_SMA, PRICE_CLOSE);
   int handle_2h_21 = iMA(symbol, PERIOD_H2, 21, 0, MODE_SMA, PRICE_CLOSE);
   int handle_1h_200 = iMA(symbol, PERIOD_H1, 200, 0, MODE_SMA, PRICE_CLOSE);
   int handle_1h_50 = iMA(symbol, PERIOD_H1, 50, 0, MODE_SMA, PRICE_CLOSE);
   int handle_1h_21 = iMA(symbol, PERIOD_H1, 21, 0, MODE_SMA, PRICE_CLOSE);
     
   if(handle_4h_200 == INVALID_HANDLE || handle_4h_50 == INVALID_HANDLE || handle_4h_21 == INVALID_HANDLE || handle_2h_200 == INVALID_HANDLE || handle_2h_50 == INVALID_HANDLE || handle_2h_21 == INVALID_HANDLE || handle_1h_200 == INVALID_HANDLE || handle_1h_50 == INVALID_HANDLE || handle_1h_21 == INVALID_HANDLE){
      PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s, error code %d",
                  symbol,
                  GetLastError());
   }
   
   ResetLastError();
   if(CopyBuffer(handle_4h_200, 0, 0, 1, ma_4h_200) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle_4h_50, 0, 0, 1, ma_4h_50) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle_4h_21, 0, 0, 1, ma_4h_21) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle_2h_200, 0, 0, 1, ma_2h_200) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle_2h_50, 0, 0, 1, ma_2h_50) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle_2h_21, 0, 0, 1, ma_2h_21) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle_1h_200, 0, 0, 1, ma_1h_200) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle_1h_50, 0, 0, 1, ma_1h_50) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle_1h_21, 0, 0, 1, ma_1h_21) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   
   if(operation == "BUY"){
      if(ma_4h_21[0] > ma_4h_50[0] && ma_4h_50[0] > ma_4h_200[0]){
         if(ma_2h_21[0] > ma_2h_50[0] && ma_2h_50[0] > ma_2h_200[0]){
            if(ma_1h_21[0] > ma_1h_50[0] && ma_1h_50[0] > ma_1h_200[0]){
               return true;
            }
         }      
      }
   }else{
      if(ma_4h_21[0] < ma_4h_50[0] && ma_4h_50[0] < ma_4h_200[0]){
         if(ma_2h_21[0] < ma_2h_50[0] && ma_2h_50[0] < ma_2h_200[0]){
            if(ma_1h_21[0] < ma_1h_50[0] && ma_1h_50[0] < ma_1h_200[0]){
               return true;
            }
         }      
      }
   }
   
   return false;
}

bool EconomicFilter(string symbol){
   string currency_1 = StringSubstr(symbol, 0, 3);
   string currency_2 = StringSubstr(symbol, 3, 3);

   MqlCalendarValue values_1[];
   MqlCalendarValue values_2[];
   
   datetime date_from = TimeCurrent(); 
   datetime date_to = date_from + (8*60*60);
   if(CalendarValueHistory(values_1, date_from, date_to, NULL, currency_1)){
      for(int i=0;i<ArraySize(values_1);i++){
         MqlCalendarEvent event; 
         ulong event_id = values_1[i].event_id;
         if(CalendarEventById(event_id, event)){
            if (event.importance > 2 && event.time_mode == CALENDAR_TIMEMODE_DATETIME){
               return false;
            }
         }
      }
   }
   if(CalendarValueHistory(values_2, date_from, date_to, NULL, currency_2)){
      for(int i=0;i<ArraySize(values_2);i++){
         MqlCalendarEvent event; 
         ulong event_id = values_2[i].event_id;
         if(CalendarEventById(event_id, event)){
            if (event.importance > 2 && event.time_mode == CALENDAR_TIMEMODE_DATETIME){
               return false;
            }
         }
      }
   }
      
   return true;
}

double CalculateTP(double price, double sl){
   double take_profit;
   double add_to_price = MathAbs(price - sl);
   
   if(price > sl){
      take_profit = price + (add_to_price * risk_reward);
   }else{
      take_profit = price - (add_to_price * risk_reward);
   }
   
   return take_profit;
}
