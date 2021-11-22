//+------------------------------------------------------------------+
//|                                                       YoloFX.mq5 |
//|                                                   Daniel Plaskur |
//|                                               https://plaskur.sk |
//+------------------------------------------------------------------+
#property copyright "Daniel Plaskur"
#property link      "https://plaskur.sk"
#property version   "1.00"
#include <jason.mqh>
long ids[10];
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
   string cookie = NULL;
   string referer = NULL;
   int timeout = 500;
   string headers = "Content-Type: application/json\r\n";;
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
               	
               	//--- Send order
               	MqlTradeRequest order_request={};
               	
               	if(operation == "BUY"){
               	   order_request.type = ORDER_TYPE_BUY;
               	}else{
               	   order_request.type = ORDER_TYPE_SELL;
               	}
               	            	
               	order_request.action=TRADE_ACTION_PENDING;
                  order_request.magic=0;
                  order_request.symbol=symbol;
                  order_request.volume=0.1;
                  order_request.sl=sl;
                  order_request.tp=tp_1;
                  order_request.price=price;
                  
                  MqlTradeResult order_result={};
                                 
                  if(!OrderSend(order_request, order_result)){
                     PrintFormat("OrderSend error %d",GetLastError());
                  }
               	//--- End Send order
         	   }
         	}else{
         	   break;
         	}
          }         
      }
   }
}

bool canTrade(long id){
   for(int i=0;i<ArraySize(ids);i++){
     if(ids[i] == id){
        return false;
     }else if(ids[i] == 0){
         ids[i] = id;
         return true;
     }else if(ids[ArraySize(ids)-1]!=0){
         ids[0] = 0;
         return false;
     }
   }
   return false;
}
