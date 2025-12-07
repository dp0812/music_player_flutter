import 'package:logger/logger.dart';
/// This class is solely responsible for handling console debug print - thanks to logger. 
/// 
/// The fact that there is a deprecated function called "wtf", which is replaced by "f", is enough for me to use this. 
class IO {
    static Logger? _logger;
    IO._(); // STATIC. DO NOT USE INSTANCE OF THIS CLASS.

    // Static logging methods
    
    static void t(dynamic message, {dynamic error, StackTrace? stackTrace}) {
        _instance.t(message, error: error,stackTrace: stackTrace);
    }

    static void d(dynamic message, {dynamic error, StackTrace? stackTrace}) {
        _instance.d(message, error: error,stackTrace: stackTrace);
    }
    
    static void i(dynamic message, {dynamic error, StackTrace? stackTrace}) {
        _instance.i(message, error: error,stackTrace: stackTrace);
    }
    
    static void w(dynamic message, {dynamic error, StackTrace? stackTrace}) {
        _instance.w(message, error: error,stackTrace: stackTrace);
    }
    
    static void e(dynamic message, {dynamic error, StackTrace? stackTrace}) {
        _instance.e(message, error: error,stackTrace: stackTrace);
    }
    
    /// Log with tag/context (custom)
    static void tagged(String tag, dynamic message, {Level level = Level.debug}) {
        _instance.log(level, '[$tag] $message');
    }
    
    /// Conditional logging (only in debug mode)
    static void debugOnly(dynamic message, {dynamic error, StackTrace? stackTrace}) {
        assert(() {
            _instance.d(message, error: error,stackTrace: stackTrace);
            return true;
        }());
    }

    /// Get the default Logger (Pretty Printer)
    static Logger get _instance {
        if (_logger == null) {
            _init();
        }
        return _logger!;
    }

    /// Set up our PrettyPrinter. 
    static void _init() {
        _logger = Logger(
            printer: PrettyPrinter(
                methodCount: 0,          
                errorMethodCount: 8,     
                lineLength: 120,         
                colors: true,            
                printEmojis: true,       
            ),
            output: null, 
        );
    }

    /// Use this to change if you dislike the default config. 
    static void configure({LogPrinter? printer, LogOutput? output, Level? level}) {
        _logger = Logger(
            printer: printer ?? PrettyPrinter(),
            output: output,
            level: level,
        );
    }
}