# Flutter_Audio_Player

Flutter Audio Player with all the fuctionality to build your own custom music player!!

This repository involevs following functionality :-
- Using Native Controlllers, you can play audio in the background mode,
- You can fast forward or descrease the speed of the audio.
- Use of native bridge allowes you to customise player on the go!


Flutter Audio player with native controller to manage audio in background. For android, implemented foreground service. This repository also demonstrate the native code bridge to flutter.


Android Pre Requirements :- 

1. Add Exoplayer dependencies in your app level build.gradle file

implementation 'com.google.android.exoplayer:exoplayer:2.9.6'
implementation 'com.google.android.exoplayer:exoplayer-ui:2.9.6'


2. Add following permissions in the AndroidMenifest.xml file :-

<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>

3.Register Service(PlayerService) in application tag of your AndroidMenifest.xml file :-

<service android:name=".player.PlayerService" android:enabled="true">
<intent-filter>
<action android:name="com.auditorium.player.PlayerService" />
</intent-filter>
</service>


Ios Pre Requirements :-

1.Enable Background service in your project by turning on the "Background Modes" -> Audio, AirPlay, and Picture in Picture

Minimum iOS OS version require: 10.0
