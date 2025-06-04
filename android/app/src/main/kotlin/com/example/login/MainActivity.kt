package com.example.login

import io.flutter.embedding.android.FlutterActivity
import android.content.pm.PackageManager
import android.util.Base64
import android.util.Log
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        // 🔥 강제로 키 해시 출력
        Log.e("DEBUG", "MainActivity onCreate 시작!")
        println("🚨 MainActivity onCreate 시작!")

        printActualKeyHash()
    }

    @Suppress("DEPRECATION")
    private fun printActualKeyHash() {
        Log.e("DEBUG", "printActualKeyHash 함수 시작!")
        println("🚨 printActualKeyHash 함수 시작!")

        try {
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)

            Log.e("DEBUG", "패키지 정보 획득 성공!")
            println("🚨 패키지 정보 획득 성공!")

            packageInfo.signatures?.let { signatures ->
                Log.e("DEBUG", "서명 개수: ${signatures.size}")
                println("🚨 서명 개수: ${signatures.size}")

                for ((index, signature) in signatures.withIndex()) {
                    val md = MessageDigest.getInstance("SHA")
                    md.update(signature.toByteArray())
                    val keyHash = Base64.encodeToString(md.digest(), Base64.DEFAULT)

                    // 🚨 여러 방법으로 출력
                    Log.e("KAKAO_KEY_HASH", "키 해시 $index: $keyHash")
                    println("🔑🔑🔑 키 해시 $index: $keyHash")
                    System.out.println("🔑🔑🔑 키 해시 $index: $keyHash")

                    // 기본값과 비교
                    val defaultHash = "Xo8WBi6jzSxKDVKUpiJNTp5u+9s="
                    if (keyHash.trim() == defaultHash) {
                        Log.e("KAKAO_KEY_HASH", "✅ 기본 키 해시와 동일!")
                        println("✅ 기본 키 해시와 동일!")
                    } else {
                        Log.e("KAKAO_KEY_HASH", "❌ 기본 키 해시와 다름! 실제: $keyHash")
                        println("❌ 기본 키 해시와 다름! 실제: $keyHash")
                    }
                }
            } ?: run {
                Log.e("DEBUG", "❌ 서명 정보가 null입니다")
                println("❌ 서명 정보가 null입니다")
            }
        } catch (e: Exception) {
            Log.e("KEY_HASH_ERROR", "키 해시 생성 실패: ${e.message}", e)
            println("❌ 키 해시 생성 실패: ${e.message}")
        }
    }
}