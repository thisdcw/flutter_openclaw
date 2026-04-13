package com.cw.claw.flutter_openclaw

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature

class KeystoreSigner(private val alias: String) {
    private val keystore: KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    fun ensureKeypair(): ByteArray {
        if (!keystore.containsAlias(alias)) {
            val generator = KeyPairGenerator.getInstance(
                ED25519_ALGORITHM,
                ANDROID_KEYSTORE,
            )
            val spec = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
            ).setDigests(KeyProperties.DIGEST_NONE).build()
            generator.initialize(spec)
            generator.generateKeyPair()
        }
        val entry = keystore.getEntry(alias, null) as KeyStore.PrivateKeyEntry
        val encoded = entry.certificate.publicKey.encoded
        return extractRawPublicKey(encoded)
    }

    fun sign(payload: ByteArray): ByteArray {
        val entry = keystore.getEntry(alias, null) as KeyStore.PrivateKeyEntry
        val signature = Signature.getInstance(ED25519_ALGORITHM)
        signature.initSign(entry.privateKey)
        signature.update(payload)
        return signature.sign()
    }

    fun clear() {
        if (keystore.containsAlias(alias)) {
            keystore.deleteEntry(alias)
        }
    }

    private fun extractRawPublicKey(encoded: ByteArray): ByteArray {
        val marker = byteArrayOf(0x03, 0x21, 0x00)
        var index = -1
        for (i in 0 until encoded.size - marker.size) {
            if (encoded[i] == marker[0] && encoded[i + 1] == marker[1] && encoded[i + 2] == marker[2]) {
                index = i + 3
                break
            }
        }
        if (index < 0 || index + 32 > encoded.size) {
            throw IllegalStateException("Unsupported Ed25519 public key format")
        }
        return encoded.copyOfRange(index, index + 32)
    }

    companion object {
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val ED25519_ALGORITHM = "Ed25519"

        fun base64(bytes: ByteArray): String = Base64.encodeToString(bytes, Base64.NO_WRAP)

        fun base64Url(bytes: ByteArray): String = Base64.encodeToString(
            bytes,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
    }
}
