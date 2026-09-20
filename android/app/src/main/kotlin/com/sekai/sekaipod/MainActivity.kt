package com.sekai.sekaipod

import android.app.role.RoleManager
import android.content.Intent
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.sekai.sekaipod/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openHomeSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val roleManager = getSystemService(RoleManager::class.java)
                                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_HOME)) {
                                    if (!roleManager.isRoleHeld(RoleManager.ROLE_HOME)) {
                                        startActivityForResult(
                                            roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME),
                                            7101
                                        )
                                    } else {
                                        startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
                                    }
                                } else {
                                    startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
                                }
                            } else {
                                startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                startActivity(Intent(Settings.ACTION_SETTINGS))
                                result.success(true)
                            } catch (fallback: Exception) {
                                result.error("HOME_SETTINGS", fallback.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
