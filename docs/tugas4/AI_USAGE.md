# Catatan Penggunaan AI — Tugas 4

## 1. Asisten dan Ruang Lingkup Bantuan

Asisten yang digunakan pada sesi ini: **OpenCode, model GPT-6.1**.
Bantuan meliputi scaffold Flutter, model/repository, Riverpod notifier, widget/form,
widget test, pemeriksaan lokal, screenshot, dan draft dokumentasi.

Dokumen ini mencatat pekerjaan asisten. Pemeriksaan mandiri mahasiswa belum dapat dinyatakan selesai oleh AI.

## 2. Prompt Pengguna yang Digunakan

Berikut instruksi asli pada sesi implementasi:

> Dan ini adalah tugas ke - 4 saya. Sesuaikan dengan project yang sedang kita buat sekarang dengan instruksi dari dosen saya sebagai berikut. Tugas Anda adalah membuat satu feature Flutter yang menerapkan state management, form, dan validasi secara nyata. Feature wajib memiliki minimal enam kondisi UI: initial loading, data berhasil dimuat, empty state, error state dengan tombol retry, validasi input pada form, serta loading saat proses submit agar pengguna tidak dapat melakukan double tap. Gunakan state management yang konsisten, misalnya Riverpod, dan pisahkan tanggung jawab antara widget, notifier/use case, serta repository. Sertakan widget test untuk setiap state utama dan dokumentasikan hasilnya dengan screenshot atau video singkat. Anda boleh menggunakan Codex atau Gemini untuk membantu membuat boilerplate, test, atau melakukan review kode, tetapi Anda tetap wajib memahami, menjelaskan, dan bertanggung jawab atas kode yang dikumpulkan; cantumkan prompt AI yang digunakan serta bagian kode yang Anda periksa atau perbaiki sendiri.

Konteks sebelumnya adalah README dan Architecture.md DonburiX,
dengan Dynamic Bowl Builder serta rencana integrasi ricebowltracker.
Feature dipilih sebagai **Racik Bowl → Tambahkan ke Keranjang**, memakai repository lokal sampai backend tersedia.
Tidak ada prompt tambahan ke subagent; implementasi dan verifikasi dilakukan dalam sesi asisten ini.

## 3. Bagian yang Dibantu AI

| Bagian | File/lokasi | Bantuan |
| --- | --- | --- |
| Scaffold | `apps/mobile` | Menjalankan `flutter create` untuk Android dan web |
| Model dan validasi | `domain/` | Data immutable, batas jumlah/catatan, validasi kategori dan stok |
| Repository | `data/demo_bowl_repository.dart` | Data demo dan operasi asynchronous yang dapat direproduksi |
| State management | `state/bowl_providers.dart` | Catalog AsyncNotifier, builder Notifier, guard submit, derived total |
| UI | `presentation/` dan `app.dart` | Form, state screens, feedback, dan keranjang |
| Test | `test/` | 12 widget test dan 2 domain/repository test |
| Bukti visual | `docs/tugas4/screenshots/` | Screenshot aplikasi yang berjalan melalui browser |
| Dokumentasi/CI | `docs/tugas4/`, README, workflow | Draft laporan, instruksi menjalankan, dan pemeriksaan otomatis |

Path feature pada tabel relatif terhadap `apps/mobile/lib/features/bowl_builder`.

## 4. Pemeriksaan dan Perbaikan oleh Asisten

* Memperbaiki empat temuan lint tentang blok `if` sebelum analyze ulang berhasil.
* Memeriksa guard notifier yang langsung aktif sebelum `await`, sehingga reentrant submit ditolak.
* Memeriksa bahwa input dipertahankan saat gagal dan keranjang tidak bertambah pada kegagalan.
* Memvalidasi ulang draft dan harga katalog pada repository lokal.
* Menjalankan analyze, 14 test, dan build web.
* Memeriksa screenshot loading submit, sukses, validasi, serta error submit.
* Menguji retry melalui browser dan mengambil screenshot pada viewport mobile.

Temuan review lokal: tidak ditemukan blocker untuk scope prototype tugas ini.
Pemisahan repository mempermudah test dan penggantian data source; guard widget/notifier mencegah submit ulang dalam satu sesi.
Batas integrasi: keranjang masih in-memory; belum ada API, persistensi Firebase, atau checkout backend.
Ini bukan laporan audit produksi atau review independen oleh mahasiswa.

## 5. Pemeriksaan Mandiri Mahasiswa — Wajib Diisi

Isi bagian ini setelah menjalankan dan memeriksa kode sendiri.
Jangan menyatakan bahwa AI telah melakukan pemeriksaan pribadi atas nama mahasiswa.

**Nama/NIM:** [isi sendiri]

**Tanggal pemeriksaan:** [isi sendiri]

| Bagian kode | Hal yang saya periksa | Hasil/perbaikan yang saya lakukan |
| --- | --- | --- |
| `BowlValidation.quantity` dan `validateDraft` | Mengapa 0, 11, desimal, dan stok kurang ditolak | [isi hasil pemeriksaan] |
| `BowlBuilderNotifier.submit` | Posisi guard, `await`, penanganan error, dan mounted | [isi hasil pemeriksaan] |
| `IngredientField` dan `Form` | Hubungan pilihan bahan dengan validator | [isi hasil pemeriksaan] |
| `DemoBowlRepository.addToCart` | Harga berasal dari katalog dan belum ada reservasi stok | [isi hasil pemeriksaan] |
| `bowl_builder_widget_test.dart` | Cara test menahan future dan membuktikan tidak ada submit ganda | [isi hasil pemeriksaan] |

Jika tidak mengubah kode, tulis hasil pemeriksaan yang nyata serta alasannya; jangan mengarang perbaikan.

### Checklist sebelum pengumpulan

- [ ] Saya menjalankan aplikasi dan mencoba enam kondisi UI wajib.
- [ ] Saya menjalankan analyze dan test sendiri.
- [ ] Saya memahami perbedaan state katalog dan state submit.
- [ ] Saya dapat menjelaskan peran widget, notifier, dan repository tanpa membaca jawaban AI.
- [ ] Saya mencatat bagian kode yang diperiksa/perbaiki sendiri pada tabel di atas.
- [ ] Saya memahami bahwa integrasi Firebase/ricebowltracker belum diterapkan pada feature ini.

### Refleksi singkat

**Keputusan yang saya pahami:** [jelaskan dengan kata-kata sendiri]

**Bagian yang saya ubah atau saya verifikasi:** [isi sesuai tindakan nyata]

**Keterbatasan feature dan langkah berikutnya:** [isi sendiri]
