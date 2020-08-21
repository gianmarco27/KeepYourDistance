#include "Timer.h"
#include "KeepYourDistance.h"


module RadioC1 @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}

implementation {
	message_t packet;
	
	bool locked;
	uint16_t counter = 0;

	struct encounter *encounters = (struct encounter *) malloc(sizeof(struct encounter));
  encounters->next = NULL;
  

	event void Boot.booted() {
		call AMControl.start();
	}
	
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
  		call MilliTimer.startPeriodic(TIMER_2HZ);
    } else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  	
  event void MilliTimer.fired() {
  dbg("KeepYourDistance", "KeepYourDistance: timer fired, id is %hu.\n", TOS_NODE_ID);
    if (locked) {
      return;
    } else {
      	radio_c1_msg_t* rcm = (radio_c1_msg_t*)call Packet.getPayload(&packet, sizeof(radio_c1_msg_t));
		  if (rcm == NULL) {
			return;
		  }
      
		  rcm->counter = counter;
		  rcm->senderId = TOS_NODE_ID;
		  if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_c1_msg_t)) == SUCCESS) {
			dbg("RadioC1C", "RadioC1C: packet sent.\n");	
			locked = TRUE;
  	  	  }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
	dbg("RadioC1", "Received packet of length %hhu.\n", len);
	if (len != sizeof(radio_c1_msg_t)) {
		return bufPtr;
	} else {
		radio_c1_msg_t* rcm = (radio_c1_msg_t*)payload;
		counter = (rcm->counter);
		counter++;
		if(counter%10 == 0){
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();
		} else {
			if(rcm->senderId & 0x1) {
					call Leds.led0Toggle();
			} else {
				if(rcm->senderId & 0x2){
					call Leds.led1Toggle();
				} else {
					if(rcm->senderId & 0x3){
						call Leds.led2Toggle();
					}
				}
			}

		}	
		return bufPtr;
	}
  }


  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
  
  
}






