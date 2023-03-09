package com.example.flutter_audio_player

import android.os.Bundle
import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.os.IBinder
import android.content.Context.BIND_AUTO_CREATE
import android.content.Intent
import androidx.core.content.ContextCompat.getSystemService
import android.icu.lang.UCharacter.GraphemeClusterBreak.T
import com.google.android.exoplayer2.Player
import com.example.flutter_audio_player.player.PlayerService
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import android.icu.lang.UCharacter.GraphemeClusterBreak.T
import android.media.AudioManager
import android.media.session.PlaybackState
import android.os.Handler
import android.util.Log
import android.view.KeyEvent
import com.google.android.exoplayer2.ExoPlaybackException
import com.google.android.exoplayer2.PlaybackParameters
import com.google.android.exoplayer2.Timeline
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import io.flutter.embedding.engine.FlutterEngine
import java.lang.Exception

class MainActivity: FlutterActivity() {

  private val TAG = MainActivity::class.java.simpleName

  private var playerService: PlayerService? = null

  private val CHANNEL = "flutter.native.audio.bridge"

  var audioPath: String? = null
  var audioTitle: String? = null
  var audioDescription: String? = null
  var isBuffering: Boolean? = null

  private var seekBarProgressHandler: Handler? = null

  private var isPlaying: Boolean = false

  private var currentProgress: Long = 0
  private var maxProgress: Long = 0

  var audioManager: AudioManager? = null
  private var maxVolumeProgress: Int = 0
  private var currentVolumeProgress: Int = 0
  private var isBindService = false




  override fun onCreate(savedInstanceState: Bundle?) {

    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(FlutterEngine(applicationContext))

    seekBarProgressHandler = Handler()
    initUpVolumeControl()


    MethodChannel(flutterView, CHANNEL).setMethodCallHandler { methodCall, result ->
      when (methodCall.method) {
        "startPlayer" -> {
          //click on play from flutter
          if (audioPath == methodCall.argument<String>("url")) {
            currentAudioPlay()
          } else {
            audioPath = methodCall.argument<String>("url")
            audioTitle = methodCall.argument<String>("title")
            audioDescription = methodCall.argument<String>("desc")

            if (playerService == null) {
              startPlayer(audioPath, audioTitle, audioDescription)
            } else {
              currentProgress=0
              isPlaying=false
              maxProgress=0

              playerService?.player?.stop(true)
              playerService?.audioTitle = audioTitle
              playerService?.audioDescription = audioDescription
              playerService?.audioPath = audioPath
              playerService?.setUpMediaPlayer()
            }
          }

        }
        "pausePlayer" -> {
          //click on pause from flutter
          currentAudioPause()
        }
        "setPlayingState" -> {
          //current state of player, from notification
          result.success(isPlaying)
        }
        "seekTo" -> {
          //when user change from seekbar
          currentProgress = methodCall.argument<Double>("milisecond")?.toLong()!!
          seekTo(currentProgress)
        }
        "setSeekBarProgress" -> {
          //every second
          result.success(currentProgress.toDouble())
        }
        "setSeekBarMaxProgress" -> {
          //max first time
          result.success(maxProgress.toDouble())
        }
        "setVolume" -> {
          currentVolumeProgress = methodCall.argument<Double>("volume")?.toInt()!!
          setVolume(currentVolumeProgress)
        }
        "getMaxVolume" -> {
          result.success(maxVolumeProgress.toDouble())
        }
        "getVolumeProgress" -> {
          result.success(currentVolumeProgress.toDouble())
        }
        "speedXPlayer" -> {
          changeAudioSpeed(methodCall.argument<String>("speedValue"))
        }
        "getBuffering" -> {
          result.success(isBuffering)
        }
      }
    }



  }


  fun setVolume(volume: Int) {
    audioManager?.setStreamVolume(AudioManager.STREAM_MUSIC, volume, 0)
  }

  private fun initUpVolumeControl() {
    try {
      audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
      maxVolumeProgress = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 0
      currentVolumeProgress = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0

      Log.d(TAG, "max==$maxVolumeProgress")
      Log.d(TAG, "current==$currentVolumeProgress")

    } catch (e: Exception) {
      e.printStackTrace()
    }
  }

  fun bindService() {
    val intent = Intent(this, PlayerService::class.java)
    intent.putExtra("audioPath", audioPath)
    intent.putExtra("audioTitle", audioTitle)
    intent.putExtra("audioDescription", audioDescription)
    bindService(intent, serviceConnection, BIND_AUTO_CREATE)
    isBindService = true

  }

  fun startPlayer(audioPath: String?, audioTitle: String?, audioDescription: String?) {
    this.audioPath = audioPath
    this.audioTitle = audioTitle
    this.audioDescription = audioDescription

    bindService()
  }

