#include "Timer.h"
#include "KeepYourDistance.h"
#include "printf.h"

module KeepYourDistance @safe() {
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
  uint16_t last_encounter = 0;

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
    printf("DEBUG : id %d. Timer fired\n", TOS_NODE_ID);
    dbg("KeepYourDistance_Radio", "KeepYourDistance: id %d. Timer fired\n", TOS_NODE_ID);

    if (locked) {
      return;
    } else {
      	radio_msg_t* rcm = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
		  if (rcm == NULL) {
			return;
		  }
		  rcm->senderId = TOS_NODE_ID;
		  if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t)) == SUCCESS) {
			    printf("DEBUG : id %d. Broadcasted Presence\n", TOS_NODE_ID);
          printfflush();  
          dbg("KeepYourDistance_Radio", "KeepYourDistance: id %d. Broadcasted Presence\n", TOS_NODE_ID);	
    			locked = TRUE;
          return;
  	  }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
  	dbg("KeepYourDistance_Radio", "Received packet of length %hhu.\n", len);
  	if (len != sizeof(radio_msg_t)) {
  		return bufPtr;
  	} else {

  		radio_msg_t* rcm = (radio_msg_t*)payload;
      if (rcm == NULL) {
        return bufPtr;
      }

      last_encounter = rcm->senderId;
  		if(last_encounter > 0){
        printf("DEBUG : id %d. Entered in range of MoteId = %d. Communicating proximity to NODE-RED\n", TOS_NODE_ID, last_encounter);
        dbg("KeepYourDistance_Radio", "KeepYourDistance: id %d. Entered in range of MoteId = %d. Communicating proximity to NODE-RED\n", TOS_NODE_ID, last_encounter);
        printf("close to:%d\n", last_encounter);
        printfflush();
  		} else {
        dbg("KeepYourDistance_Radio", "KeepYourDistance: id %d. Received rcm->senderId = %d.\n", TOS_NODE_ID, last_encounter);
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






