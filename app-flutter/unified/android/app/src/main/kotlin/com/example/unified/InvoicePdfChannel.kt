package com.example.unified

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import kotlin.math.min

/** Renders one supplied invoice page locally. No URL or credentials leave the app. */
class InvoicePdfChannel(context: Context, messenger: BinaryMessenger) {
    private val appContext = context.applicationContext
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val channel = MethodChannel(messenger, "br.com.ajust.app_provedor/invoice_pdf")

    init {
        channel.setMethodCallHandler { call, result ->
                if (call.method != "render") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val pageIndex = call.argument<Int>("page") ?: 0
                if (bytes == null || bytes.isEmpty() || bytes.size > 12 * 1024 * 1024 || pageIndex < 0) {
                    result.error("invalid_pdf", "Documento inválido.", null)
                    return@setMethodCallHandler
                }
                executor.execute {
                    try {
                        val rendered = renderPage(bytes, pageIndex)
                        mainHandler.post { result.success(rendered) }
                    } catch (error: Exception) {
                        mainHandler.post { result.error("render_failed", "Não foi possível visualizar o documento.", null) }
                    }
                }
            }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdownNow()
    }

    private fun renderPage(bytes: ByteArray, pageIndex: Int): Map<String, Any> {
        val file = java.io.File.createTempFile("invoice-preview-", ".pdf", appContext.cacheDir)
        try {
            file.writeBytes(bytes)
            ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                PdfRenderer(descriptor).use { renderer ->
                    require(pageIndex < renderer.pageCount)
                    renderer.openPage(pageIndex).use { page ->
                        val scale = min(1200.0 / page.width, 3200.0 / page.height)
                        val width = (page.width * scale).toInt().coerceAtLeast(1)
                        val height = (page.height * scale).toInt().coerceAtLeast(1)
                        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                        try {
                            bitmap.eraseColor(Color.WHITE)
                            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                            val output = ByteArrayOutputStream()
                            check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, output))
                            return mapOf("image" to output.toByteArray(), "pages" to renderer.pageCount)
                        } finally {
                            bitmap.recycle()
                        }
                    }
                }
            }
        } finally {
            file.delete()
        }
    }
}
