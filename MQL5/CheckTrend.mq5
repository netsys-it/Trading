//+------------------------------------------------------------------+
//|                                                   CheckTrend.mq5 |
//|                                                   Daniel Plaskur |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Daniel Plaskur"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs
input string economic_symbols = "EUR,USD";
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   string result[];
   string separator = ",";
   ushort u_sep = StringGetCharacter(separator, 0);
   int total = StringSplit(economic_symbols, u_sep, result);
   bool economic_flag = true;
   for(int i=0;i<SymbolsTotal(true);i++){
      for(int j=0;j<total;j++){
         if(StringFind(SymbolName(i, 1), result[j]) >= 0){
            economic_flag = false;
            break;
         }
      }
      if(economic_flag){
         string symbol = SymbolName(i, 1);
         int ima_1h = iMA(symbol, PERIOD_H1, 200, 0, MODE_SMA, PRICE_CLOSE);
         int ima_2h = iMA(symbol, PERIOD_H2, 200, 0, MODE_SMA, PRICE_CLOSE);
         int ima_4h = iMA(symbol, PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE);
         
         MqlTick Latest_Price;
         static double ask_price = Latest_Price.ask;
         static double bid_price = Latest_Price.bid;
                  
         if(ask_price > ima_1h && ask_price > ima_2h && ask_price > ima_4h){
            Alert("BUY trend for ", symbol);
         }
         if(bid_price < ima_1h && bid_price < ima_2h && bid_price < ima_4h){
            Alert("SELL trend for ", symbol);
         }
      }
      economic_flag = true;
   }
  }
//+------------------------------------------------------------------+
