# How to Add Network Diagnostics Button

This guide shows various ways to add the Network Diagnostics page to your app.

## Import Required

Add this import to your page:
```dart
import 'network_diagnostics_page.dart';
```

## Option 1: Floating Action Button (Quick Debug)

Add a FloatingActionButton to your Scaffold:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... your existing scaffold code ...
    
    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.blue,
      child: const Icon(Icons.network_check),
      tooltip: 'Network Diagnostics',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NetworkDiagnosticsPage(),
          ),
        );
      },
    ),
  );
}
```

## Option 2: As a Menu Card/List Item

```dart
Card(
  child: ListTile(
    leading: const Icon(Icons.network_check, color: Colors.blue),
    title: const Text('Network Diagnostics'),
    subtitle: const Text('Check backend connectivity'),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NetworkDiagnosticsPage(),
        ),
      );
    },
  ),
)
```

## Option 3: As a Settings Option

```dart
ListTile(
  leading: const Icon(Icons.settings_ethernet),
  title: const Text('Network Settings'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NetworkDiagnosticsPage(),
      ),
    );
  },
)
```

## Option 4: Debug Mode Only

Add to imports:
```dart
import 'package:flutter/foundation.dart';
```

Add to your UI:
```dart
if (kDebugMode)
  IconButton(
    icon: const Icon(Icons.bug_report),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NetworkDiagnosticsPage(),
        ),
      );
    },
  )
```

## Option 5: Show on Network Error

In your error handling:
```dart
void _handleNetworkError(String error) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Network Error'),
      content: Text(
        'Error: $error\n\nWould you like to check network diagnostics?'
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: const Text('Diagnostics'),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NetworkDiagnosticsPage(),
              ),
            );
          },
        ),
      ],
    ),
  );
}
```

## Recommendation

For production apps:
- Use **Option 3** (Settings Option) for regular users
- Use **Option 4** (Debug Mode Only) for development
- Use **Option 5** (On Error) for better UX when network issues occur

For testing:
- Use **Option 1** (FAB) for quick access during development
