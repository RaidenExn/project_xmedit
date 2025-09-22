export 'platform_helper_desktop.dart' // Default export for non-web platforms
    if (dart.library.html) 'platform_helper_web.dart'; // Conditional export for web