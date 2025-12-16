/// Provides static format for text based item. 
class MiscFormatter {
    MiscFormatter._();
    /// Format Duration to a readable MM:SS string
    static String formatDuration(Duration duration) {
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        final minutes = twoDigits(duration.inMinutes.remainder(60));
        final seconds = twoDigits(duration.inSeconds.remainder(60));
        return "$minutes:$seconds";
    }
}