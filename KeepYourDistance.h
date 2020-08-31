#ifndef KeepYourDistance_H
#define KeepYourDistance_H

typedef nx_struct radio_msg {
  nx_uint16_t senderId;
} radio_msg_t;

enum {
	AM_RADIO_COUNT_MSG = 6, TIMER_2HZ = 500,
};


#endif