  val playserSeekRunnable = Runnable {

    currentProgress = playerService?.player?.currentPosition!!

    startSeekRunnable()
  }

  fun startSeekRunnable() {
    seekBarProgressHandler?.postDelayed(playserSeekRunnable, 1000)
  }

  fun stopSeekRunnable() {
    seekBarProgressHandler?.removeCallbacks(playserSeekRunnable)
    seekBarProgressHandler?.removeCallbacksAndMessages(null)
  }

  val serviceConnection = object : ServiceConnection {
    override fun onServiceDisconnected(name: ComponentName?) {

    }

    override fun onServiceConnected(name: ComponentName?, service: IBinder?) {

      val myBinder = service as PlayerService.MyBinder

      playerService = myBinder.service
      playerService?.playerEvent = playserEvent
      playerService?.setUpMediaPlayer()

      currentAudioPlay()
    }
  }

  var playserEvent = object : Player.EventListener {
    override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters?) {
      Log.d(TAG, "onPlaybackParametersChanged")
    }

    override fun onSeekProcessed() {
      Log.d(TAG, "onSeekProcessed")
    }

    override fun onTracksChanged(trackGroups: TrackGroupArray?, trackSelections: TrackSelectionArray?) {
      Log.d(TAG, "onTracksChanged")
    }

    override fun onPlayerError(error: ExoPlaybackException?) {
      Log.d(TAG, "onPlayerError")
    }

    override fun onLoadingChanged(isLoading: Boolean) {
      Log.d(TAG, "onLoadingChanged")
      isBuffering = isLoading

    }

    override fun onPositionDiscontinuity(reason: Int) {
      Log.d(TAG, "onPositionDiscontinuity")
    }

    override fun onRepeatModeChanged(repeatMode: Int) {
      Log.d(TAG, "onRepeatModeChanged")
    }

    override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
      Log.d(TAG, "onShuffleModeEnabledChanged")
    }

    override fun onTimelineChanged(timeline: Timeline?, manifest: Any?, reason: Int) {
      Log.d(TAG, "onTimelineChanged")
    }

    override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
      Log.d(TAG, "onPlayerStateChanged")
      when (playbackState) {
        PlaybackState.STATE_PLAYING -> {

          Log.d(TAG, "STATE_PLAYING")

          isPlaying = playWhenReady

          if (isPlaying) {

            if (maxProgress <= 0) {
              getDuration()
            }

            startSeekRunnable()

          } else {

            stopSeekRunnable()
          }
        }
        PlaybackState.STATE_STOPPED -> {
          Log.d(TAG, "STATE_STOPPED")
        }
        PlaybackState.STATE_FAST_FORWARDING -> {
          Log.d(TAG, "STATE_FAST_FORWARDING")

          stopSeekRunnable()
          currentAudioPause()
          playerService?.player?.seekTo(0)
          currentProgress = 0
        }
        PlaybackState.STATE_BUFFERING -> {
          Log.d(TAG, "STATE_BUFFERING")
        }
        PlaybackState.STATE_PAUSED -> {
          Log.d(TAG, "STATE_PAUSED")
        }
        PlaybackState.STATE_ERROR -> {
          Log.d(TAG, "STATE_ERROR")
        }
        PlaybackState.STATE_NONE -> {
          Log.d(TAG, "STATE_NONE")
        }
      }
    }
  }


  override fun onDestroy() {
    super.onDestroy()
    if (isBindService) {
      unbindService(serviceConnection)
    }
  }


  fun currentAudioPlay() {
    playerService?.player?.playWhenReady = true
  }

  fun currentAudioPause() {
    playerService?.player?.playWhenReady = false
  }

  fun changeAudioSpeed(speed: String?) {
    if (speed != null) {
      when (speed) {
        "0.5x" -> playerService?.player?.setPlaybackParameters(PlaybackParameters(0.5f, 1.0f))
        "0.75x" -> playerService?.player?.setPlaybackParameters(PlaybackParameters(0.75f, 1.0f))
        "1x" -> playerService?.player?.setPlaybackParameters(PlaybackParameters(1.0f, 1.0f))
        "1.25x" -> playerService?.player?.setPlaybackParameters(PlaybackParameters(1.25f, 1.0f))
        "1.5x" -> playerService?.player?.setPlaybackParameters(PlaybackParameters(1.5f, 1.0f))
        "2x" -> playerService?.player?.playbackParameters = PlaybackParameters(2f, 1.0f)
      }
    }
  }

  fun getDuration() {
    maxProgress = playerService?.player?.duration!!
  }

  fun seekTo(miliseconds: Long) {
    playerService?.player?.seekTo(miliseconds)
  }

  override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
    if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
      currentVolumeProgress = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
    } else if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
      currentVolumeProgress = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
    }
    return super.onKeyDown(keyCode, event)
  }
}
