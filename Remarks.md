## Remarks
This section is preserve for certain remarks with regards to the code (and, some irritating found issues that I have yet to be able to resolve).
Note that these following situations do not break the application (no red error page), but is not intuitive to the user, or could cause some confusion. 

- Remark 1: 
    - If a file location is change during the usage of the app and user attempt to play that song - using the controls or the progress bar, then there will be a warning saying: file missing ... (in red).
    - In order for the UI to updated properly, the user should navigates to another page that DOES NOT contain the song list which the error is in. Then when the user come back, this missing file will be cleared from the UI. 

- Remark 2 (Updated December 20 - 25th 2025): Carrying of the Song is now application wide: 
    - That is, moving from and to any pages in the application will still display the songs (and can still controls those).
    - This current active list will determine which song can be played next, via loop, next, previous, random. 
    - This active list will only be update when the user click on a song that is NOT currently playing - to play that Song. Then the list which the song belongs to is considered as the new active list - playlist takes precedence over master list. 
    - HOWEVER 2: REMOVING a Song from any list would not immediately updated the list that is being played. 
        - This update is written to file, BUT, in order to exclude the song in the current playing list, the user must tap to play another song in the list (to set the NEW active list). 

- Remark 3: 
    - After many considerations, the build function will be move to be the immediate next thing after the initialization of the state. 
    - This change is to accomodate the following things:
        - User (reader of this code) should be able to tell, on a very high level, what this code is doing (and the visual of this code), with a brief glance over the first k lines of the code. 
        - Also, there is a very high chance that the user is inclined towards making UI changes, rather than logical changes (since you can see the effect immediately), then putting the build function on the top is more helpful.   

