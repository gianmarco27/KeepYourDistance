#ifndef KeepYourDistance_H
#define KeepYourDistance_H

typedef nx_struct radio_c1_msg {
  nx_uint16_t counter;
  nx_uint16_t senderId;
} radio_c1_msg_t;

typedef nx_struct encounter {
  nx_uint16_t counter;
  nx_uint16_t senderId;
  nx_struct encounter *next;
};

enum {
	AM_RADIO_COUNT_MSG = 6, TIMER_2HZ = 500,
};


#endif
