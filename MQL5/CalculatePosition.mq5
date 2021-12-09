//+------------------------------------------------------------------+
//|                                            CalculatePosition.mq5 |
//|                                                   Daniel Plaskur |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Daniel Plaskur"
#property link      "https://www.mql5.com"
#property version   "1.01"
#property script_show_inputs
input double open_price;
input double stop_loss;
input double risk_percentage = 1;
input double risk_reward = 1;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
//---
   Print(CalculateLotsize(open_price, stop_loss));
   Print(CalculateRR());
}
//+------------------------------------------------------------------+

double CalculateLotsize(double price, double sl){
   int lot_digits;
   int sl_pips;
   double min_lot_size = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot_size = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   if(min_lot_size == 0.001){
      lot_digits = 3;
   }else if(min_lot_size == 0.01){
      lot_digits = 2;
   }else{
      lot_digits = 1;
   }
   
   if(SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5){
      sl_pips = (int)(MathAbs(price - sl) * 100000);
   }else{
      sl_pips = (int)(MathAbs(price - sl) * 1000);
   }
   
   static double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double exchange_rate = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * (account_balance * (risk_percentage/100));
   double lot_size = NormalizeDouble(exchange_rate/sl_pips, lot_digits);
   
   if (lot_size >= max_lot_size){
      lot_size = max_lot_size;
   }
   if (lot_size < min_lot_size){ 
      lot_size = min_lot_size;
   }   
   
   return lot_size;
}

double CalculateRR(){
   double take_profit;
   double add_to_price = MathAbs(open_price - stop_loss);
   
   if(open_price > stop_loss){
      take_profit = open_price + (add_to_price * risk_reward);
   }else{
      take_profit = open_price - (add_to_price * risk_reward);
   }
   
   return take_profit;
}
