package com.aryan.digitalwallet.payhive

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {

  private val CHANNEL = "com.aryan.payhive/saveToDownloads"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL
    ).setMethodCallHandler { call, result ->
      if (call.method == "saveToDownloads") {
        try {
          val args = call.arguments as Map<*, *>
          val bytes = args["bytes"] as ByteArray
          val filename = args["filename"] as String

          val savedPath = saveToDownloads(filename, bytes)
          result.success(savedPath)
        } catch (e: Exception) {
          result.error("SAVE_FAILED", e.message, null)
        }
      } else {
        result.notImplemented()
      }
    }
  }

  private fun saveToDownloads(filename: String, bytes: ByteArray): String {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      val resolver = applicationContext.contentResolver

      val contentValues = ContentValues().apply {
        put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
        put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
        put(
          MediaStore.MediaColumns.RELATIVE_PATH,
          Environment.DIRECTORY_DOWNLOADS
        )
      }

      val uri = resolver.insert(
        MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
        contentValues
      ) ?: throw Exception("Failed to create MediaStore record")

      resolver.openOutputStream(uri)?.use { output ->
        output.write(bytes)
      } ?: throw Exception("Failed to open output stream")

      uri.toString()
    } else {
      val downloads =
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)

      val dir = File(downloads, "PayHive")
      if (!dir.exists()) dir.mkdirs()

      val file = File(dir, filename)
      FileOutputStream(file).use {
        it.write(bytes)
        it.flush()
      }

      file.absolutePath
    }
  }
}
