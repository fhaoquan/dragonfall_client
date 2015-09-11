APP_STL := gnustl_static

APP_CPPFLAGS := -frtti -DCC_ENABLE_CHIPMUNK_INTEGRATION=1 -std=c++11 -fsigned-char
APP_LDFLAGS := -latomic

COCOSTUDIO_JSON_USE_CONFIG_PNG_FILE := 1
USE_ETC1_TEXTURE_WITH_ALPHA_DATA := 1
CC_USE_CCBUILDER := 0
CC_USE_3D := 0
CC_USE_SQLITE := 0
CC_USE_PHYSICS := 0
CC_USE_SIMULATOR := 0

ifeq ($(CC_USE_SIMULATOR),1)
APP_CPPFLAGS += -DCC_USE_SIMULATOR=1
endif

ifeq ($(CC_USE_CCBUILDER),1)
APP_CPPFLAGS += -DCC_USE_CCBUILDER=1
endif

ifeq ($(CC_USE_3D),1)
APP_CPPFLAGS += -DCC_USE_3D=1
endif

ifeq ($(CC_USE_SQLITE),1)
APP_CPPFLAGS += -DCC_USE_SQLITE=1
endif

ifeq ($(CC_USE_PHYSICS),1)
APP_CPPFLAGS += -DCC_USE_PHYSICS=1
endif

ifeq ($(COCOSTUDIO_JSON_USE_CONFIG_PNG_FILE),1)
APP_CPPFLAGS += -DCOCOSTUDIO_JSON_USE_CONFIG_PNG_FILE
endif

ifeq ($(USE_ETC1_TEXTURE_WITH_ALPHA_DATA),1)
APP_CPPFLAGS += -DUSE_ETC1_TEXTURE_WITH_ALPHA_DATA=1
endif

ifeq ($(NDK_DEBUG),1)
  APP_CPPFLAGS += -DCOCOS2D_DEBUG=1
  APP_OPTIM := debug
else
  APP_CPPFLAGS += -DNDEBUG
  APP_OPTIM := release
endif
