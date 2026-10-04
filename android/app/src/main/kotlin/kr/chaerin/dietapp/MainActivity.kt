package kr.chaerin.dietapp

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// 오늘 식단을 기록했는지에 따라 홈 화면 앱 아이콘을 바꾼다 (빈 그릇 ↔ 채운 그릇).
/// 두 개의 activity-alias(AndroidManifest.xml) 중 하나만 켜두는 방식으로 구현한다.
class MainActivity : FlutterActivity() {
    private val channelName = "kr.chaerin.dietapp/app_icon"
    private val emptyAlias = "kr.chaerin.dietapp.MainActivityEmpty"
    private val filledAlias = "kr.chaerin.dietapp.MainActivityFilled"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setFilled" -> {
                        setFilled(call.argument<Boolean>("filled") == true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setFilled(filled: Boolean) {
        val pm = packageManager
        pm.setComponentEnabledSetting(
            ComponentName(packageName, emptyAlias),
            if (filled) PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            else PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        pm.setComponentEnabledSetting(
            ComponentName(packageName, filledAlias),
            if (filled) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP,
        )
    }
}
