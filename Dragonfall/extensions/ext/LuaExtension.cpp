//
//  LuaExtension.cpp
//  battlefront
//
//  Created by Modun on 14-4-9.
//
//

#include "LuaExtension.h"
#include <iostream>
#include <stdio.h>
#include <string>
extern "C" {
    #include "tolua++.h"
}

#include "cocos2d.h"
#include "tolua_fix.h"
#include "LuaBasicConversions.h"
#include "base/ccUtils.h"
#include "tolua_fix.h"
#include "CCLuaValue.h"
#include "CCLuaStack.h"
#include "CCLuaEngine.h"

#define LOG_BUFFER_SIZE 1024 * 10 * 2

//extension header
#include "CommonUtils.h"
#include "crc/crc32.c"
#include "FileOperation.h"
#include "AppDelegate.h"
#include "tolua_sysmail.h"
#include "tolua_local_push.h"
//quick lua node
#include "../../external/lua/quick/LuaNodeManager.h"
//facebook
#if CC_USE_FACEBOOK
#include "tolua_fb_sdk.h"
#endif

//MARK:Android
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
#if CC_USE_POMELO_C_LIB
#include "CCPomelo.h"
#endif
#include "MarketSDKTool.h"
#include "jni_StoreKit.h"
#if CC_USE_SDK_PAYPAL
#include "PayPalSDK.h"
#endif
#if CC_USE_GOOGLE_LOGIN
#include "GoogleSignSDK.h"
#endif
#define KODLOG(format, ...) CCLOG(format, ##__VA_ARGS__);
//MARK:iOS
#elif CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#if CC_USE_POMELO_C_LIB
#include "CCPomelo.h"
#endif
#include "MarketSDKTool.h"
#include "GameCenter.h"
#define KODLOG(format, ...) CCLOG(format, ##__VA_ARGS__);Kodlog__(format, ##__VA_ARGS__);
//MARK:WinRT
#elif CC_TARGET_PLATFORM == CC_PLATFORM_WINRT
#include "audio/to_lua_simpleaudio.h"
#include "AdeasygoSDK/to_lua_adeasygo_helper.h"
#define KODLOG(format, ...) CCLOG(format, ##__VA_ARGS__);

#endif /* CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID */


#if CC_USE_POMELO_C_LIB
static void tolua_reg_pomelo_type(lua_State* tolua_S)
{
    tolua_usertype(tolua_S, "CCPomelo");
}

void Kodlog__(const char * format, ...)
{
    va_list args;
    va_start(args, format);
    char buf[LOG_BUFFER_SIZE];
    
    vsnprintf(buf, LOG_BUFFER_SIZE-3, format, args);
    strcat(buf, "\n");
    WriteLog_(buf);
    va_end(args);
}

