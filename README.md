# project_xmedit
A desktop application built with Flutter for viewing, editing, and managing specific medical XML claim files, such as those for DHPO resubmissions.


## 🚀 Features

- **Load & Save XML:** Open local XML claim files and save them as a new file or overwrite the existing one.
- **Claim Data Editing:**
    - View and copy key details like Claim ID and Member ID.
    - Edit financial totals (Gross, Patient Share, Net) with live balance-checking.
    - Modify the resubmission type and comment.
- **Activity Management:**
    - View all activities grouped by type (CPT, Drug, etc.).
    - See descriptions for CPT codes from a local data source.
    - Mark individual activities as deleted/restored, which are then excluded/included from the final XML.
    - View special observations, such as "Presenting-Complaint".
- **Diagnosis Management:**
    - View all diagnosis codes with descriptions loaded from a local ICD-10 data source.
    - Set which diagnosis is the "Principal" code.
    - Add new diagnoses by searching via code or description in a popup dialog.
    - Delete and reset diagnoses back to their original state.
- **Customizable UI:**
    - Toggle between Light and Dark mode.
    - Change the application's theme color.
    - Show or hide the main data cards (Details, Activities, etc.) to customize the workspace.
- **Desktop Focused:** Built for Windows with a custom title bar and window controls.

## 🛠️ Tech Stack

- **Framework:** Flutter 3.x
- **Language:** Dart
- **State Management:** Provider
- **Key Packages:**
    - `xml`: For parsing and building XML documents.
    - `file_picker`: For opening and saving files.
    - `window_manager`: For custom desktop window management.
    - `provider`: For state management.
    - `shared_preferences`: For persisting user settings.
    - `uuid`: For generating unique IDs.

## ⚙️ Setup and Installation

1.  **Clone the repository:**
    ```sh
    git clone [https://github.com/RaidenExn/project_xmedit.git](https://github.com/RaidenExn/project_xmedit.git)
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd project_xmedit
    ```
3.  **Get dependencies:**
    ```sh
    flutter pub get
    ```
4.  **Run the application:**
    ```sh
    flutter run -d windows
    ```

## 📂 File Structure

The core application logic is located in the `lib` directory, organized as follows:

- `main.dart`: The entry point of the application, handles window and provider setup.
- `home_page.dart`: Defines the main UI scaffold, including the app bar and settings drawer.
- `notifiers.dart`: Contains all the state management logic using `ChangeNotifier`.
- `xml_handler.dart`: Handles all data parsing from and serialization to XML.
- `cards/`: A directory containing the individual UI widgets for each data card (Activities, Diagnosis, etc.).
- `widgets/`: A directory for common, reusable UI components used throughout the app.
- `assets/`: Contains the JSON files for CPT and ICD-10 code descriptions.

---