//+------------------------------------------------------------------+
//|                                                   CheckTrend.mq5 |
//|                                                   Daniel Plaskur |
//|                                               https://plaskur.sk |
//+------------------------------------------------------------------+
#property copyright "Daniel Plaskur"
#property link      "https://plaskur.sk"
#property version   "1.02"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
//---
   FilterTrend();
}
//+------------------------------------------------------------------+
bool FilterEconomicEvents(string symbol){
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

void FilterTrend(){
   for(int i=0;i<SymbolsTotal(true);i++){
      string symbol = SymbolName(i, 1);

      if(FilterEconomicEvents(symbol)){
         int ima_1h = iMA(symbol, PERIOD_H1, 200, 0, MODE_SMA, PRICE_CLOSE);
         int ima_2h = iMA(symbol, PERIOD_H2, 200, 0, MODE_SMA, PRICE_CLOSE);
         int ima_4h = iMA(symbol, PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE);
         
         MqlTick Latest_Price;
         static double ask_price = Latest_Price.ask;
         static double bid_price = Latest_Price.bid;
                  
         if(ask_price > ima_1h && ask_price > ima_2h && ask_price > ima_4h){
            Alert("BUY trend for ", symbol);
            FilterMACD(symbol, "BUY");
         }
         if(bid_price < ima_1h && bid_price < ima_2h && bid_price < ima_4h){
            Alert("SELL trend for ", symbol);
            FilterMACD(symbol, "SELL");
         }
      }
   }
}

void FilterMACD(string symbol, string operation){
   double MACDBuffer[];
   double SignalBuffer[];
   
   SetIndexBuffer(0, MACDBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, SignalBuffer, INDICATOR_DATA);
   
   int handle = iMACD(symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE);
   if(handle == INVALID_HANDLE){
      PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s, error code %d",
                  symbol,
                  GetLastError());
   }
   
   ResetLastError();
   if(CopyBuffer(handle, 0, 0, 2, MACDBuffer) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle, 1, 0, 2, SignalBuffer) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   
   if(SignalBuffer[0] < MACDBuffer[0] && SignalBuffer[1] > MACDBuffer[1] && MACDBuffer[0] > MACDBuffer[1] && SignalBuffer[0] > SignalBuffer[1]){
      if(operation == "BUY"){
         Alert("BUY MACD");   
      }
   }else if(SignalBuffer[0] > MACDBuffer[0] && SignalBuffer[1] < MACDBuffer[1] && MACDBuffer[0] < MACDBuffer[1] && SignalBuffer[0] < SignalBuffer[1]){
      if(operation == "SELL"){
         Alert("SELL MACD");   
      }
   }
}
