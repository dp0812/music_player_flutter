## Remarks
This section is preserve for certain remarks with regards to the code (and, some irritating found issues that I have yet to be able to resolve).
- Remark 1: The following situation does not break the application, but is not intuitive to the user:
    - If a file location is change, and loop mode is off, and the user is in SongDetailPageState, 
    - Seeking will NOT do anything visually (expected).
    - HOWEVER 1: The page is not remove, and the user needs to go back to the PlaylistDetailPage (or the SongScreenState) for it to delete the song. 
    - Clicking on go to next song (or go to previous song) will go to next/previous song (expected).
    - HOWEVER 2: Had the user change anything with the seek (suppose, they seek to 2:40s), the immediate next/previous song will start playing at the time. 
    This however, if the current length is more than the total length of the immediate next/previous song, the app will default to the first song (due to, this is not posisble to play).

- Remark 2: The carrying of the song playing is only applicable in the case you can see the song (name). 
    - That is, moving from and to the SongDetailPage.  
    - Thus, moving between playlist and between navigation page (using the bar on the left) will stop any song currently playing. 

