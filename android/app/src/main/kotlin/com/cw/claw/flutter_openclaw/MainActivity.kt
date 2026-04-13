package com.cw.claw.flutter_openclaw

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private var pendingSaveRequest: PendingSaveRequest? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val keystoreSigner = KeystoreSigner(KEY_ALIAS)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveImage" -> saveImage(call, result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            KEYSTORE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            runCatching {
                when (call.method) {
                    "ensureKeypair" -> {
                        val publicKey = keystoreSigner.ensureKeypair()
                        result.success(KeystoreSigner.base64(publicKey))
                    }
                    "signPayload" -> {
                        val payload = call.argument<String>("payload")
                        if (payload.isNullOrEmpty()) {
                            result.error(
                                "missing-payload",
                                "Payload is required for signing.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        val signature = keystoreSigner.sign(payload.toByteArray(Charsets.UTF_8))
                        result.success(KeystoreSigner.base64Url(signature))
                    }
                    "clearKeypair" -> {
                        keystoreSigner.clear()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }.onFailure { error ->
                result.error(
                    "keystore-error",
                    error.message ?: "Keystore operation failed.",
                    null,
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_WRITE_STORAGE) {
            return
        }
        val request = pendingSaveRequest ?: return
        pendingSaveRequest = null
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            persistImage(request)
            return
        }
        request.result.error(
            "permission-denied",
            "Storage permission was denied.",
            null,
        )
    }

    private fun saveImage(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val fileName = call.argument<String>("fileName") ?: "openclaw-image.jpg"
        val mimeType = call.argument<String>("mimeType") ?: "image/jpeg"
        if (bytes == null) {
            result.error("invalid-arguments", "Image bytes are required.", null)
            return
        }

        val request = PendingSaveRequest(
            bytes = bytes,
            fileName = fileName,
            mimeType = mimeType,
            result = result,
        )

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            pendingSaveRequest = request
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                REQUEST_WRITE_STORAGE,
            )
            return
        }

        persistImage(request)
    }

    private fun persistImage(request: PendingSaveRequest) {
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveWithMediaStore(
                    bytes = request.bytes,
                    fileName = request.fileName,
                    mimeType = request.mimeType,
                )
            } else {
                saveWithLegacyStorage(
                    bytes = request.bytes,
                    fileName = request.fileName,
                    mimeType = request.mimeType,
                )
            }
        }.onSuccess { uri ->
            request.result.success(uri.toString())
        }.onFailure { error ->
            request.result.error(
                "save-failed",
                error.message ?: "Saving image failed.",
                null,
            )
        }
    }

    private fun saveWithMediaStore(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
    ): Uri {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            put(
                MediaStore.Images.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_PICTURES}/OpenClaw",
            )
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: error("Unable to create MediaStore entry.")
        resolver.openOutputStream(uri)?.use { output ->
            output.write(bytes)
            output.flush()
        } ?: error("Unable to open MediaStore output stream.")
        values.clear()
        values.put(MediaStore.Images.Media.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return uri
    }

    private fun saveWithLegacyStorage(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
    ): Uri {
        val picturesDirectory =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
        val targetDirectory = File(picturesDirectory, "OpenClaw")
        if (!targetDirectory.exists()) {
            targetDirectory.mkdirs()
        }
        val targetFile = File(targetDirectory, fileName)
        FileOutputStream(targetFile).use { output ->
            output.write(bytes)
            output.flush()
        }
        MediaScannerConnection.scanFile(
            this,
            arrayOf(targetFile.absolutePath),
            arrayOf(mimeType),
            null,
        )
        return Uri.fromFile(targetFile)
    }

    private data class PendingSaveRequest(
        val bytes: ByteArray,
        val fileName: String,
        val mimeType: String,
        val result: MethodChannel.Result,
    )

    companion object {
        private const val CHANNEL_NAME = "openclaw/media"
        private const val KEYSTORE_CHANNEL = "openclaw/keystore"
        private const val KEY_ALIAS = "openclaw.device.signing"
        private const val REQUEST_WRITE_STORAGE = 2407
    }
}
