package com.batcatstudio.dragonfall.utils;

import org.cocos2dx.lib.Cocos2dxHelper;
import org.cocos2dx.lua.AppActivity;

import com.batcatstudio.dragonfall.data.DataHelper;
import com.xapcn.dragonfall.BuildConfig;

import java.io.File;

@SuppressWarnings("deprecation")
public class LaunchHelper {
	
	private static String TAG = "LaunchHelper";
	private static native void nativeInitLuaEngine(String path);
	private static native void nativeInitLuaEngineNoBundlePath();
	private static boolean UNZIP_RSOURCES = false; //是否解压游戏的zip文件,如果为false则表示直接执行assets
	//define the location of resources to extra.
	private enum UnzipLocation { None, ExternalStorage, InternalSpace }
	//check the device if player install the game at fist time
	public static void checkGameFirstInstall(){
		if(UNZIP_RSOURCES) {
			AppActivity.getGameActivity().setKeepScreenOn(true);
			if(DataHelper.isAppVersionExpired() || !DataHelper.hasInstallUnzip()) { //需要解压
				DebugUtil.LogDebug(TAG, "checkGameFirstInstall:need unzip dragonfall.zip");
				UnzipLocation location = getUnzipLocation();
				if(location == UnzipLocation.None) {
					AppActivity.getGameActivity().runOnUiThread(new Runnable() {
						@Override
						public void run() {
							AppActivity.getGameActivity().showDialog(AppActivity.AppActivityDialog.DIALOG_UNZIP_SPACE_NOT_ENOUGH.ordinal());
						}
					});

				}else {
					DataHelper.unzipGameResource(location == UnzipLocation.ExternalStorage);
				}
			}else {
				runNativeLuaEngine();
			}
		}else {
			AppActivity.getGameActivity().setKeepScreenOn(true);
			String writePath = getWritePath();
			if (DataHelper.isAppVersionExpired() && DataHelper.hasInstallUnzip()) {
				//clean
				DebugUtil.LogDebug(TAG, "Clean User Data: "+writePath);
				try {
					DataHelper.deleteFileRecursively(writePath);
				}catch (Exception e)
				{
					DebugUtil.LogException(TAG,e);
				}
			}
			DataHelper.saveIntValue(DataHelper.KEY_APP_VERSION_CODE, BuildConfig.VERSION_CODE);
			DataHelper.saveBooleanValue(DataHelper.KEY_HAS_INSTALL_GAME, true);
			Cocos2dxHelper.setCocos2dxWritablePath(writePath);
			runNativeLuaEngine();
		}
	}
	
	private static UnzipLocation getUnzipLocation() {
		UnzipLocation location = UnzipLocation.None; 
		if(!DataHelper.isExternalStorageMounted() || !DataHelper.isExternalStorageSpaceEnough()) {
			if(DataHelper.isInternalSpaceEnough()) {
				location = UnzipLocation.InternalSpace;
			}
		}else {
			location = UnzipLocation.ExternalStorage;
		}
		return location;
	}

	//执行游戏lua相关的cpp初始化逻辑
	public static void runNativeLuaEngine() {
		if (UNZIP_RSOURCES) {
			runNativeLuaEngineWithBundlePath();
		}else{
			runNativeLuaEngineNoBundlePath();
		}
	}

	public static void runNativeLuaEngineNoBundlePath() {
		AppActivity.getGameActivity().setGameLaunched(true);
		Cocos2dxHelper.runOnGLThread(new Runnable() {
			@Override
			public void run() {
				nativeInitLuaEngineNoBundlePath();
			}
		});
	}

	public static void runNativeLuaEngineWithBundlePath() {
		DataHelper.preInitActivityData();
		DebugUtil.LogDebug(TAG, "Game Bundle Path:"+Cocos2dxHelper.getCocos2dxBundlePath());
		Cocos2dxHelper.runOnGLThread(new Runnable() {
			@Override
			public void run() {
				nativeInitLuaEngine(Cocos2dxHelper.getCocos2dxBundlePath());
			}
		});
		AppActivity.getGameActivity().setGameLaunched(true);
		AppActivity.getGameActivity().setKeepScreenOn(false);
	}

	public static boolean isGameLaunched() {
		return AppActivity.getGameActivity().isGameLaunched();
	}

	public static String getWritePath() {
		StringBuilder sb = new StringBuilder();
		File file = AppActivity.getGameActivity().getExternalFilesDir(null);
		if (file != null && DataHelper.isExternalStorageMounted()) {
			sb.append(file.getAbsolutePath()).append(File.separator);
		} else {
			sb.append(Cocos2dxHelper.getCocos2dxWritablePath());
		}
		return sb.toString();
	}
}
