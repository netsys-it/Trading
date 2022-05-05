//+------------------------------------------------------------------+
//|                                                   PostSignal.mq4 |
//|                                              Ing. Daniel Plaskúr |
//|                                               https://plaskur.sk |
//+------------------------------------------------------------------+
#property copyright "Ing. Daniel Plaskúr"
#property link      "https://plaskur.sk"
#property version   "1.00"
#property strict
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
void OnTick(){
//---
   CheckOrders();
}
//+------------------------------------------------------------------+
void CheckOrders(){
   int res;
   int timeout = 500;
   string order_type;
   string result_headers;
   string url = "http://example.com";
   string headers = "Content-Type: application/json\r\n";
   string json_string = "{\"signals\": {";
   char result[];
   char post_data[];
   
   for(int i=0;i<OrdersTotal();i++){
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         if(OrderType() == 0){
            order_type = "BUY";
         }else{
            order_type = "SELL";
         }
         json_string += "\""+IntegerToString(OrderTicket())+"\": {\"signal_date\":\""+TimeToString(OrderOpenTime())+"\",\"signal_symbol\":\""+OrderSymbol()+"\",\"signal_price\":"+DoubleToString(OrderOpenPrice())+",\"signal_lots\":"+DoubleToString(OrderLots())+",\"signal_type\":\""+order_type+"\"";
         if(i == OrdersTotal()-1){
            json_string += "}";
         }else{
            json_string += "},";
         }
      }
   }
   json_string += "}}";
   
   StringToCharArray(json_string, post_data, 0, StringLen(json_string));
   
   res = WebRequest("POST", url, headers, timeout, post_data, result, result_headers);
}
