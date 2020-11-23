//+------------------------------------------------------------------+
//|                                               LondonBreakout.mq4 |
//|                        Copyright 2020, Daniel Plaskúr Software.  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Daniel Plaskúr Software"
#property link      ""
#property version   "1.00"
#property strict
#property show_inputs
bool CanTradeBuy = true;
bool CanTradeSell = true;
int ticket;
double min = 2;
double max = 0;
double LotSize = 0;
double Price = 0.0;
double StopLoss = 0.0;
double TakeProfit = 0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   // Dynamicky TP a SL + vymazanie neaktivnych objednavok.
   if(OrdersTotal() > 1){
     TrailingStop();
     CloseOrders();
   }
   
   // Ak bola 10 hodina, tak najdi max a min z poslednych 3 sviecok
   if(Hour() == 10 && Minute() == 0){
      for(int i=1;i<=3;i++){
         if(max < iHigh(Symbol(), PERIOD_H1, i)){
            max = iHigh(Symbol(), PERIOD_H1, i);
         }
         if(min > iLow(Symbol(), PERIOD_H1, i)){
            min = iLow(Symbol(), PERIOD_H1, i);
         }
      }
   }

   // Vytvorenie BUY objednavky.
   if(Hour() >= 10 && max != 0 && CanTradeBuy){
   // TODO stop loss a lot size prepocitat
      TakeProfit = max + 130 * Point();
      StopLoss = max - (2* iATR(Symbol(), PERIOD_H1, 14, 0));
      LotSize = (2* iATR(Symbol(), PERIOD_H1, 14, 0)) * 10000;
      Price = max;
      ticket = OrderSend(Symbol(), OP_BUYSTOP, LotSize, Price, 3, StopLoss, TakeProfit, "London breakout BUYSTOP", 0, 0, clrGreen);
      if(ticket<0){
         Print("OrderSend failed with error #", GetLastError());
      }else{
         Print("OrderSend placed successfully");
      }
      CanTradeBuy = false;
   }
   
   // Vytvorenie SELL objednavky.
   if(Hour() >= 10 && min != 2 && CanTradeSell){
      TakeProfit = min - 130 * Point();
      StopLoss = min + (2* iATR(Symbol(), PERIOD_H1, 14, 0));
      LotSize = (2* iATR(Symbol(), PERIOD_H1, 14, 0)) * 10000;
      Price = min;
      ticket = OrderSend(Symbol(), OP_SELLSTOP, LotSize, Price, 3, StopLoss, TakeProfit, "London breakout SELLSTOP", 0, 0, clrRed);
      if(ticket<0){
         Print("OrderSend failed with error #", GetLastError());
      }else{
         Print("OrderSend placed successfully");
      }
      CanTradeSell = false;
   }
}
//+------------------------------------------------------------------+
//| Calculate Lot size from Stop Loss function                       |
//+------------------------------------------------------------------+
double CalculateLotSize(double SL){
   double AccBalance = 3000;
   double MaxRiskPerTrade = 2;
   //We get the value of a tick
   double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   //If the digits are 3 or 5 we normalize multiplying by 10
   if(Digits == 3 || Digits == 5){
      nTickValue = nTickValue*10;
   }
   //We apply the formula to calculate the position size and assign the value to the variable
   LotSize = (AccBalance * (MaxRiskPerTrade / 100))/(SL*nTickValue);
   LotSize = MathRound(LotSize/MarketInfo(Symbol(), MODE_LOTSTEP))*MarketInfo(Symbol(), MODE_LOTSTEP);
   return LotSize;
}
//+------------------------------------------------------------------+
//| Trailing Take profit and Stop Loss function                      |
//+------------------------------------------------------------------+
void TrailingStop(){
   bool res;
   for(int i=0;i<OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         if(OrderType() == OP_BUY && OrderSymbol() == Symbol()){
            if(Ask > OrderOpenPrice() + (100 * Point())){
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + (100 * Point()), OrderTakeProfit(), 0, clrNONE);
               if(!res){
                  Print("Error in OrderModify. Error code=", GetLastError());
               }else{
                  Print("Order modified successfully.");
               }
            }
            if(Ask > OrderTakeProfit() - 20 * Point()){
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), OrderTakeProfit() + (20 * Point()), 0, clrNONE);
               if(!res){
                  Print("Error in OrderModify. Error code=", GetLastError());
               }else{
                  Print("Order modified successfully.");
               }
            }
         }else if(OrderType() == OP_SELL && OrderSymbol() == Symbol()){
            if(Bid < OrderOpenPrice() - (100 * Point())){
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - (100 * Point()), OrderTakeProfit(), 0, clrNONE);
               if(!res){
                  Print("Error in OrderModify. Error code=", GetLastError());
               }else{
                  Print("Order modified successfully.");
               }
            }
           if(Bid < OrderTakeProfit() + 20 * Point()){
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), OrderTakeProfit() - (20 * Point()), 0, clrNONE);
               if(!res){
                  Print("Error in OrderModify. Error code=", GetLastError());
               }else{
                  Print("Order modified successfully.");
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
//| Close inactive orders                                            |
//+------------------------------------------------------------------+
void CloseOrders(){
   bool res;
   if(Hour() >= 11){
      for(int i=0;i<OrdersTotal(); i++){
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
            if(OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT){
               res = OrderDelete(OrderTicket());
               if(!res){
                  Print("Error in OrderDelete. Error code=", GetLastError());
               }else{
                  Print("Order deleted successfully.");
               }
            }
         }
      }
   }
}
