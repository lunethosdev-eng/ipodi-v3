package com.sekai.sekaipod

import android.app.role.RoleManager
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.sekai.sekaipod/system"
    private val homeRoleRequestCode = 4201

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "openHomeSettings" -> {
                    openHomeSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openHomeSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(RoleManager::class.java)
                if (roleManager != null &&
                    roleManager.isRoleAvailable(RoleManager.ROLE_HOME) &&
                    !roleManager.isRoleHeld(RoleManager.ROLE_HOME)
                ) {
                    startActivityForResult(
                        roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME),
                        homeRoleRequestCode
                    )
                    return
                }
            }
            startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
            } catch (_: Exception) {
                // Nothing else to open on this device.
            }
        }
    }
}
