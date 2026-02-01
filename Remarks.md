## Remarks
This section is preserve for certain remarks with regards to the code (and, some irritating found issues that I have yet to be able to resolve).
Note that these following situations do not break the application (no red error page), but is not intuitive to the user, or could cause some confusion. 

- Remark 1: 
    - If a file location is change during the usage of the app and user attempt to play that song - using the controls or the progress bar, then there will be a warning saying: file missing ... (in orange). - The invalid song will be removed from the UI, and the dock will be set to not playing anything. The user should either navigates to another page and the come back, or click on playing another song in the same page, or click the next/previous song button to set the new active list without the improper song.

- Remark 2 (Updated January 2025): Carrying of the Song is now application wide: 
    - That is, moving from and to any pages in the application will still display the songs (and can still controls those).
    - This current active list will determine which song can be played next, via loop, next, previous, random. 
    - This active list will only be update when the user click on a song that is NOT currently playing - to play that Song. Then the list which the song belongs to is considered as the new active list - playlist takes precedence over master list. 
    - Any add / delete / reorder will immediately takes effect, thus, the next song will automatically be corrected. 

- Remark 3: 
    - After many considerations, the build function will be move to be the immediate next thing after the initialization of the state. 
    - This change is to accomodate the following things:
        - User (reader of this code) should be able to tell, on a very high level, what this code is doing (and the visual of this code), with a brief glance over the first k lines of the code. 
        - Also, there is a very high chance that the user is inclined towards making UI changes, rather than logical changes (since you can see the effect immediately), then putting the build function on the top is more helpful.   

- Remark 4: Android specific.  
    - Permission problem is only tested on android.
    - If granted audio permission (WHICH IS THE ONLY THING THIS APP ASK), the file picker for folder will work. Also the auto scan from android_file_system.dart will work. 
    - If not granted, or permission is removed from the AndroidManifest.xml in android/app/src/main, then it will for sure fail.
    - Currently control with bluetooth shortcut does not work.  

- Remark 5:
    - This is my proud version, all about cutting down rebuild per frame. 
    - Using dev tool, the rebuild per frame of multiple widgest across all pages has been cut down by at least 4 times, and some pages reach 12 times (some even more, this is purely number in the worst case).
        - For example: SongScreenState: 11 - 13 rebuild per frame, multiple widgets (19 widgets in compact dock mode) INCLUDING the CustomListTile widget (this is insane) to 1 single rebuild for much less widget (4 widgets in total, if playing song in compact dock mode), with the rest not being rebuilt at all.
        - Another example: PlaylistDetailPageState, 10 to 14 rebuild for (19 widgets in compact dock mode) per frame (10 songs), INCLUDING the CustomListTile. This was cut down to 2 rebuild per frame (3 widgets, and 1 that only rebuild 1 per frame) in worst case.
    - One very important thing: 
        - The SongDetailPageState rebuild process is dependent on where do you come from. 
        - If the navigation flow is as follow: 
            - PlaylistDetailPageState => SongDetailPageState: 
        - Then rebuild number per frame will be 1 extra compared to the following: 
            1. PlaylistPageState => SongDetailPageState.
            2. SongScreenState => SongDetailPageState. 
        - This affects the Slider, Gesture Detector and the ValueListenableBuilder in the NowPlayingDisplay and the MusicPlayerDock.