                                       "OLT property"               "OLT description"                       "OLT device type"                       "OLT up time"                       �"
     The device stype of either fixed or chassis basedT        
     fixed(1) - such as pizza box
     chassisBased(2) - Have number of slots for installing service card, power card, etc.        
     "                       "board info table"                       "BoardEntry table"                       "slot Index"                       " down:0   up:1"                      c"config type
	  typedef enum
	  {
	    BOARD_TYPE_NULL = 0,
	    BOARD_TYPE_CONTROL_BCM5670,
	    BOARD_TYPE_LINE_24_GE_FIBER_BCM56504,
	    BOARD_TYPE_LINE_24_GE_COPPER_BCM56504,
	    BOARD_TYPE_LINE_24_GE_COPPER_BCM56524, 
	    BOARD_TYPE_LINE_4_10GE_FIBER_BCM56628,
	    BOARD_TYPE_LINE_8PON_6GE_BCM56524,
	    BOARD_TYPE_NUM
	  }BOARD_TYPE"                      a"true type
	  typedef enum
	  {
	    BOARD_TYPE_NULL = 0,
	    BOARD_TYPE_CONTROL_BCM5670,
	    BOARD_TYPE_LINE_24_GE_FIBER_BCM56504,
	    BOARD_TYPE_LINE_24_GE_COPPER_BCM56504,
	    BOARD_TYPE_LINE_24_GE_COPPER_BCM56524, 
	    BOARD_TYPE_LINE_4_10GE_FIBER_BCM56628,
	    BOARD_TYPE_LINE_8PON_6GE_BCM56524,
	    BOARD_TYPE_NUM
	  }BOARD_TYPE"                       "software version"                       "hardware version"                       "reset"                                                      