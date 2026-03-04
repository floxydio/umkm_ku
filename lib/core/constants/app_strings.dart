class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'UMKM Ku';
  static const String appTagline = 'Kelola bisnis Anda dengan mudah';

  // General
  static const String simpan = 'Simpan';
  static const String batal = 'Batal';
  static const String hapus = 'Hapus';
  static const String edit = 'Edit';
  static const String tambah = 'Tambah';
  static const String cari = 'Cari';
  static const String filter = 'Filter';
  static const String lanjut = 'Lanjut';
  static const String kembali = 'Kembali';
  static const String tutup = 'Tutup';
  static const String ya = 'Ya';
  static const String tidak = 'Tidak';
  static const String konfirmasi = 'Konfirmasi';
  static const String berhasil = 'Berhasil';
  static const String gagal = 'Gagal';
  static const String memuat = 'Memuat...';
  static const String tidakAdaData = 'Tidak ada data';
  static const String refresh = 'Perbarui';

  // Auth
  static const String masuk = 'Masuk';
  static const String keluar = 'Keluar';
  static const String daftar = 'Daftar';
  static const String email = 'Email';
  static const String password = 'Kata Sandi';
  static const String konfirmasiPassword = 'Konfirmasi Kata Sandi';
  static const String lupaPassword = 'Lupa kata sandi?';
  static const String resetPassword = 'Reset Kata Sandi';
  static const String belumPunyaAkun = 'Belum punya akun?';
  static const String sudahPunyaAkun = 'Sudah punya akun?';
  static const String masukDenganGoogle = 'Masuk dengan Google';

  // Product
  static const String produk = 'Produk';
  static const String tambahProduk = 'Tambah Produk';
  static const String editProduk = 'Edit Produk';
  static const String hapusProduk = 'Hapus Produk';
  static const String namaProduk = 'Nama Produk';
  static const String hargaJual = 'Harga Jual';
  static const String hargaBeli = 'Harga Beli';
  static const String stok = 'Stok';
  static const String satuan = 'Satuan';
  static const String kategori = 'Kategori';
  static const String barcode = 'Barcode';
  static const String fotoProduk = 'Foto Produk';
  static const String batasMaxProduk =
      'Batas maksimal $maxFreeProducts produk untuk akun gratis';

  static const int maxFreeProducts = 30;

  // POS
  static const String kasir = 'Kasir';
  static const String transaksi = 'Transaksi';
  static const String tambahKeKeranjang = 'Tambah ke Keranjang';
  static const String keranjang = 'Keranjang';
  static const String totalBelanja = 'Total Belanja';
  static const String bayar = 'Bayar';
  static const String tunai = 'Tunai';
  static const String kembalian = 'Kembalian';
  static const String jumlahBayar = 'Jumlah Bayar';
  static const String selesaikanTransaksi = 'Selesaikan Transaksi';
  static const String transaksiBehasil = 'Transaksi Berhasil';
  static const String cetakStruk = 'Cetak Struk';
  static const String transaksiBaruLagi = 'Transaksi Baru';
  static const String keranjangKosong = 'Keranjang kosong';

  // Stock
  static const String stokBarang = 'Stok Barang';
  static const String tambahStok = 'Tambah Stok';
  static const String kurangiStok = 'Kurangi Stok';
  static const String riwayatStok = 'Riwayat Stok';
  static const String stokMenipis = 'Stok Menipis';
  static const String stokHabis = 'Stok Habis';
  static const String minimumStok = 'Minimum Stok';
  static const String jumlah = 'Jumlah';
  static const String keterangan = 'Keterangan';

  // Hutang (Debt/Credit)
  static const String hutang = 'Hutang';
  static const String piutang = 'Piutang';
  static const String hutangPiutang = 'Hutang & Piutang';
  static const String tambahHutang = 'Tambah Hutang';
  static const String bayarHutang = 'Bayar Hutang';
  static const String namaDebitur = 'Nama Debitur';
  static const String jumlahHutang = 'Jumlah Hutang';
  static const String tanggalJatuhTempo = 'Tanggal Jatuh Tempo';
  static const String statusLunas = 'Lunas';
  static const String statusBelumLunas = 'Belum Lunas';
  static const String totalHutang = 'Total Hutang';
  static const String riwayatPembayaran = 'Riwayat Pembayaran';

  // Report
  static const String laporan = 'Laporan';
  static const String laporanPenjualan = 'Laporan Penjualan';
  static const String laporanHarian = 'Laporan Harian';
  static const String laporanMingguan = 'Laporan Mingguan';
  static const String laporanBulanan = 'Laporan Bulanan';
  static const String pendapatan = 'Pendapatan';
  static const String pengeluaran = 'Pengeluaran';
  static const String keuntungan = 'Keuntungan';
  static const String totalPenjualan = 'Total Penjualan';
  static const String produkTerlaris = 'Produk Terlaris';
  static const String periodeWaktu = 'Periode Waktu';
  static const String batasRiwayatGratis =
      'Riwayat terbatas 30 hari untuk akun gratis. Upgrade untuk akses penuh.';

  // Settings
  static const String pengaturan = 'Pengaturan';
  static const String tema = 'Tema';
  static const String temaTerang = 'Terang';
  static const String temaGelap = 'Gelap';
  static const String temaSistem = 'Ikuti Sistem';
  static const String bahasa = 'Bahasa';
  static const String notifikasi = 'Notifikasi';
  static const String sinkronisasi = 'Sinkronisasi Data';
  static const String sedangSinkronisasi = 'Sedang menyinkronkan data...';
  static const String sinkronisasiBerhasil = 'Data berhasil disinkronkan';
  static const String tentangAplikasi = 'Tentang Aplikasi';
  static const String versiAplikasi = 'Versi Aplikasi';
  static const String kebijakanPrivasi = 'Kebijakan Privasi';
  static const String syaratKetentuan = 'Syarat & Ketentuan';
  static const String upgrade = 'Upgrade ke Premium';

  // Error messages (user-friendly Indonesian)
  static const String errorTidakAdaInternet =
      'Tidak ada koneksi internet. Periksa jaringan Anda.';
  static const String errorServerTidakTersedia =
      'Server sedang tidak tersedia. Coba beberapa saat lagi.';
  static const String errorSessionBerakhir =
      'Sesi Anda telah berakhir. Silakan masuk kembali.';
  static const String errorEmailTidakValid =
      'Format email tidak valid.';
  static const String errorPasswordTerlaluPendek =
      'Kata sandi minimal 6 karakter.';
  static const String errorPasswordTidakCocok =
      'Konfirmasi kata sandi tidak cocok.';
  static const String errorEmailSudahTerdaftar =
      'Email sudah terdaftar. Gunakan email lain atau masuk.';
  static const String errorEmailTidakTerdaftar =
      'Email tidak terdaftar. Periksa kembali atau daftar akun baru.';
  static const String errorPasswordSalah =
      'Kata sandi salah. Coba lagi.';
  static const String errorDataTidakDitemukan =
      'Data tidak ditemukan.';
  static const String errorGagalMenyimpan =
      'Gagal menyimpan data. Coba lagi.';
  static const String errorGagalMemuat =
      'Gagal memuat data. Tarik ke bawah untuk memperbarui.';
  static const String errorGagalMenghapus =
      'Gagal menghapus data. Coba lagi.';
  static const String errorStokTidakCukup =
      'Stok tidak mencukupi.';
  static const String errorBatasProdukTercapai =
      'Batas maksimal $maxFreeProducts produk telah tercapai. Upgrade untuk menambah lebih banyak.';
  static const String errorBatasCustomerTercapai =
      'Batas maksimal 10 pelanggan telah tercapai. Upgrade untuk menambah lebih banyak.';
  static const String errorTidakDiketahui =
      'Terjadi kesalahan. Coba lagi atau hubungi dukungan.';
  static const String errorInputWajibDiisi =
      'Field ini wajib diisi.';
  static const String errorHargaHarusLebihDariNol =
      'Harga harus lebih dari 0.';
  static const String errorStokHarusBilanganBulat =
      'Stok harus berupa bilangan bulat.';
}
