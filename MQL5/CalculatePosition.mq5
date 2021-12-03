//+------------------------------------------------------------------+
//|                                            CalculatePosition.mq5 |
//|                                                   Daniel Plaskur |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Daniel Plaskur"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs
input double open_price;
input double stop_loss;
input double risk_percentage = 1;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   Alert(calculate_lotsize());
  }
//+------------------------------------------------------------------+
double calculate_lotsize(){
   int lot_digits;
   double min_lot_size = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_lot_size = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
      
   if(min_lot_size == 0.001){
      lot_digits = 3;
   }else if(min_lot_size == 0.01){
      lot_digits = 2;
   }else{
      lot_digits = 1;
   }
   
   double stop_loss_pips;
   double symbol_point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);

   if(symbol_point == 0.00001){
      stop_loss_pips = MathAbs(open_price - stop_loss) * 100000;
   }else {
      stop_loss_pips = MathAbs(open_price - stop_loss) * 1000;
   }
   static double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double exchange_rate = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE) * (account_balance * (risk_percentage/100));
   double lot_size = NormalizeDouble(exchange_rate/stop_loss_pips, lot_digits);
   
   if (lot_size>=max_lot_size){
      lot_size = max_lot_size;
   }
   if (lot_size<min_lot_size){ 
      lot_size = min_lot_size;
   }   

   return lot_size;
}
