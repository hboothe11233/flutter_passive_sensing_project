# flutter_passive_sensing_project

- - **Modular Architecture:**
- The code is organized into separate modules for models, controllers, and views for improved maintainability and testability.

- **Models (models.dart):**
    - **ScanResultModel:**
        - Represents a single BLE scan result.
        - Contains fields for device ID, device name, and RSSI.
        - Provides JSON serialization (`toJson`) and deserialization (`fromJson`).
        - Includes a factory constructor `fromScanResult()` that creates an instance from a `ScanResult` (using data from Flutter Blue Plus).
    - **ScanBatch:**
        - Groups multiple `ScanResultModel` objects along with a timestamp.
        - Used to maintain a batch of scan results for each scan cycle.
        - Supports JSON conversion to enable persistence.

- **Background Scanning (controllers/background_scan_controller.dart & background_service.dart):**
    - **BackgroundScanController:**
        - Encapsulates logic to perform a background BLE scan for 5 seconds.
        - Listens for scan results, converts them into `ScanResultModel` objects, and packages them in a `ScanBatch`.
        - Persists the scan batch to SharedPreferences under a designated key.
    - **Callback Dispatcher (in background_service.dart):**
        - Annotated with `@pragma('vm:entry-point')` to ensure entry point availability.
        - Invokes the background scan controller when the Workmanager task (named `scanTask`) is triggered.
        - Designed to run periodically (configured via Workmanager).

- **Foreground Scanning & Controller (controllers/home_controller.dart):**
    - **HomeController:**
        - Extends `ChangeNotifier` and manages foreground scanning, persistent storage of scan data, and state for UI filtering.
        - Loads stored scan batches from SharedPreferences on initialization.
        - Checks and requests necessary permissions (Bluetooth and location) for both iOS and Android.
        - Periodically performs foreground scans (every 10 seconds), converts results to `ScanResultModel` objects, and appends a new `ScanBatch` to an in‑memory list.
        - Persists updated scan batches using SharedPreferences.
        - Provides methods to clear all scan results from both memory and persistent storage.
        - Manages search UI state (text controller, focus node, search query, and visibility) for filtering the displayed data.

- **User Interface (views/home_view.dart):**
    - **HomeView Widget:**
        - Uses the Provider package to consume the `HomeController` state.
        - Displays the list of detected BLE devices from the most recent foreground scan.
        - Provides a toggleable, rounded search field:
            - When activated via a Floating Action Button (FAB), it scrolls to the top and opens the keyboard.
            - Supports filtering the device list and the data displayed in the charts.
        - Visualizes historical scan data through two charts (using fl_chart):
            - A chart of the number of devices over time.
            - A chart of the average RSSI (signal strength) over time.
        - Includes an AppBar with a "Clear All Results" button to clear stored scan data.

- **Application Entry Point (main.dart):**
    - Ensures the widget binding is initialized.
    - On Android, initializes background execution using the `flutter_background` package (which displays a foreground notification).
    - Initializes Workmanager with the defined background callback (from `background_service.dart`) and registers a periodic background task.
    - Uses a `ChangeNotifierProvider` to supply the `HomeController` to the widget tree.
    - Launches the app using `MyApp`, which defines the MaterialApp configuration and sets `HomeView` as its home screen.

- **Overall Functionality:**
    - The application continuously scans for nearby BLE devices, combining data from both foreground and background scans.
    - All scan batches (each containing a list of devices and their RSSI values) are persisted using SharedPreferences and merged on startup.
    - The UI provides real-time filtering and historical visualization through dynamic charts.
    - Background scanning is enabled via Workmanager and flutter_background, ensuring the app can capture scan data even when not in the foreground.
