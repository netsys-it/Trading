//+------------------------------------------------------------------+
//|                                                   CheckTrend.mq5 |
//|                                                   Daniel Plaskur |
//|                                               https://plaskur.sk |
//+------------------------------------------------------------------+
#property copyright "Daniel Plaskur"
#property link      "https://plaskur.sk"
#property version   "1.03"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
//---
   CheckTrading();
}

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

string TrendSignal(string symbol){
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
   
   if(ma_4h_21[0] > ma_4h_50[0] && ma_4h_50[0] > ma_4h_200[0]){
      if(ma_2h_21[0] > ma_2h_50[0] && ma_2h_50[0] > ma_2h_200[0]){
         if(ma_1h_21[0] > ma_1h_50[0] && ma_1h_50[0] > ma_1h_200[0]){
            return "BUY";
         }
      }      
   }
   if(ma_4h_21[0] < ma_4h_50[0] && ma_4h_50[0] < ma_4h_200[0]){
      if(ma_2h_21[0] < ma_2h_50[0] && ma_2h_50[0] < ma_2h_200[0]){
         if(ma_1h_21[0] < ma_1h_50[0] && ma_1h_50[0] < ma_1h_200[0]){
            return "SELL";
         }
      }      
   }

   return "None";
}

string MACDSignal(string symbol){
   double macd_buffer[];
   double signal_buffer[];
   
   SetIndexBuffer(0, macd_buffer, INDICATOR_DATA);
   SetIndexBuffer(1, signal_buffer, INDICATOR_DATA);
   
   int handle = iMACD(symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE);
   if(handle == INVALID_HANDLE){
      PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s, error code %d",
                  symbol,
                  GetLastError());
   }
   
   ResetLastError();
   if(CopyBuffer(handle, 0, 0, 2, macd_buffer) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   if(CopyBuffer(handle, 1, 0, 2, signal_buffer) < 0){
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d", GetLastError());
   }
   
   if(signal_buffer[0] < macd_buffer[0] && signal_buffer[1] > macd_buffer[1] && macd_buffer[0] > macd_buffer[1] && signal_buffer[0] > signal_buffer[1]){
      return "BUY";
   }else if(signal_buffer[0] > macd_buffer[0] && signal_buffer[1] < macd_buffer[1] && macd_buffer[0] < macd_buffer[1] && signal_buffer[0] < signal_buffer[1]){
      return "SELL";
   }

   return "None";
}

void CheckTrading(){
   for(int i=0;i<SymbolsTotal(true);i++){
      string symbol = SymbolName(i, 1);
      
      if(FilterEconomicEvents(symbol)){
         string macd_signal = MACDSignal(symbol);
         string trend_signal = TrendSignal(symbol);
         
         if(trend_signal != "None"){
            PrintFormat("Symbol: %s, Trend Signal: %s, MACD Signal: %s", symbol, trend_signal, macd_signal);
         }
      }
   }
}
