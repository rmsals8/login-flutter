package com.example.login

import io.flutter.embedding.android.FlutterFragmentActivity
import android.content.pm.PackageManager
import android.util.Base64
import android.util.Log
import java.security.MessageDigest

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 🔥 키 해시 출력을 주석 처리했다
        // 나중에 필요하면 주석을 풀어서 사용할 수 있다
        
        // Log.e("MAIN_ACTIVITY", "=== MainActivity onCreate 시작! ===")
        // System.out.println("🚨 MainActivity onCreate 시작!")
        
        // getKeyHash()
    }
    
    // 🔥 키 해시 메소드도 주석 처리했다
    /*
    @Suppress("DEPRECATION")
    private fun getKeyHash() {
        try {
            Log.e("KEY_HASH", "키 해시 추출 시작")
            println("🔑 키 해시 추출 시작")
            
            val packageInfo = packageManager.getPackageInfo(
                packageName, 
                PackageManager.GET_SIGNATURES
            )
            
            // 🔥 null 체크 추가
            packageInfo.signatures?.let { signatures ->
                Log.e("KEY_HASH", "서명 개수: ${signatures.size}")
                
                for (signature in signatures) {
                    val md = MessageDigest.getInstance("SHA")
                    md.update(signature.toByteArray())
                    val keyHash = Base64.encodeToString(md.digest(), Base64.DEFAULT)
                    
                    // 🚨 모든 방법으로 출력
                    Log.e("KEY_HASH_RESULT", "키 해시: $keyHash")
                    Log.w("KEY_HASH_RESULT", "키 해시: $keyHash")
                    Log.i("KEY_HASH_RESULT", "키 해시: $keyHash")
                    Log.d("KEY_HASH_RESULT", "키 해시: $keyHash")
                    
                    println("🔑🔑🔑 키 해시: $keyHash")
                    System.out.println("🔑🔑🔑 키 해시: $keyHash")
                    System.err.println("🔑🔑🔑 키 해시: $keyHash")
                    
                    // 토스트도 표시
                    runOnUiThread {
                        android.widget.Toast.makeText(
                            this,
                            "키 해시: $keyHash",
                            android.widget.Toast.LENGTH_LONG
                        ).show()
                    }
                }
            } ?: run {
                Log.e("KEY_HASH_ERROR", "signatures가 null입니다")
                println("❌ signatures가 null입니다")
            }
            
        } catch (e: Exception) {
            Log.e("KEY_HASH_ERROR", "에러: ${e.message}")
            println("❌ 키 해시 에러: ${e.message}")
            e.printStackTrace()
        }
    }
    */
}