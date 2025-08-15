# Dokumentasi Penggunaan "flutter_bluetooth_serial" pada Flutter

Dokumen ini menjelaskan alur kerja dan implementasi kode untuk menghubungkan aplikasi Flutter dengan perangkat Bluetooth Classic (seperti HC-05/HC-06) menggunakan library flutter_bluetooth_serial.

## Pra-syarat Penting

Sebelum aplikasi dapat berfungsi dengan baik, ada dua hal krusial yang harus dipastikan:

1.Izin (Permissions) di AndroidManifest.xml: Pastikan file android/app/src/main/AndroidManifest.xml memiliki izin yang diperlukan untuk mengakses Bluetooth.

copy paste code ini diluar tag <application></application>

```.xml
<!-- Izin untuk Bluetooth klasik -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />

<!-- Diperlukan untuk scan di beberapa versi Android -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Izin baru untuk Android 12 (API 31) ke atas -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

2. Pairing Perangkat Manual: Aplikasi ini tidak melakukan scan perangkat baru. Ia hanya menampilkan daftar perangkat yang sudah pernah di-pairing (dipasangkan) dengan HP Anda. Oleh karena itu, Anda harus melakukan pairing manual terlebih dahulu.

Pengaturan HP -> Bluetooth -> Pindai -> Pilih Perangkat Bluetooth Serial

## Penjelasan Kode

Berikut adalah penjelasan fungsi-fungsi dan variabel utama yang digunakan untuk mengelola koneksi Bluetooth.

### A. Variabel State Utama

Variabel-variabel ini digunakan untuk menyimpan status aplikasi dan mengontrol tampilan UI.

```Dart
// Instance utama dari library
FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;

// Menyimpan daftar perangkat yang sudah di-pairing
List<BluetoothDevice> devices = [];

// Flag untuk menandai proses koneksi sedang berlangsung
bool isConnecting = false;

// Teks untuk ditampilkan ke pengguna mengenai status koneksi
String status = "Not connected";

// Objek koneksi yang aktif, null jika tidak ada koneksi
BluetoothConnection? connection;

// Menyimpan informasi perangkat yang sedang terhubung
BluetoothDevice? connectedDevice;
```

### B. Fungsi Utama

1. initState()
   Fungsi ini dipanggil pertama kali saat halaman dibuat. Ini adalah titik awal untuk memulai logika Bluetooth.

-   Kapan dipakai?: Saat ConnectBluetoothPage pertama kali dibuka.
-   Apa yang dilakukan?: Memanggil dua fungsi penting: \_checkBluetooth() untuk memastikan Bluetooth aktif, dan \_getBondedDevices() untuk mengambil daftar perangkat.

```dart
@override
void initState() {
super.initState();
\_checkBluetooth();
\_getBondedDevices();
}
```

2. \_checkBluetooth()
   Fungsi ini memastikan layanan Bluetooth di HP pengguna sudah menyala.

-   Kapan dipakai?: Dipanggil dari initState().
-   Apa yang dilakukan?: Menggunakan bluetooth.isEnabled untuk mengecek status. Jika mati, bluetooth.requestEnable() akan menampilkan dialog sistem untuk meminta pengguna mengaktifkan Bluetooth.

3.  \_getBondedDevices()
    Fungsi ini adalah kunci untuk mendapatkan daftar perangkat yang bisa dihubungkan.

    -   Kapan dipakai?: Dipanggil dari initState() setelah memastikan Bluetooth aktif.
    -   Apa yang dilakukan?: Memanggil await bluetooth.getBondedDevices(). Fungsi ini mengembalikan List<BluetoothDevice> yang berisi semua perangkat yang sudah di-pairing dengan HP. Hasilnya disimpan di variabel devices dan UI diperbarui melalui setState.

4.  \_connectToDevice(BluetoothDevice device)
    Ini adalah fungsi inti untuk memulai koneksi ke perangkat yang dipilih.

    -   Kapan dipakai?: Saat pengguna menekan ingin melakukan connect.

    code utama untuk connect :
    connection = await BluetoothConnection.toAddress(device.address);

    contohnya dalam satu fungsi :
    ```dart
    Future<void> \_connectToDevice(BluetoothDevice device) async {
    // Langkah 1: Mengatur UI untuk menampilkan status "Connecting..."
    setState(() {
    isConnecting = true;
    status = "Connecting to ${device.name ?? device.address}...";
    });

        try {
        // ===================================================================
        // INI ADALAH LOGIKA UTAMA UNTUK MENGHUBUNGKAN PERANGKAT
        // ===================================================================
        connection = await BluetoothConnection.toAddress(device.address);
        // ===================================================================

            // Langkah 2: Jika koneksi berhasil, perbarui UI ke status "Connected"
            setState(() {
            connectedDevice = device;
            status = "Connected to ${device.name ?? device.address}";
            isConnecting = false;
            });

            // Langkah 3: Siapkan listener untuk mendeteksi jika koneksi terputus
            connection!.input?.listen((_) {
            // bisa dipakai untuk handle data masuk
            }).onDone(() {
            setState(() {
                status = "Disconnected";
                connectedDevice = null;
                connection = null;
            });
            });

        } catch (\_) {
        // Langkah 4: Jika koneksi gagal, perbarui UI untuk menampilkan error
            setState(() {
            status = "Gagal connect ke Bluetooth";
            isConnecting = false;
            });
        }
    }
    ```
5.  \_disconnect()
    Fungsi ini digunakan untuk memutuskan koneksi yang sedang aktif.
    