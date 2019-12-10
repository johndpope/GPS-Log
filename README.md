# GPS Log

GPS track generator. Generates GPS tracks defined by periodic sampling of the location of the device.

GPS Log was written by Stuart Rankin.

## Version

Versioning for GPS Log is maintained in the `Versioning.swift` file and is automatically updated with each build as a pre-build script step. The updating includes build IDs, build numbers, times and dates, but version numbers must currently be updated by hand. The current build string below is also maintained by the same mechanism.

The versioning program does not currently update the GPS Log project file's version or build numbers.

Most recent build: **Version 1.0 Alpha, Build 106, Build date: 10 December 2019, 16:23**

## Design

GPS log works by getting a continuous stream of coordinates from the device's GPS unit. The user determines how often to use a sample, so if the user indicates once a minute, at least one minute will have to pass before a location is accumulated. Locations passed to the program outside of the sample time-frame will be dropped.

When collecting data points, each data point is saved as soon as it becomes available (bearing in mind that only certain locations are used depending on the sampling frequency). If the user is requesting addresses, the data point in the data base will be updated asynchronously.

The user can press the mark button to save a location at any time.

All data is saved into a device-local Sqlite 3 database.

## Sessions and Data Points

A session is defined as the data saved from when the user pressed the play (or go) button to when the user presses the stop button. Each session is defined by the set of data points accumulated as well as the starting and ending times, and an optional name. (If no name is specified, the starting time is used.)

Each data point in a session consists of a set of location data from the OS as well as some metadata. Data points are stored in the session class.

## Database

There are two major tables in the database. One for sessions, and one for entries. All data points are stored in the **Entries** table and have the session ID back to the session. Session data is stored in the **Sessions** table.

Each session has a unique ID. This ID is the way GPS Log differentiates between various sessions. The session name is for the user's convenience only.

Each entry has a unique ID to help with map operations.

### Sessions Table

The **Sessions** table has the following columns:

| Column   | Type  | Comment  |
|:----------|:----------|:----------|
| **Key**    | `Integer	`  | Not directly used    |
| **ID**    | `Text`    | ID of the session (UUID in string format)    |
| **StartTime** | `Text`| Start time for the session (in string format) |
| **EndTime** | `Text` | End time for the session (in string format) |
| **Name** | `Text`| Optional name for the session |


### Entries Table

| Column  | Type  | Comment  |
|:----------|:----------|:----------|
| **Key**    | `Integer`    | Not directly used   |
| **Session**    | `Text`    | Session ID (UUID in string format)   |
| **Latitude**   | `Text`    | Latitude value (in string format) |
| **Longitude**  | `Text`    | Longitude value (in string format) |
| **Altitude**   | `Text`    | Altitude value (in string format) |
| **HorizontalAccuracy**| `Text` | Horizontal accuracy value (in string format) |
| **VerticalAccuracy**| `Text` | Vertical accuracy value (in string format) |
| **TimeStam**p| `Text` | Time stamp of the location sample (in string format) |
| **Speed** | `Text` | Speed at the sample time (in string format) |
| **Course** | `Text` | Heading at the sample time (in string format) |
| **Address** | `Text`| Reverse geocoded address (if available) |
| **Marked** | `Text`| Location was marked by user (boolean in string format) |
| **EntryID**| `Text`| Unique ID for the entry (UUID in string format) |
| **InstanceCount**| `Integer` | Number of times this location was recorded in a row |
| **Heading** | `Real` | If data represents a heading change, the new heading value |
| **IsHeadingChanged** | `Integer` | If this value is 0, the data is for a location - if non-zero the data is for a heading change |
| **HeadingTimeStamp** | 'Text' | Time stamp for the heading change |

### Database Access

Sessions can be exported as XML fragments. The entire database can be accessed via Apple's **Files** program and shared/moved from there using mechanisms provided.

## Time-Lag/Asynchronous Processing

There is a time-lag from when the device requests its location to when it actually is received. Therefore, asynchronous processing shows up in the user interface as slow updates. Care has been taken to minimize the perception of lagging performance. 

When map tiles are slow to download, a busy indicator is shown in the bottom toolbar. The busy indicator also shows map download failures.

This lag is especially true when reverse geolocating addresses.  A special mechanism was put into place to allow for asynchronous updating of the accumulating table for late arrival of addresses.

### Apple Limitation

Apple enforces a limitation with respect to how often addresses may be decoded. When Apple's servers are very busy, no more than one address per minute will be decoded per client. The limit is dynamic so when the load is low, it is possible to decode multiple addresses over the span of a minute.

Due to this limitation, addresses are not always available for saved data points.

## Mapping

There are two mapping modes planned for GPS Log.

### 3D Mapping

This mode will be implemented in SceneKit and displayed as a 3D view. It is intended to be more stylistic than accurate.

### OS Mapping

This mode will use the built-in OS mapping SDK and plot each data point as a type of point-of-view indicating where each data point was taken.

## Tested

GPS Log was tested on the following hardware:
- iPhone 6S+, iOS 13.2
- iPad Mini 4, iOS 13.3

## Copyright

GPS Log is copyright © 2019 by Stuart Rankin