static int tolua_CCPomelo_getInstance(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertable(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo* tolua_ret = (CCPomelo*)CCPomelo::getInstance();
		tolua_pushusertype(tolua_S, (void*)tolua_ret, "CCPomelo");
#endif
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'getInstance'.",&tolua_err);
    return 0;
#endif
}

static int tolua_CCPomelo_destroyInstance(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertable(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo::destroyInstance();
#endif
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'destroyInstance'.",&tolua_err);
    return 0;
#endif
}

static int tolua_CCPomelo_connect(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isstring(tolua_S, 2, 0, &tolua_err) ||
        !tolua_isnumber(tolua_S, 3, 0, &tolua_err) ||
        !toluafix_isfunction(tolua_S, 4, "LUA_FUNCTION", 0, &tolua_err) ||
        !tolua_isnoobj(tolua_S,4,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo* pomelo = static_cast<CCPomelo*>(tolua_tousertype(tolua_S, 1, 0));

#ifndef TOLUA_RELEASE
		if (nullptr == pomelo)
		{
			tolua_error(tolua_S, "invalid 'CCPomelo' in function 'tolua_CCPomelo_connect'\n", NULL);
			return 0;
		}
#endif
		const char* addr = tolua_tostring(tolua_S, 2, 0);
		int port = tolua_tonumber(tolua_S, 3, 0);
		LUA_FUNCTION func = toluafix_ref_function(tolua_S, 4, 0);
		KODLOG("trying connect %s:%d", addr, port);
		int status = pomelo->connect(addr, port);
		KODLOG("connect status:%d", status);
		auto stack = LuaEngine::getInstance()->getLuaStack();
		stack->pushBoolean(status == 0);
		stack->executeFunctionByHandler(func, 1);
#endif
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'tolua_CCPomelo_connect'.",&tolua_err);
    return 0;
#endif
}

static int tolua_CCPomelo_asyncConnect(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isstring(tolua_S, 2, 0, &tolua_err) ||
        !tolua_isnumber(tolua_S, 3, 0, &tolua_err) ||
        !toluafix_isfunction(tolua_S, 4, "LUA_FUNCTION", 0, &tolua_err) ||
        !tolua_isnoobj(tolua_S,5,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo* pomelo = static_cast<CCPomelo*>(tolua_tousertype(tolua_S, 1, 0));
#ifndef TOLUA_RELEASE
		if (nullptr == pomelo)
		{
			tolua_error(tolua_S, "invalid 'CCPomelo' in function 'tolua_CCPomelo_connect'\n", NULL);
			return 0;
		}
#endif
		const char* addr = tolua_tostring(tolua_S, 2, 0);
		int port = tolua_tonumber(tolua_S, 3, 0);
		LUA_FUNCTION func = toluafix_ref_function(tolua_S, 4, 0);
		KODLOG("trying connect %s:%d", addr, port);
		pomelo->asyncConnect(addr, port, [=](const CCPomeloReponse& resp){
			KODLOG("connect status:%d", resp.status);
			auto stack = LuaEngine::getInstance()->getLuaStack();
			stack->pushBoolean(resp.status == 0);
			stack->executeFunctionByHandler(func, 1);
		});
#endif
        
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'tolua_CCPomelo_connect'.",&tolua_err);
    return 0;
#endif
}

static int tolua_CCPomelo_stop(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo* pomelo = static_cast<CCPomelo*>(tolua_tousertype(tolua_S, 1, 0));
#ifndef TOLUA_RELEASE
		if (nullptr == pomelo)
		{
			tolua_error(tolua_S, "invalid 'CCPomelo' in function 'tolua_CCPomelo_stop'\n", NULL);
			return 0;
		}
#endif
		KODLOG("disconnect from server");
		pomelo->stop();
#endif
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'tolua_CCPomelo_stop'.",&tolua_err);
    return 0;
#endif
}

static int tolua_CCPomelo_request(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isstring(tolua_S, 2, 0, &tolua_err) ||
        !tolua_isstring(tolua_S, 3, 0, &tolua_err) ||
        !toluafix_isfunction(tolua_S, 4, "LUA_FUNCTION", 0, &tolua_err) ||
        !tolua_isnoobj(tolua_S,5,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo* pomelo = static_cast<CCPomelo*>(tolua_tousertype(tolua_S, 1, 0));
#ifndef TOLUA_RELEASE
		if (nullptr == pomelo)
		{
			tolua_error(tolua_S, "invalid 'CCPomelo' in function 'tolua_CCPomelo_request'\n", NULL);
			return 0;
		}
#endif
		const char* route = tolua_tostring(tolua_S, 2, 0);
		const char* msg = tolua_tostring(tolua_S, 3, 0);
		json_error_t err;
		json_t* msgj = json_loads(msg, JSON_COMPACT, &err);
		LUA_FUNCTION func = toluafix_ref_function(tolua_S, 4, 0);
		KODLOG("request route:%s", route);
		KODLOG("request message:%s", msg);
		pomelo->request(route, msgj, [=](const CCPomeloReponse& resp){
			char* msg = json_dumps(resp.docs, JSON_COMPACT);
			KODLOG("response status:%d", resp.status);
			KODLOG("response data:%s", msg);
			auto stack = LuaEngine::getInstance()->getLuaStack();
			stack->pushBoolean(resp.status == 0);
			stack->pushString(msg);
			stack->executeFunctionByHandler(func, 2);
		});
#endif
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'tolua_CCPomelo_request'.",&tolua_err);
    return 0;
#endif
}

static int tolua_CCPomelo_notify(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isstring(tolua_S, 2, 0, &tolua_err) ||
        !tolua_isstring(tolua_S, 3, 0, &tolua_err) ||
        !toluafix_isfunction(tolua_S, 4, "LUA_FUNCTION", 0, &tolua_err) ||
        !tolua_isnoobj(tolua_S,5,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo* pomelo = static_cast<CCPomelo*>(tolua_tousertype(tolua_S, 1, 0));
#ifndef TOLUA_RELEASE
		if (nullptr == pomelo)
		{
			tolua_error(tolua_S, "invalid 'CCPomelo' in function 'tolua_CCPomelo_notify'\n", NULL);
			return 0;
		}
#endif
		const char* route = tolua_tostring(tolua_S, 2, 0);
		const char* msg = tolua_tostring(tolua_S, 3, 0);
		json_error_t err;
		json_t* msgj = json_loads(msg, JSON_COMPACT, &err);
		LUA_FUNCTION func = toluafix_ref_function(tolua_S, 4, 0);
		KODLOG("notify route:%s", route);
		KODLOG("notify message:%s", msg);
		pomelo->notify(route, msgj, [=](const CCPomeloReponse& resp){
			KODLOG("notify status:%d", resp.status);
			auto stack = LuaEngine::getInstance()->getLuaStack();

			stack->pushBoolean(resp.status == 0);
			stack->executeFunctionByHandler(func, 1);
		});
#endif
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'tolua_CCPomelo_notify'.",&tolua_err);
    return 0;
#endif
}

static int tolua_CCPomelo_addListener(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isstring(tolua_S, 2, 0, &tolua_err) ||
        !toluafix_isfunction(tolua_S, 3, "LUA_FUNCTION", 0, &tolua_err) ||
        !tolua_isnoobj(tolua_S,4,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo* pomelo = static_cast<CCPomelo*>(tolua_tousertype(tolua_S, 1, 0));
#ifndef TOLUA_RELEASE
		if (nullptr == pomelo)
		{
			tolua_error(tolua_S, "invalid 'CCPomelo' in function 'tolua_CCPomelo_addListener'\n", NULL);
			return 0;
		}
#endif
		const char* event = tolua_tostring(tolua_S, 2, 0);
		LUA_FUNCTION func = toluafix_ref_function(tolua_S, 3, 0);
		KODLOG("add event listener:%s", event);
		pomelo->addListener(event, [=](const CCPomeloReponse& resp){
			char* msg = json_dumps(resp.docs, JSON_COMPACT);
			KODLOG("event status:%d", resp.status);
			KODLOG("event data:%s", msg);
			auto stack = LuaEngine::getInstance()->getLuaStack();
			stack->pushBoolean(resp.status == 0);
			stack->pushString(msg);
			stack->executeFunctionByHandler(func, 2);
		});
#endif
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'tolua_CCPomelo_addListener'.",&tolua_err);
    return 0;
#endif
}

static int tolua_CCPomelo_removeListener(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isstring(tolua_S, 2, 0, &tolua_err) ||
        !tolua_isnoobj(tolua_S,3,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo* pomelo = static_cast<CCPomelo*>(tolua_tousertype(tolua_S, 1, 0));
#ifndef TOLUA_RELEASE
		if (nullptr == pomelo)
		{
			tolua_error(tolua_S, "invalid 'CCPomelo' in function 'tolua_CCPomelo_removeListener'\n", NULL);
			return 0;
		}
#endif
		const char* event = tolua_tostring(tolua_S, 2, 0);
		KODLOG("remove event listener:%s", event);
		pomelo->removeListener(event);
#endif
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'tolua_CCPomelo_removeListener'.",&tolua_err);
    return 0;
#endif
}

static int tolua_CCPomelo_cleanup(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (!tolua_isusertype(tolua_S,1,"CCPomelo",0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		CCPomelo* pomelo = static_cast<CCPomelo*>(tolua_tousertype(tolua_S, 1, 0));
#ifndef TOLUA_RELEASE
		if (nullptr == pomelo)
		{
			tolua_error(tolua_S, "invalid 'CCPomelo' in function 'tolua_CCPomelo_cleanup'\n", NULL);
			return 0;
		}
#endif
		KODLOG("pomelo cleanup");
		pomelo->cleanup();
#endif
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'tolua_CCPomelo_cleanup'.",&tolua_err);
    return 0;
#endif
}

#endif /* CC_USE_POMELO_C_LIB */

TOLUA_API int tolua_cc_pomelo_open(lua_State* tolua_S)
{
#if CC_USE_POMELO_C_LIB
    tolua_open(tolua_S);
    tolua_reg_pomelo_type(tolua_S);
    tolua_module(tolua_S,NULL,0);
    tolua_beginmodule(tolua_S, NULL);
    tolua_cclass(tolua_S,"CCPomelo","CCPomelo","",NULL);
    tolua_beginmodule(tolua_S,"CCPomelo");
    tolua_function(tolua_S, "getInstance", tolua_CCPomelo_getInstance);
    tolua_function(tolua_S, "destroyInstance", tolua_CCPomelo_destroyInstance);
    tolua_function(tolua_S, "connect", tolua_CCPomelo_connect);
    tolua_function(tolua_S, "asyncConnect", tolua_CCPomelo_asyncConnect);
    tolua_function(tolua_S, "stop", tolua_CCPomelo_stop);
    tolua_function(tolua_S, "request", tolua_CCPomelo_request);
    tolua_function(tolua_S, "notify", tolua_CCPomelo_notify);
    tolua_function(tolua_S, "addListener", tolua_CCPomelo_addListener);
    tolua_function(tolua_S, "removeListener", tolua_CCPomelo_removeListener);
    tolua_function(tolua_S, "cleanup", tolua_CCPomelo_cleanup);
    tolua_endmodule(tolua_S);
    tolua_endmodule(tolua_S);
    return 1;
#else
    return 0;
#endif
}




static void tolua_reg_ext_type(lua_State* tolua_S)
{
    tolua_usertype(tolua_S, "ext");
}


static int tolua_ext_now(lua_State* tolua_S){
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isnoobj(tolua_S,1,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        
        long long now;
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID ||  CC_TARGET_PLATFORM == CC_PLATFORM_WINRT
        struct timeval tv;
        gettimeofday(&tv,NULL);
        now = (long long)tv.tv_sec * 1000 + tv.tv_usec / 1000;
#else
        now = GetOSTime();
#endif
        tolua_pushnumber(tolua_S, now);
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'now'.",&tolua_err);
    return 0;
#endif
}


static int tolua_ext_getBatteryLevel(lua_State* tolua_S){
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isnoobj(tolua_S,1,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        
        float batteryLeve = GetBatteryLevel();
        tolua_pushnumber(tolua_S, batteryLeve);
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'getBatteryLeve'.",&tolua_err);
    return 0;
#endif
}

static int tolua_ext_getInternetConnectionStatus(lua_State* tolua_S){
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isnoobj(tolua_S,1,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
		std::string internetConnectionStatus = GetInternetConnectionStatus();
		tolua_pushcppstring(tolua_S, internetConnectionStatus);
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'getInternetConnectionStatus'.",&tolua_err);
    return 0;
#endif
}

static int tolua_ext_copyText(lua_State* tolua_S){
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isstring(tolua_S,1,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        const char* str = ((const char*)  tolua_tostring(tolua_S,1,0));
        CopyText(str);
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'createDir'.",&tolua_err);
    return 0;
#endif
}

static int tolua_ext_createDirectory(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isstring(tolua_S,1,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
		const char* strFolderPath = ((const char*)tolua_tostring(tolua_S, 1, 0));
		bool isCreated = FileOperation::createDirectory(strFolderPath);
		tolua_pushboolean(tolua_S, isCreated);
#elif CC_TARGET_PLATFORM == CC_PLATFORM_WINRT
		bool isCreated =  FileUtils::getInstance()->createDirectory(tolua_tocppstring(tolua_S, 1, 0));
		tolua_pushboolean(tolua_S, isCreated);
#endif
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'createDir'.",&tolua_err);
    return 0;
#endif
}

static int tolua_ext_removeDirectory(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isstring(tolua_S,1,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
		bool isRemoved = FileOperation::removeDirectory(tolua_tocppstring(tolua_S, 1, 0));
		tolua_pushboolean(tolua_S, isRemoved);
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'createDir'.",&tolua_err);
    return 0;
#endif
}

static int tolua_ext_isDirectoryExist(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isstring(tolua_S,1,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        FileUtils* self = FileUtils::getInstance();
        const char* strFolderPath = ((const char*)  tolua_tostring(tolua_S,1,0));
#ifndef TOLUA_RELEASE
        if (!self) tolua_error(tolua_S,"invalid 'self' in function 'isDirectoryExist'", NULL);
#endif
        {
            bool isExist = self->isDirectoryExist(strFolderPath);
            tolua_pushboolean(tolua_S,isExist);
        }
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'isDirectoryExist'.",&tolua_err);
    return 0;
#endif
}

static int tolua_ext_getOpenUdid(lua_State* tolua_S)
{
	tolua_pushcppstring(tolua_S, GetOpenUdid());
    return 1;
}

static int tolua_ext_clearOpenUdid(lua_State* tolua_S)
{
    ClearOpenUdidData();
    return 0;
}

static int tolua_ext_registereForRemoteNotifications(lua_State* tolua_S)
{
    RegistereForRemoteNotifications();
    return 0;
}

static int tolua_ext_disableIdleTimer(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isboolean(tolua_S, 1, 0, &tolua_err))
        goto tolua_lerror;
    else
#endif
    {
        bool disable = tolua_toboolean(tolua_S, 1, 0);
        DisableIdleTimer(disable);
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'disableIdleTimer'.",&tolua_err);
    return 0;
#endif
}

static int tolua_ext_restart(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isnoobj(tolua_S,1,&tolua_err) )
        goto tolua_lerror;
    else
#endif
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_WINRT
		AppDelegateExtern delegateExtern;

		auto scheduler = Director::getInstance()->getScheduler();
		//下面两个方法均有被修改 dannyhe
		LuaNodeManager::getInstance()->removeAllNodeAndEvents();
		scheduler->unscheduleScriptEntry(-1);
		scheduler->schedule(schedule_selector(AppDelegateExtern::restartGame), &delegateExtern, 0, false, 0, false);
#endif
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'restart'.",&tolua_err);
    return 0;
#endif
}

unsigned long getFileCrc32(const char* filePath)
{
    FILE *file = fopen(filePath, "rb");
    unsigned long crc32;
    Crc32_ComputeFile(file, &crc32);
    fclose(file);
    return crc32;
}

static int tolua_ext_crc32(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isstring(tolua_S,1,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        const char* filePath = tolua_tostring(tolua_S, 1, 0);
        FILE *file = fopen(filePath, "rb");
#ifndef TOLUA_RELEASE
        if(file == NULL){
            tolua_err.index = 2;
            tolua_err.array = 0;
            tolua_err.type = "string";
            goto tolua_lerror;
        }
        else
#endif
        {
            char crc32S[32];
            unsigned long crc32;
            Crc32_ComputeFile(file, &crc32);
            sprintf(crc32S, "%08lx", crc32);
            tolua_pushstring(tolua_S, crc32S);
            fclose(file);
        }
    }
    return 1;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'crc32'.",&tolua_err);
    return 0;
#endif
}

static int tolua_ext_close_keyboard(lua_State* tolua_S)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS
    CloseKeyboard();
#endif
    return 0;
}

static int tolua_ext_get_os_version(lua_State* tolua_S)
{
	std::string ret = GetOSVersion();
	tolua_pushcppstring(tolua_S, ret);
    return 1;
}

static int tolua_ext_get_device_model(lua_State* tolua_S)
{
	std::string model = GetDeviceModel();
	tolua_pushcppstring(tolua_S, model);
    return 1;
}

static int tolua_ext_log_file(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
    tolua_Error tolua_err;
    if (
        !tolua_isstring(tolua_S,1,0,&tolua_err) ||
        !tolua_isnoobj(tolua_S,2,&tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        const char* log = tolua_tostring(tolua_S, 1, 0);
        WriteLog_(log);
    }
    return 0;
#ifndef TOLUA_RELEASE
tolua_lerror:
    tolua_error(tolua_S,"#ferror in function 'log_file'.",&tolua_err);
    return 0;
#endif
}

static int tolua_ext_get_app_version(lua_State* tolua_S)
{
	std::string  app_ver = GetAppVersion();
	tolua_pushcppstring(tolua_S, app_ver);
    return 1;

}

static int tolua_ext_get_app_build_version(lua_State* tolua_S)
{
	std::string build_ver = GetAppBundleVersion();
	tolua_pushcppstring(tolua_S, build_ver);
    return 1;
}

static int tolua_ext_get_device_token(lua_State* tolua_S)
{
	std::string  token = GetDeviceToken();
	tolua_pushcppstring(tolua_S, token);
    return 1;
}

static int tolua_ext_get_language_code(lua_State* tolua_S)
{
	std::string token = GetDeviceLanguage();
	tolua_pushcppstring(tolua_S, token);
    return 1;
}

static int tolua_ext_is_app_hoc(lua_State* tolua_S)
{
    bool ret = IsAppAdHocMode();
    lua_pushboolean(tolua_S, ret);
    return 1;
}

static int tolua_ext_isLowMemoryDevice(lua_State* tolua_S)
{
	bool ret = isLowMemoryDevice();
	tolua_pushboolean(tolua_S, ret);
	return 1;
}

static int tolua_ext_getAppMemoryUsage(lua_State* tolua_S)
{
	auto ret = getAppMemoryUsage();
	tolua_pushnumber(tolua_S, ret);
	return 1;
}

#if  CC_TARGET_PLATFORM == CC_PLATFORM_WINRT
static int tolua_ext_open_url(lua_State* tolua_S)
{
	std::string url = tolua_tocppstring(tolua_S, 1, 0);
	OpenUrl(url);
	return 0;
}

static int tolua_ext_show_alert(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
	tolua_Error tolua_err;
	if (!toluafix_isfunction(tolua_S, 4, "LUA_FUNCTION", 0, &tolua_err) ||
		!tolua_isstring(tolua_S, 1, 0, &tolua_err) ||
		!tolua_isstring(tolua_S, 2, 0, &tolua_err) ||
		!tolua_isstring(tolua_S, 3, 0, &tolua_err))
		goto tolua_lerror;
	else
#endif
	{
		cocos2d::LUA_FUNCTION handlerId = toluafix_ref_function(tolua_S, 4, 0);
		std::string title = tolua_tocppstring(tolua_S, 1, 0);
		std::string content = tolua_tocppstring(tolua_S, 2, 0);
		std::string okString = tolua_tocppstring(tolua_S, 3, 0);
		ShowAlert(title, content, okString, [=](){
			auto stack = cocos2d::LuaEngine::getInstance()->getLuaStack();
			stack->executeFunctionByHandler(handlerId,0);
		});
		return 0;
	}
#ifndef TOLUA_RELEASE
tolua_lerror :
	tolua_error(tolua_S, "#ferror in function 'tolua_ext_show_alert'.", &tolua_err);
	return 0;
#endif
}
#endif

static void ResgisterGlobalExtFunctions(lua_State* tolua_S)
{
    tolua_function(tolua_S, "now", tolua_ext_now);
    tolua_function(tolua_S, "getBatteryLevel", tolua_ext_getBatteryLevel);
    tolua_function(tolua_S, "getInternetConnectionStatus", tolua_ext_getInternetConnectionStatus);
    tolua_function(tolua_S, "createDirectory", tolua_ext_createDirectory);
    tolua_function(tolua_S, "removeDirectory", tolua_ext_removeDirectory);
    tolua_function(tolua_S, "isDirectoryExist", tolua_ext_isDirectoryExist);
    tolua_function(tolua_S, "crc32", tolua_ext_crc32);
    tolua_function(tolua_S, "restart", tolua_ext_restart);
    tolua_function(tolua_S, "copyText", tolua_ext_copyText);
    tolua_function(tolua_S, "disableIdleTimer", tolua_ext_disableIdleTimer);
    tolua_function(tolua_S, "closeKeyboard", tolua_ext_close_keyboard);
    tolua_function(tolua_S, "getOSVersion", tolua_ext_get_os_version);
    tolua_function(tolua_S, "getDeviceModel", tolua_ext_get_device_model);
    tolua_function(tolua_S, "getAppVersion", tolua_ext_get_app_version);
    tolua_function(tolua_S, "getAppBuildVersion", tolua_ext_get_app_build_version);
    tolua_function(tolua_S, "__logFile", tolua_ext_log_file);
    tolua_function(tolua_S, "getDeviceToken", tolua_ext_get_device_token);
    tolua_function(tolua_S, "getOpenUDID",tolua_ext_getOpenUdid);
    tolua_function(tolua_S, "registereForRemoteNotifications",tolua_ext_registereForRemoteNotifications);
    tolua_function(tolua_S, "clearOpenUdid",tolua_ext_clearOpenUdid);
    tolua_function(tolua_S, "getDeviceLanguage",tolua_ext_get_language_code);
    tolua_function(tolua_S, "isAppAdHoc",tolua_ext_is_app_hoc);
	tolua_function(tolua_S, "isLowMemoryDevice", tolua_ext_isLowMemoryDevice);
	tolua_function(tolua_S, "getAppMemoryUsage", tolua_ext_getAppMemoryUsage);
#if  CC_TARGET_PLATFORM == CC_PLATFORM_WINRT
	tolua_function(tolua_S, "openURL", tolua_ext_open_url);
	tolua_function(tolua_S, "showAlert", tolua_ext_show_alert);
#endif
}

static void RegisterExtModules(lua_State* tolua_S)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS
    tolua_ext_module_gamecenter(tolua_S);
	tolua_ext_module_market(tolua_S);
#elif CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
     tolua_ext_module_store(tolua_S);
	 tolua_ext_module_market(tolua_S);
#if CC_USE_SDK_PAYPAL
     tolua_ext_module_paypal(tolua_S);
#endif
#if CC_USE_GOOGLE_LOGIN
     tolua_ext_module_google(tolua_S);
#endif
#elif CC_TARGET_PLATFORM == CC_PLATFORM_WINRT
	tolua_ext_module_audio(tolua_S);
	tolua_ext_module_adeasygo(tolua_S);
#endif
	tolua_ext_module_sysmail(tolua_S); //email
	tolua_ext_module_localpush(tolua_S); //local push
#if CC_USE_FACEBOOK
    tolua_ext_module_facebook(tolua_S);
#endif
}


TOLUA_API int tolua_cc_lua_extension(lua_State* tolua_S)
{
    tolua_open(tolua_S);
    tolua_reg_ext_type(tolua_S);
    tolua_module(tolua_S,NULL,0);
    tolua_beginmodule(tolua_S, NULL);
    tolua_cclass(tolua_S,"ext","ext","",NULL);
    tolua_beginmodule(tolua_S,"ext");
    ResgisterGlobalExtFunctions(tolua_S);
    RegisterExtModules(tolua_S);
    tolua_endmodule(tolua_S);
    tolua_endmodule(tolua_S);
    return 1;
}