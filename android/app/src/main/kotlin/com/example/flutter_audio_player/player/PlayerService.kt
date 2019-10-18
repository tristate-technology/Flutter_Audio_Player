package com.example.flutter_audio_player.player

import android.app.NotificationManager
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Binder
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory
import com.google.android.exoplayer2.source.ExtractorMediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.ui.PlayerNotificationManager
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import com.example.flutter_audio_player.MainActivity

class PlayerService : Service() {

    private val TAG = PlayerService::class.java.simpleName
    var player: SimpleExoPlayer? = null
    private var dataSourceFactory: DefaultDataSourceFactory? = null
    private var playerNotificationManager: PlayerNotificationManager? = null

    private var mWiFiLock: WifiManager.WifiLock? = null
    private var mWakeLock: PowerManager.WakeLock? = null
    var isServiceStart: Boolean = false

    var audioPath: String? = null
    var audioTitle: String? = null
    var audioDescription: String? = null

    var playerEvent: Player.EventListener? = null

    override fun onCreate() {
        super.onCreate()

        player = ExoPlayerFactory.newSimpleInstance(applicationContext, DefaultTrackSelector())
        dataSourceFactory = DefaultDataSourceFactory(applicationContext,
                Util.getUserAgent(applicationContext, "mediaPlayer"), DefaultBandwidthMeter())
    }

    override fun onBind(intent: Intent?): IBinder? {
        if (intent != null) {
            if (intent.hasExtra("audioPath")) {
                audioPath = intent.getStringExtra("audioPath")
                audioTitle = intent.getStringExtra("audioTitle")
                audioDescription = intent.getStringExtra("audioDescription")

            }
        }

        return MyBinder()
    }

    inner class MyBinder : Binder() {
        val service: PlayerService
            get() = this@PlayerService
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    fun setUpMediaPlayer() {
        val mediaSource = ExtractorMediaSource.Factory(dataSourceFactory)
                .setExtractorsFactory(DefaultExtractorsFactory())
                .createMediaSource(Uri.parse(audioPath))

        player?.addListener(playerEvent)
        player?.prepare(mediaSource)
//        player?.setPlayWhenReady(true)

        playerNotificationManager = PlayerNotificationManager.createWithNotificationChannel(applicationContext,
                "mediaPlayer", R.string.exo_download_notification_channel_name, 1,
                object : PlayerNotificationManager.MediaDescriptionAdapter {

                    override fun createCurrentContentIntent(player: Player?): PendingIntent? {
                        val intent = Intent(applicationContext, MainActivity::class.java)
                        return PendingIntent.getActivity(applicationContext, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
                    }

                    override fun getCurrentContentText(player: Player?): String? {
                        return audioDescription ?: ""
                    }

                    override fun getCurrentContentTitle(player: Player?): String {
                        return audioTitle ?: ""
                    }

                    override fun getCurrentLargeIcon(player: Player?, callback: PlayerNotificationManager.BitmapCallback?): Bitmap? {
                        val drawable = ContextCompat.getDrawable(applicationContext,
                                R.drawable.exo_controls_fastforward)

                        val bitmap = Bitmap.createBitmap(drawable!!.intrinsicWidth,
                                drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
                        val canvas = Canvas(bitmap)
                        drawable.setBounds(0, 0, canvas.width, canvas.height)
                        drawable.draw(canvas)

                        return bitmap
                    }

                })

        playerNotificationManager?.setNotificationListener(object : PlayerNotificationManager.NotificationListener {
            override fun onNotificationCancelled(notificationId: Int) {
                isServiceStart = false
                unlockWiFi()
                unlockCPU()
                stopSelf()
                /*  val notificationManager=applicationContext?.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                  notificationManager.cancel(notificationId)*/
            }

            override fun onNotificationStarted(notificationId: Int, notification: Notification?) {
                isServiceStart = true
                startForeground(notificationId, notification)
            }

        })

        playerNotificationManager?.setRewindIncrementMs(15000)
        playerNotificationManager?.setFastForwardIncrementMs(15000)
        playerNotificationManager?.setUseNavigationActions(false)
        playerNotificationManager?.setPlayer(player)

        lockWiFi()
        lockCPU()
    }


    private fun lockCPU() {
        val mgr = getSystemService(Context.POWER_SERVICE) as PowerManager
        mWakeLock = mgr.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, this.javaClass.simpleName)
        mWakeLock?.acquire()
    }

    private fun unlockCPU() {
        if (mWakeLock != null && mWakeLock!!.isHeld) {
            mWakeLock?.release()
            mWakeLock = null
            //            Log.d(TAG, "Player unlockCPU()");
        }
    }

    private fun lockWiFi() {
        val connManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val lWifi = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI)
        if (lWifi != null && lWifi.isConnected) {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.HONEYCOMB_MR1) {
                mWiFiLock = (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).createWifiLock(
                        WifiManager.WIFI_MODE_FULL_HIGH_PERF, PlayerService::class.java.simpleName)
            } else {
                mWiFiLock = (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).createWifiLock(
                        WifiManager.WIFI_MODE_FULL, PlayerService::class.java.simpleName)
            }
            mWiFiLock?.acquire()
        }
    }

    private fun unlockWiFi() {
        if (mWiFiLock != null && mWiFiLock?.isHeld!!) {
            mWiFiLock?.release()
            mWiFiLock = null
        }
    }

    override fun onDestroy() {
        playerNotificationManager?.setPlayer(null)
        player?.stop()
        player?.release()
        player = null
        super.onDestroy()
        unlockCPU()
        unlockWiFi()
    }

}